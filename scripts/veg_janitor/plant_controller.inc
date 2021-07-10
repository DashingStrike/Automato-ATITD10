dofile("veg_janitor/util.inc")
dofile("veg_janitor/plant.inc")
dofile("veg_janitor/vector.inc")
dofile("veg_janitor/screen.inc")
dofile("veg_janitor/calibration.inc")
dofile("screen_searcher.inc")
dofile("veg_janitor/logger.inc")

PlantController = {}
function PlantController:new(index, location, alternate_drag, window_pos, seed_name, seed_type, num_water_times, config, existing_unpin_locations)
  if index == nil or location == nil or alternate_drag == nil or window_pos == nil or num_water_times == nil or config == nil then

    error("Invalid or missing arguments for PlantController:new")
  end
  local o = {}
  o.config = config
  o.index = index
  o.state = "unplanted"
  o.location = location
  o.alternate_drag = alternate_drag
  o.window_pos = window_pos
  o.seed_name = seed_name
  o.seed_type = seed_type
  o.last_ticked_time = 0
  o.saved_plant_location = false
  o.saved_plant_pixel = false
  o.window_open = false
  o.num_water_times = num_water_times
  o.plant = nil
  o.plant_time = nil
  o.beforePlantPixels = nil
  o.last_clicked_plant_at = 0
  o.undragged_window_open = false
  o.dragged_at = 0
  o.change_count_log = {}
  o.prevCheckPixels = nil
  o.harvested = false
  o.existing_unpin_locations = existing_unpin_locations
  o.open_attempts = 0
  o.searcher = nil
  o.snapshoting_water_animations = false
  o.watered_at = nil
  o.bad_calibration = true
  o.bad_calibration_config_change = 0.5

  return newObject(self, o)
end

function PlantController:partiallyResetState()
  self.state = "unplanted"
  self.last_ticked_time = 0
  self.window_open = false
  self.plant = nil
  self.plant_time = nil
  self.last_clicked_plant_at = 0
  self.undragged_window_open = false
  self.dragged_at = 0
  self.saved_plant_pixel = false
  self.search_box = nil
  self.prevCheckPixels = nil
  self.harvested = false
  self.change_count_log = {}
  self.searcher = nil
  self.snapshoting_water_animations = false
  self.watered_at = nil
  self.open_attempts = 0
  self.bad_calibration = true
  self.bad_calibration_config_change = 0.5
end

function PlantController:output_calibration_data()
  writeCsvFileTo(CALIBRATION_LOG_FILE_NAME, self.plant.measured_stage_times)
end

function PlantController:time_till_death()
  if self.state == "unplanted" then
    return 10000
  elseif self.state == "searching" then
    return 10000
  elseif self.state == "opening" then
    return 10000
  elseif self.state == "growing" then
    return self.plant:time_till_death()
  elseif self.state == "complete" then
    return 100000
  elseif self.state == "wait-till-death" then
    return self.plant:time_till_death()
  elseif self.state == "closed" then
    return 100000
  else
    error("Unknown controller state in time_till_death " .. self.state)
  end
end
function PlantController:status()
  if self.state == "unplanted" then
    return "unplanted"
  elseif self.state == "searching" then
    return "searching"
  elseif self.state == "opening" then
    return "opening"
  elseif self.state == "growing" then
    return self.plant:status()
  elseif self.state == "wait-till-dead" then
    return "waiting till plant dies"
  elseif self.state == "complete" then
    return "complete"
  elseif self.state == "closed" then
    return "closed"
  else
    error("Unknowng controller state in status " .. self.state)
  end
end

function PlantController:finished()
  return self.state == "complete"
end

function PlantController:died()
  return not self.harvested
end

function PlantController:tick()
  self.last_ticked_time = lsGetTimer()
  if self.state == "closed" then
    return self.state
  end
  if self:dead() then
    self.state = "complete"
    return self.state
  end
  if self.state == "unplanted" then
    self:grow_plant()
    self.state = "opening"
  elseif self.state == "opening" then
    if self:openBedWindow() then
      find_and_click_image("pin", self.window_pos)
      self.window_open = true
      self.state = "growing"
    end
  elseif self.state == 'wait-till-dead' then
    -- Refresh the window so we can see when the plant dies.
    self:harvest()
  elseif self.state == "growing" then
    local plant_state = self.plant:tick()
    if plant_state ~= "growing" then
      if plant_state == "wait-till-dead" then
        self.state = plant_state
      else
        self.state = "complete"
      end
    else
      if self.snapshoting_water_animations then
        if self.watered_at and lsGetTimer() - self.watered_at > 3000 then
          self.snapshoting_water_animations = false
        else
          self.searcher:markChangesAsDeadZone('before')
        end
      end
    end
  elseif self.state == "complete" then
    self:close()
    self.state = "closed"
  end
  return self.state
end

function PlantController:dead()
  local search_box = makeBox(self.window_pos.x - 15, self.window_pos.y - 15, 200, 70)
  srReadScreen()
  local dead = findImage("veg_janitor/dead.png", search_box)
  local r = dead or not self.window_open and (self.plant_time and (lsGetTimer() - self.plant_time) > 7000) or self.harvest_time and (lsGetTimer() - self.harvest_time > 7000)
  self:_log(TRACE, "dead? " .. (r and 'dead' or 'alive') .. " | " .. self.window_pos.x .. ", " .. self.window_pos.y);
  return r
end

function PlantController:close()
  -- New UI changes affected the closing of finished windows.
  -- Now look for the UnPin image, and safeClick it closed if found.

  local search_box = makeBox(self.window_pos.x + 15, self.window_pos.y - 15, 220, 80)
  srReadScreen()
  local unpin_loc = srFindImageInRange("UnPin.png", search_box.left, search_box.top, search_box.width, search_box.height, 4800)
  if unpin_loc then
    safeClick(unpin_loc[0], unpin_loc[1]);
  else
    self:_log(INFO,"Didn't find unpin image for plant " .. self.index .. " looking left:" .. search_box.left .. ", top: " .. search_box.top .. ", width: " .. search_box.width .. ", height: " .. search_box.height .. ".");
    return
  end
end

function PlantController:_log(level, message)
  veg_log(level, self.config.debug_log_level, 'plant_controller.inc', message)
end

function PlantController:grow_plant()
  -- Take of a snapshot of the area in which we are guessing the plant will be placed before we actually create
  -- and place it.

  if self.saved_plant_location then
    self.saved_plant_pixel = srReadPixel(self.saved_plant_location.x, self.saved_plant_location.y)
  end

  local buildButton = clickPlantButton(self.seed_name)
  self.location:move()
  safeClick(buildButton[0], buildButton[1])
  self.plant_time = lsGetTimer()
  self.plant = Plant:new(self.index, self.plant_time, self, self.config)
  if self.config.calibration_mode then
    self.searcher = ScreenSearcher:new(self.location.box, 'compareColorEx', self.config.debug_log_level)
    self.searcher:snapshotScreen('before')
    self.snapshoting_water_animations = true
  end
end

function clickPlantButton(seed_name)
  local build_menu_opened = false
  while not build_menu_opened do
    local plantPos = findImage("plant.png", nil, 7000)
    if plantPos then
      safeClick(plantPos[0], plantPos[1])
      build_menu_opened = waitForImage("veg_janitor/build_button.png", 1000, "Waiting for build button to appear")
    else
      playErrorSoundAndExit("Plant button not found")
    end
    sleepWithStatus(tick_delay, "Planting...") --Retrying build menu open
  end
  return build_menu_opened
end

function checkPlantButton()
  local plantPos = findImage("plant.png", nil, 7000)
  if not plantPos then
    playErrorSoundAndExit("Plant button not found")
  end

end

function PlantController:find_and_click_self()
  return find_and_click_image("this_is", self.window_pos)
end

function PlantController:harvest()
  local this_vec = self:find_and_click_self()
  if not this_vec then
    return false
  end

  local harvest_vec = findImageInWindowVec("harvest", self.window_pos)
  if not harvest_vec then
    return false
  end
  if harvest_vec then
    click(harvest_vec)
    lsSleep(click_delay / 2)
    self.harvested = true
    self.bad_calibration = false
    self.harvest_time = lsGetTimer()
    return self:dead()
  else
    return false
  end
end

function PlantController:water()
  local water_vec = findImageInWindowVec("water", self.window_pos)
  if not water_vec then
    local this_vec = self:find_and_click_self()
    if not this_vec then
      return false
    end
    water_vec = findImageInWindowVec("water", self.window_pos)
    if not water_vec then
      return false
    end
  end

  for _ = 1, self.num_water_times do
    click(water_vec)
    lsSleep(20)
  end
  if self.snapshoting_water_animations then
    self.watered_at = lsGetTimer()
  end
  return true
end
function PlantController:check_how_many_plant_pixels_changed()
  if self.snapshoting_water_animations then
    return 0
  end
  return self.searcher:countNumberChanged('before', 'before')
end

function PlantController:openBedWindow()
  -- TODO: problably do something different as this is the only thing that takes mouse control from the user.
  if self.alternate_drag then

    if not self.undragged_window_open and (not self.last_clicked_plant_at or (lsGetTimer() - self.last_clicked_plant_at) > 500) then
      local current_pixel = srReadPixel(self.saved_plant_location.x, self.saved_plant_location.y)
      local new_colour = current_pixel
      local click_colour = self.saved_plant_pixel
      local pixel_same = new_colour == click_colour
      if pixel_same or not self.config.only_click_when_pixel_changes_mode then
        self.last_clicked_plant_at = lsGetTimer()
        click(self.saved_plant_location, false, true)
        lsSleep(click_delay)
        click(self.saved_plant_location, true, true)
        lsSleep(click_delay)
      else
        self:_log(INFO, "Pixel matches recorded before planting colour of " .. click_colour .. ", not clicking.")
      end
      self.open_attempts = self.open_attempts + 1
    end
    if findImageInWindowVec("this_is", self.saved_plant_location) and (not self.dragged_at or (lsGetTimer() - self.dragged_at) > 500) then
      self.undragged_window_open = true
      drag(self.saved_plant_location.x + 10, self.saved_plant_location.y + 10, self.window_pos.x, self.window_pos.y, click_delay * 2)
      lsSleep(100)
      self.dragged_at = lsGetTimer()
      self.window_open = findImageInWindowVec("this_is", self.window_pos)
      return self.window_open
    else
      self.window_open = findImageInWindowVec("this_is", self.window_pos)
      if not self.window_open then
        local found_new_window = findRemoveNewWindows(self.existing_unpin_locations)
        if found_new_window or self.open_attempts > 3 then
          self:_log(INFO, 'Failed due to click opening unknown window for plant: ' .. self.index)
          self.state = "complete"
        end
      end
      return self.window_open
    end
  else
    -- Wierd hacky thing, move the mouse to where the window will be and then safeClick the plant which causes
    -- the window to open instantly at the desired location and not where we clicked the plant.
    moveMouse(self.window_pos)
    click(self.saved_plant_location, 1)
    self.window_open = findImageInWindowVec("this_is", self.window_pos)
    return self.window_open
  end
end

function PlantController:set_search_box(box)
  self.location.box = box
end


