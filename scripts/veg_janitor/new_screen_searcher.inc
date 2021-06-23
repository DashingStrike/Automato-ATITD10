dofile("veg_janitor/util.inc")
dofile("veg_janitor/screen.inc")
dofile("veg_janitor/binsert.inc")

RegionProxy = {}
function RegionProxy:new(x, y, dead)
  local o = {}
  o.region = Region:new(x, y, dead)
  return newObject(self, o)
end

function RegionProxy:add(x, y)
  self.region:add(x, y)
end

function RegionProxy:connect(other_region, connecting_x, connecting_y)
  if other_region:id() ~= self:id() then
    self.region:connect(other_region.region, connecting_x, connecting_y)
    other_region.region = self.region
  else
    self.region:add(connecting_x, connecting_y)
  end
end

function RegionProxy:get_center(x, y)
  return self.region:get_center(x, y)
end

function RegionProxy:size()
  return self.region.size
end

function RegionProxy:id()
  return self.region.id
end

function RegionProxy:dead()
  return self.region.dead
end

next_free_region_id = 1
Region = {}
function Region:new(x, y, dead)
  local o = {}
  o.size = 1
  o.min_y = y
  o.max_y = y
  o.min_x = x
  o.max_x = x
  o.dead = dead
  o.id = next_free_region_id
  next_free_region_id = next_free_region_id + 1
  return newObject(self, o)
end

function Region:add(x, y)
  self.size = self.size + 1
  self.min_x = math.min(self.min_x, x)
  self.min_y = math.min(self.min_y, y)
  self.max_x = math.max(self.max_x, x)
  self.max_y = math.max(self.max_y, y)
end

function Region:connect(other_region, connecting_x, connecting_y)
  self.size = self.size + other_region.size + 1
  self.min_x = math.min(self.min_x, connecting_x, other_region.min_x)
  self.min_y = math.min(self.min_y, connecting_y, other_region.min_y)
  self.max_x = math.max(self.max_x, connecting_x, other_region.max_x)
  self.max_y = math.max(self.max_y, connecting_y, other_region.max_y)
end

function Region:get_center(x_offset, y_offset)
  local center_x = math.floor((self.max_x + self.min_x) / 2) + x_offset
  local center_y = math.floor((self.max_y + self.min_y) / 2) + y_offset
  return { ['x'] = center_x, ['y'] = center_y }
end

SeedSearcher = {}
function SeedSearcher:new(search_box)
  local o = {}
  o.search_box = search_box
  o.tolerance = 1000
  o.initial_box_pixels = getBoxPixels(search_box)
  o.regions = {}
  o.pixel_to_region = {}
  o.dead_pixel_to_region = {}
  o.dead_min_x = 99999999
  o.dead_min_y = 99999999
  o.dead_max_x = -1
  o.dead_max_y = -1
  return newObject(self, o)
end
function SeedSearcher:markAnyChangedRegionsAsDeadZone()
  self:findChangedRegions(0, false, true)
end

function SeedSearcher:resetNonDead()
  self.pixel_to_region = {}
  self.regions = {}
end

function SeedSearcher:resnapshot()
  self.initial_box_pixels = getBoxPixels(self.search_box)
end

function SeedSearcher:dead_box()
  local fudge = 5
  return makeBox(self.dead_min_x + self.search_box.x - fudge,
    self.dead_min_y + self.search_box.y - fudge,
    self.dead_max_x - self.dead_min_x + 1 + fudge * 2,
    self.dead_max_y - self.dead_min_y + 1 + fudge * 2)
end

function SeedSearcher:findChangedRegions(size_filter, top_x, mark_as_dead, drawSeen)
  srReadScreen()

  local box = self.search_box

  for y = 0, box.height, 1 do
    self.pixel_to_region[y] = self.pixel_to_region[y] or {}
    self.dead_pixel_to_region[y] = self.dead_pixel_to_region[y] or {}
    for x = 0, box.width do
      local new_pixel = srReadPixelFromBuffer(box.left + x, box.top + y)
      local same = compareColorEx(self.initial_box_pixels[y][x], new_pixel, self.tolerance, self.tolerance)

      if not same then
        self:connectChangedPixelToSurroundingRegions(x, y, mark_as_dead)
        if mark_as_dead then
          self.dead_min_x = math.min(self.dead_min_x, x)
          self.dead_min_y = math.min(self.dead_min_y, y)
          self.dead_max_x = math.max(self.dead_max_x, x)
          self.dead_max_y = math.max(self.dead_max_y, y)
        end
      end
    end
  end

  if drawSeen then
    self:drawRegions(size_filter)
  end

  if top_x then
  local regions_with_size_greater_than_filter = {}
  local seen_regions = {}
  for _, region in ipairs(self.regions) do
    if not seen_regions[region:id()] then
      seen_regions[region:id()] = true
      if region:size() >= size_filter then
        local fcomp = function(a, b)
          return a:size() > b:size()
        end
        table.binsert(regions_with_size_greater_than_filter, region, fcomp)
      end
    end
  end
  local result = {}
  for i=1, math.min(#regions_with_size_greater_than_filter, top_x) do
    table.insert(result ,regions_with_size_greater_than_filter[i]:get_center(self.search_box.x, self.search_box.y))
  end
  return result
  end
end

function SeedSearcher:drawRegions(size_filter)
  lsSleep(1000)
  lsDoFrame()
  local box = self.search_box
  local pixel_to_region = self.pixel_to_region
  for y = 0, box.height, 1 do
    for x = 0, box.width do
      if pixel_to_region[y] and pixel_to_region[y][x] then
        local colours = { GREEN, BLUE, YELLOW, PINK, BROWN, PURPLE, LIGHT_BLUE, GREEN, BLUE }
        local region = pixel_to_region[y][x]
        local index = math.fmod(region:id(), #colours) + 1
        local colour = colours[index]
        if size_filter and region:size() < size_filter then
          colour = RED
        end
        if region:dead() then
          colour = YELLOW
        end
        lsDisplaySystemSprite(1, x, y, 1, 1, 1, colour)
      end
    end
  end
  lsDoFrame()
  lsSleep(3000)

end

function SeedSearcher:connectChangedPixelToSurroundingRegions(x, y, dead)
  local above_region = false
  local left_region = false
  local pixel_to_region = self.pixel_to_region

  if dead then
    pixel_to_region = self.dead_pixel_to_region
  end
  local regions = self.regions
  if self.dead_pixel_to_region[y] and self.dead_pixel_to_region[y][x] then
    return
  end

  if y - 1 >= 0 then
    above_region = pixel_to_region[y - 1][x]
  end
  if x - 1 >= 0 then
    left_region = pixel_to_region[y][x - 1]
  end

  local resulting_region = nil
  if above_region and left_region then
    above_region:connect(left_region, x, y)
    resulting_region = above_region
  elseif above_region then
    above_region:add(x, y)
    resulting_region = above_region
  elseif left_region then
    left_region:add(x, y)
    resulting_region = left_region
  else
    local new_region = RegionProxy:new(x, y, dead)
    if not dead then
      table.insert(regions, new_region)
    end
    resulting_region = new_region
  end
  pixel_to_region[y][x] = resulting_region
end
