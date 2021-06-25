dofile("veg_janitor/util.inc")
dofile("veg_janitor/calibration.inc")

Plant = {}
function Plant:new(index, plant_time, controller, config)
  if plant_time == nil or index == nil or controller == nil then
    error("Invalid or missing arguments for Plant:new")
  end
  local o = {}
  o.config = config
  o.index = index
  o.number_of_growth_stages = config.plants[config.seed_type][config.seed_name].stages
  o.stage = 1
  o.prev_stage = 0
  o.plant_time = plant_time
  o.seed_type = controller.seed_type
  o.current_stage_started_at = plant_time
  o.previous_stage_ended_at = plant_time
  o.current_stage_watered = false
  o.controller = controller
  o.measured_stage_times = {}
  o.inserted_first_stage_time = false
  o.harvested = false
  local p = newObject(self, o)
  p.next_stage_starts_at = plant_time + p:time_till_stage_advances(o.stage)
  return p
end

function Plant:fully_grown(stage)
  if stage == nil then
    stage = self.stage
  end
  return stage > self.number_of_growth_stages
end

function Plant:dead()
  return self.stage == 0
end

function Plant:status()
  local stage_times = {}
  for i = self.stage, 1, -1 do
    stage_times[i] = self:time_till_stage_advances(i)
  end
  return { stage = self.stage, next = stage_times[self.stage] - (self.next_stage_starts_at - lsGetTimer()),
           times = stage_times, next_in = self.next_stage_starts_at - lsGetTimer() }
end

function Plant:insert_stage_times_header()
  table.insert(self.measured_stage_times, calibration_log_header())
end

function Plant:update_stage_times()
  local now = lsGetTimer()
  local time_since_last_stage = 0
  local len = #self.measured_stage_times
  if len > 1 then
    time_since_last_stage = now - calibration_stage_time_row_to_table(self.measured_stage_times[len])["now"]
  end
  local row = create_calibration_stage_time_log_row(
    self.config,
    self.index,
    self.controller.plant_time,
    self.prev_stage,
    self.stage,
    now,
    now - self.controller.plant_time,
    time_since_last_stage
  )
  table.insert(self.measured_stage_times, row)
end

function Plant:tick()
  if self:dead() then
    return "dead"
  end
  if self:fully_grown() then

    -- TODO Move out of Plant class
    if not self.last_harvest_attempt or (lsGetTimer() - self.last_harvest_attempt) > self.config.harvest_delay_time then
      self.last_harvest_attempt = lsGetTimer()
      if self.controller:harvest() then
        print('PLANT ' .. self.index .. ' HARVESTED ')
        self.harvested = true
        return "harvested"
      end
    end
  else
    if self.config.calibration_mode then
      if not self.inserted_first_stage_time then
        self:insert_stage_times_header()
        self:update_stage_times()
        self.inserted_first_stage_time = true
      end
      local xyWindowSize = srGetWindowSize();
      local change_count = self.controller:check_how_many_plant_pixels_changed()
      local limit = self.config.non_onion_calibration_mode_change_threshold or 1
      if self.config.seed_type == 'Onions' then
        limit = self.config.onion_calibration_mode_change_threshold or 4.5
      end
      local limit_percent = limit / 100
      local pixel_limit = xyWindowSize[0] * limit_percent
      pixel_limit = pixel_limit * pixel_limit * (self.stage / 1.5)
      if (self.config.debug or self.config.debug_log) and change_count ~= 0 then
        print(' count = ' .. change_count .. ' vs ' .. pixel_limit)
      end
      if lsGetTimer() - self.previous_stage_ended_at > 25000 then
        print("CALIBRATION STAGE TIMED OUT")
        self.controller.bad_calibration = true
        apply_calibration_fix(self.config, -0.5)
        return "wait-till-dead"
      end
      if change_count > pixel_limit then
        if self.config.debug or self.config.debug_log then
          print('-------------------------')
          print('BIG CHANGE ' .. change_count)
          print('-------------------------')
        end
        if lsGetTimer() - self.previous_stage_ended_at < 6000 then
          print("DETECTED TOO EARLY CHANGE IN CALIBRATION")
          self.controller.bad_calibration = true
          apply_calibration_fix(self.config, 0.5)
          return "wait-till-dead"
        else
          self.previous_stage_ended_at = lsGetTimer()
          self:change_stage(1)
          self:update_stage_times()
        end
      end
    else
      if lsGetTimer() > self.next_stage_starts_at then
        self.previous_stage_ended_at = self.next_stage_starts_at
        self:change_stage(self.current_stage_watered and 1 or -1)
      end
    end
    if self.stage <= self.number_of_growth_stages then
      if not self.current_stage_watered then
        self.current_stage_watered = self:water()
      end
    end
  end
  return "growing"
end

function Plant:finished()
  return self:dead() or (self.harvested)
end

function Plant:change_stage(direction)
  lsPrintln("Plant " .. self.index .. " changing stage at " .. (lsGetTimer() - self.plant_time) ..
    " in stage " .. self.stage .. " to stage " .. (self.stage + direction))
  self.prev_stage = self.stage
  self.stage = self.stage + direction
  self.current_stage_watered = false
  self.next_stage_starts_at = lsGetTimer() + self:time_till_stage_advances(self.stage)
end

function Plant:time_till_stage_advances(stage)
  if self:fully_grown(stage) then
    return self.config.harvest_delay_time * 5
  else
    local timings = self.config.plants[self.config.seed_type][self.config.seed_name].stage_advance_timings
    return timings[stage] or timings["Default"]
  end
end

function Plant:time_till_death()
  if self:fully_grown() or self:dead() or self.harvested then
    return 100000
  end
  local next_stage = self.current_stage_watered and self.stage + 1 or self.stage - 1
  local regress_times = 0
  if self.stage > 0 then
    for i = next_stage, 1, -1 do
      regress_times = regress_times + self:time_till_stage_advances(i)
    end
  end

  return (self.next_stage_starts_at + regress_times) - lsGetTimer()
end

function Plant:water()
  local result = self.controller:water()
  lsPrintln("Plant " .. self.index .. "water delay is " .. (lsGetTimer() - self.previous_stage_ended_at) .. " watered at " .. (lsGetTimer() - self.plant_time) ..
    " in stage " .. self.stage .. " death " .. self:time_till_death() .. " next " .. (self.next_stage_starts_at - lsGetTimer()))
  return result
end

function Plant:harvest()
  return self.controller:harvest()
end
