dofile("veg_janitor/util.inc")
dofile("veg_janitor/screen.inc")
dofile("veg_janitor/binsert.inc")

MinMaxTracker = {}
function MinMaxTracker:new(x, y)
  local o = {}
  o.size = 1
  o.min_y = y
  o.max_y = y
  o.min_x = x
  o.max_x = x
  return newObject(self, o)
end
function MinMaxTracker:update(x, y)
  self.size = self.size + 1
  self.min_x = math.min(self.min_x, x)
  self.min_y = math.min(self.min_y, y)
  self.max_x = math.max(self.max_x, x)
  self.max_y = math.max(self.max_y, y)
end
function MinMaxTracker:width()
  return self.max_x - self.min_x + 1
end
function MinMaxTracker:height()
  return self.max_y - self.min_y + 1
end

PlantFinder = {}
function PlantFinder:new(search_box)
  local o = {}
  o.search_box = search_box
  o.tolerance = 1000
  o.initial_box_pixels = getBoxPixels(search_box)
  o.pixels = {}
  o.plant_min_maxes = {}
  return newObject(self, o)
end
function PlantFinder:resnapshot()
  self.initial_box_pixels = getBoxPixels(self.search_box)
end

function PlantFinder:markAnyChangedRegionsAsDeadZone()
  self:findChangedRegions(-1)
end
function PlantFinder:excludeDeadBox(dead_box)
  local box = self.search_box

  for y = box.top, box.bottom do
    self.pixels[y-box.top] = self.pixels[y-box.top] or {}
    for x = box.left, box.right do
      if dead_box.left <= x and dead_box.right >= x and dead_box.top <= y and dead_box.bottom >= y then
        self.pixels[y-box.top][x-box.left] = -1
      end
    end
  end
end

function PlantFinder:findChangedRegions(plant_index)
  srReadScreen()

  local box = self.search_box

  for y = 0, box.height do
    self.pixels[y] = self.pixels[y] or {}
    for x = 0, box.width do
      local new_pixel = srReadPixelFromBuffer(box.left + x, box.top + y)
      local same = compareColorEx(self.initial_box_pixels[y][x], new_pixel, self.tolerance, self.tolerance)

      if not same and self.pixels[y][x] ~= -1 then
        self.pixels[y][x] = plant_index
        local tracker = self.plant_min_maxes[plant_index]
        if tracker then
          tracker:update(x, y)
        else
          self.plant_min_maxes[plant_index] = MinMaxTracker:new(x, y)
        end
      end
    end
  end
end
function PlantFinder:getSearchBoxForPlant(plant_index)
  local tracker = self.plant_min_maxes[plant_index]
  local xyScreenSize = srGetWindowSize();
  local extra_width = xyScreenSize[0] * 0.02
  local extra_height = xyScreenSize[0] * 0.02

  return makeBox(tracker.min_x + self.search_box.x - extra_width, tracker.min_y + self.search_box.y - extra_height, tracker:width() + extra_width*2, tracker:height() + extra_height*2)
end

function PlantFinder:findFurthestPixelFromEdgeForPlant(plant_index, debug)
  local tracker = self.plant_min_maxes[plant_index]

  local weird_tracker = MinMaxTracker:new(0, 0)
  weird_tracker.max_x = tracker.max_x + 2
  weird_tracker.max_y = tracker.max_y + 2
  weird_tracker.min_x = tracker.min_x - 2
  weird_tracker.min_y = tracker.min_y - 2

  local c_result = chamfer_distance(weird_tracker, self.pixels, plant_index)
  local result = {}
  result.vector  = Vector:new{x=c_result.max_x+weird_tracker.min_x + self.search_box.left, y=c_result.max_y+weird_tracker.min_y+self.search_box.top}
  result.pixel = self.initial_box_pixels[c_result.max_y+weird_tracker.min_y][c_result.max_x+weird_tracker.min_x]

  if debug  then
    --moveMouse(result.vector)
    --lsDoFrame()
    --lsPrintWrapped(10, 100, 0, lsScreenX - 20, 1, 1, 0xd0d0d0ff, 'Click location for plant ' .. plant_index);
    --lsDoFrame()
    --lsSleep(5000)
  end
  if debug then
    print("DRAWING")
    local dt = c_result.dt
    for y = 0, weird_tracker:height() do
      for x = 0, weird_tracker:width() do
        local distance = 0
        if dt[y] and dt[y][x] then
          distance = dt[y][x]
        end
        local colour = BLACK
        if distance > 0 then
          colour = WHITE
        end
        if c_result.max_x == x and c_result.max_y == y then
          colour = RED
        end
        lsDisplaySystemSprite(1, x, y, 1, 1, 1, colour)

      end
    end
    lsDoFrame()
    lsSleep(5000)
  end
  return result
end

function PlantFinder:drawLayers()
  lsSleep(1000)
  lsDoFrame()
  local colours = { [1] = GREEN, [2] = BLUE, [3] = YELLOW, [4] = PINK, [5] = BROWN, [6] = PURPLE, [7] = LIGHT_BLUE, [8] = GREEN, [9] = BLUE }
  local box = self.search_box
  local pixels = self.pixels
  local plant_to_colour = { [-1] = RED }
  local next_colour = 1
  for y = 0, box.height, 1 do
    for x = 0, box.width do
      if pixels[y] and pixels[y][x] then
        local plant_index = pixels[y][x]
        if not plant_to_colour[plant_index] then
          plant_to_colour[plant_index] = colours[next_colour]
          next_colour = next_colour + 1
          if next_colour > 9 then
            next_colour = 1
          end
        end
        local colour = plant_to_colour[plant_index] or BLACK
        lsDisplaySystemSprite(1, x, y, 1, 1, 1, colour)
      end
    end
  end
  lsDoFrame()
  lsSleep(3000)

end

function test_c()
  local o = -1
  local x = 1
  local pixels = {
    [0] = { [0] = o, o, o, o, x, o, o },
    [1] = { [0] = o, o, o, o, o, o, o },
    [2] = { [0] = o, o, x, x, x, x, o },
    [3] = { [0] = o, x, x, x, x, x, o },
    [4] = { [0] = o, x, x, x, x, x, o },
    [5] = { [0] = o, x, x, x, x, x, o },
    [6] = { [0] = o, o, o, x, o, x, o },
    [7] = { [0] = o, o, o, o, o, o, o },
  }
  local tracker = nil
  for y = 0, 7 do
    for x2 = 0, 6 do
      if pixels[y][x2] == x then
        if not tracker then
          tracker = MinMaxTracker:new(x2, y)
        else
          tracker:update(x2, y)
        end
      end
    end
  end
  tracker.max_x = tracker.max_x + 2
  tracker.max_y = tracker.max_y + 2
  tracker.min_x = tracker.min_x - 2
  tracker.min_y = tracker.min_y - 2
  local result = chamfer_distance(tracker, pixels, x)
  for y = 0, tracker:height() - 1 do
    local line = ''
    for x2 = 0, tracker:width() - 1 do
      local r = result.dt[y][x2]
      local prefix = ''
      if not r then
        r = '--'
      else
        if r < 10 then
          prefix = '0'
        end
      end
      line = line .. '  ' .. prefix .. r
    end
    print(line)
  end
  print('max = ' .. result.max_x .. ', ' .. result.max_y .. ' = ' .. result.max_dt)
end

function is_outside_pixel(y, x, pixels, plant_index)
  return pixels[y] and pixels[y][x] and plant_index == pixels[y][x]
end


function chamfer_distance(tracker, pixels, plant_index)
  function fr(r)
    if r == nil then
      return 0
    else
      return r
    end
  end

  local w = tracker:width()
  local h = tracker:height()
  local dt = { [0] = {} }

  local top = tracker.min_y
  local left = tracker.min_x
  print('Top = ' .. top)
  print('Left = ' .. left)
  print('w = ' .. w)
  print('h = ' .. h)

  if is_outside_pixel(top, left, pixels, plant_index) then
    dt[0][0] = 65535
  end
  for x = 1, w - 1 do
    local y = 0
    if is_outside_pixel(y + top, x + left, pixels, plant_index) then
      dt[y][x] = 3 + fr(dt[y][x - 1])
    end
  end
  for y = 1, h - 1 do
    dt[y] = dt[y] or {}
    if is_outside_pixel(y + top, left, pixels, plant_index) then
      dt[y][0] = math.min(3 + fr(dt[y - 1][0]), 4 + fr(dt[y - 1][1]))
    end
    for x = 1, w - 2 do
      if is_outside_pixel(y + top, left + x, pixels, plant_index) then
        dt[y][x] = math.min(4 + fr(dt[y - 1][x - 1]), 3 + fr(dt[y - 1][x]), 4 + fr(dt[y - 1][x + 1]), 3 + fr(dt[y][x - 1]))
      end
    end
    local x = w - 1
    if is_outside_pixel(y + top, x + left, pixels, plant_index) then
      dt[y][x] = math.min(4 + fr(dt[y - 1][x - 1]), 3 + fr(dt[y - 1][x]), 3 + fr(dt[y][x - 1]))
    end
  end

  -- Backwards pass
  local max_x = 0
  local max_y = 0
  local max_dt = -1
  for x = w - 2, 0, -1 do
    local y = h - 1
    if is_outside_pixel(top + y, x + left, pixels, plant_index) then
      dt[y][x] = math.min(fr(dt[y][x]), 3 + fr(dt[y][x + 1]))
      if dt[y][x] > max_dt then
        max_x = x
        max_y = y
        max_dt = dt[y][x]
      end
    end
  end
  for y = h - 2, 0, -1 do
    local x = w - 1
    if is_outside_pixel(top + y, left + x, pixels, plant_index) then
      dt[y][x] = math.min(fr(dt[y][x]), 3 + fr(dt[y + 1][x]), 3 + fr(dt[y + 1][x - 1]))
      if dt[y][x] > max_dt then
        max_x = x
        max_y = y
        max_dt = dt[y][x]
      end
    end
    for x2 = 1, w - 2 do
      if is_outside_pixel(top + y, left + x2, pixels, plant_index) then
        dt[y][x2] = math.min(fr(dt[y][x2]), 4 + fr(dt[y + 1][x2 + 1]), 3 + fr(dt[y + 1][x2]), 4 + fr(dt[y + 1][x2 - 1]), 3 + fr(dt[y][x2 + 1]))
        if dt[y][x2] > max_dt then
          max_x = x2
          max_y = y
          max_dt = dt[y][x2]
        end
      end
    end
    x = 0
    if is_outside_pixel(top + y, left + x, pixels, plant_index) then
      dt[y][x] = math.min(fr(dt[y][x]), 4 + fr(dt[y + 1][x + 1]), 3 + fr(dt[y + 1][x]), 3 + fr(dt[y][x + 1]))

      if dt[y][x] > max_dt then
        max_x = x
        max_y = y
        max_dt = dt[y][x]
      end
    end
  end
  local result = {}
  result.dt = dt
  result.max_x = max_x
  result.max_y = max_y
  result.max_dt = max_dt
  return result
end
