dofile("veg_janitor/util.inc")
dofile("veg_janitor/screen.inc")
dofile("veg_janitor/binsert.inc")
dofile("veg_janitor/io.inc")
dofile("veg_janitor/logger.inc")
dofile("screen_reader_common.inc")

-------------------------------------------------------------------------------
-- ScreenSearcher is a utility class that detects areas of changed pixels in a box on the screen. For example you can
-- use it to find a plant placed on the screen by your macro, or ore nodes which have appeared. It can then identify
-- the best places to click inside of these areas of changed pixels. Finally it provides an easy way of filtering out
-- bad areas of the screen it should ignore, also know as the "dead area".
-- For example you could trigger a certain animation on the screen and whilst it is occurring mark any changed pixels
-- as being "dead", this way guaranteeing that future regions identified by that screenSearcher will never include any
-- dead areas. This is very useful for ensuring you never click on the player or other animated things on the screen.
--
-- It works by first creating a new ScreenSearcher with a box to search.
--
-- local quarterScreenWidth = srGetWindowSize()[0] / 4
-- local yourBoxToSearch = makeLargeSearchBoxAroundPlayer(quarterScreenWidth)
-- local screenSearcher = ScreenSearcher:new(yourBoxToSearch)
--
-- You can use any box using the makeBox function however I also provide the makeLargeSearchBoxAroundPlayer helper
-- function which takes the desired width of the box and creates on centered on the player.
--
-- Then you can take a snapshot of the screen's pixels in the box, which will be stored inside the ScreenSearcher
-- using the name you provide:
--
-- screenSearcher:snapshotScreen('before')
--
-- Finally you can then using the previous snapshot find and identify all the areas of pixels which have changed in
-- the ScreenSearcher's box.
--
-- triggerSomeObjectToAppearOnScreen()
-- screenSearcher:markAllChangesAsRegion('before', 'myObject')
-- local myObjectsLocationOnScreen = screenSearcher:findPointInRegionFurthestFromEdge('myObject')
-- click(myObjectsLocationOnScreen)
-------------------------------------------------------------------------------

ScreenSearcher = {}
function ScreenSearcher:new(search_box, comparisonMode, logLevel)
  local o = {}
  o.box = search_box
  o.snapshots = {} -- A Map from snapshot name to a 2d table of pixel values for that snapshot
  o.screenToRegionMap = {} -- A 2d table of every location in the box to its region
  o.regions = {} -- A list of the regions
  o.nextFreeConnectedRegionId = 0
  o.comparisonMode = comparisonMode or 'equality' -- Can be 'equality' or 'compareColorEx'
  -- These tolerances are only used when the comparisonMode is set to 'compareColorEx' and will be passed to the
  o.rgbTolerance = 1000
  o.hueTolerance = 1000
  o.deadRegionName = -1 -- A built in region which forces all other regions to ignore locations in this region.
  o.logLevel = logLevel
  return newObject(self, o)
end

-------------------------------------------------------------------------------
-- Takes and stores a snapshot of the pixels inside this ScreenSearcher's box under the provided name.
-------------------------------------------------------------------------------
function ScreenSearcher:snapshotScreen(newSnapshotName)
  self.snapshots[newSnapshotName] = getBoxPixels(self.box)
end

-------------------------------------------------------------------------------
-- Comparing against a previous snapshot reads the screen and marks any changed pixels in the box as "dead"
-- A "dead" pixel can never be used by another region and so will prevent clicks etc occurring in these areas.
-------------------------------------------------------------------------------
function ScreenSearcher:markChangesAsDeadZone(snapshotToCompareAgainst,
                                              optionalSnapshotToSaveNewPixelsIn)

  return self:_searchChangedPixelsAndSetupRegions(snapshotToCompareAgainst, self.deadRegionName, optionalSnapshotToSaveNewPixelsIn)
end

-------------------------------------------------------------------------------
-- Comparing against a previous snapshot marks every changed pixel as the region called regionName.
-------------------------------------------------------------------------------
function ScreenSearcher:markAllChangesAsRegion(snapshotToCompareAgainst,
                                               regionName,
                                               optionalSnapshotToSaveNewPixelsIn)

  if not regionName then
    playErrorSoundAndExit('A Region Name must be provided when calling markAllChangesAsRegion')
  end
  if regionName == self.deadRegionName then
    playErrorSoundAndExit('The provided name clashes with the dead regions name, please use another.')
  end
  return self:_searchChangedPixelsAndSetupRegions(snapshotToCompareAgainst, regionName, optionalSnapshotToSaveNewPixelsIn)
end

-------------------------------------------------------------------------------
-- Returns the number of changed pixels on the screen without changing any regions, excluding pixels in dead areas.
-------------------------------------------------------------------------------
function ScreenSearcher:countNumberChanged(snapshotToCompareAgainst,
                                           optionalSnapshotToSaveNewPixelsIn)

  return self:_searchChangedPixelsAndSetupRegions(
    snapshotToCompareAgainst,
    nil,
    optionalSnapshotToSaveNewPixelsIn,
    false)
end

-------------------------------------------------------------------------------
-- Comparing against a previous snapshot groups together connected changes areas into new regions called
-- 'connectedRegion_1' , 'connectedRegion_2' and so on.
-------------------------------------------------------------------------------
function ScreenSearcher:markConnectedAreasAsNewRegions(snapshotToCompareAgainst,
                                                       optionalSnapshotToSaveNewPixelsIn,
                                                       resetOldRegions)

  return self:_searchChangedPixelsAndSetupRegions(
    snapshotToCompareAgainst,
    nil,
    optionalSnapshotToSaveNewPixelsIn,
    true,
    resetOldRegions)
end

-------------------------------------------------------------------------------
-- Marks the provided box as being in the dead region.
-------------------------------------------------------------------------------
function ScreenSearcher:markBoxAsDead(deadBox)
  local box = self.box

  for y = box.top, box.bottom do
    local searcherY = y - box.top
    self.screenToRegionMap[searcherY] = self.screenToRegionMap[searcherY] or {}
    for x = box.left, box.right do
      local searcherX = x - box.left
      if deadBox.left <= x and deadBox.right >= x and deadBox.top <= y and deadBox.bottom >= y then
        self:_markLocationForRegion(searcherX, searcherY, self.deadRegionName)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- Returns the regions optionally filtered by a minimum size and/or returning only the largest N regions.
-------------------------------------------------------------------------------
function ScreenSearcher:getRegions(minRegionSizeFilter, keepLargestNRegionFilter)
  local fcomp = function(a, b)
    return a:size() > b:size()
  end
  local regionsPassingFilter = {}
  local seenRegions = {}
  for name, region in pairs(self.regions) do
    if not seenRegions[name] and name ~= self.deadRegionName then
      seenRegions[name] = true
      if region:size() >= minRegionSizeFilter or not minRegionSizeFilter then
        table.binsert(regionsPassingFilter, region, fcomp)
      end
    end
  end

  local result = {}
  if keepLargestNRegionFilter then
    for i = 1, math.min(#regionsPassingFilter, keepLargestNRegionFilter) do
      table.insert(result, regionsPassingFilter[i])
    end
  else
    result = regionsPassingFilter
  end
  return result
end

-------------------------------------------------------------------------------
-- Returns the regions optionally filtered by a minimum size and/or returning only the largest N regions.
-------------------------------------------------------------------------------
function ScreenSearcher:drawRegions(displayTime, minRegionSizeFilter, title)
  local furthestResults = {}
  for name, _ in pairs(self.regions) do
    if name ~= self.deadRegionName then
      local result = self:findFurthestPointFromEdgeForRegion(name)
      if result then
        local x = result.x - self.box.left
        local y = result.y - self.box.top
        furthestResults[y] = furthestResults[y] or {}
        furthestResults[y][x] = true
      end
    end
  end
  local startTime = lsGetTimer()
  lsDoFrame()
  local tickColour = RED
  while (not displayTime or lsGetTimer() - startTime < displayTime) and not lsShiftHeld() do
    local box = self.box
    local screenToRegionMap = self.screenToRegionMap
    local regionToColour = { [self.deadRegionName] = RED }
    local nextFreeColour = 1
    current_y = 10
    drawWrappedText(title or "Displaying all regions:", WHITE)
    for y = 0, box.height, 1 do
      for x = 0, box.width do
        if screenToRegionMap[y] and screenToRegionMap[y][x] then
          local colours = { GREEN, BLUE, YELLOW, PINK, BROWN, PURPLE, LIGHT_BLUE, GREEN, BLUE }
          local region = screenToRegionMap[y][x]
          local colour = regionToColour[region:name()]
          if not colour then
            colour = colours[nextFreeColour]
            regionToColour[region:name()] = colour
            nextFreeColour = nextFreeColour + 1
            if nextFreeColour > #colours then
              nextFreeColour = 1
            end
          end
          if minRegionSizeFilter and region:size() < minRegionSizeFilter then
            colour = BLACK
          end
          if furthestResults[y] and furthestResults[y][x] then
            colour = tickColour
          end
          if furthestResults[y - 1] and furthestResults[y - 1][x] then
            colour = tickColour
          end
          if furthestResults[y + 1] and furthestResults[y + 1][x] then
            colour = tickColour
          end
          if furthestResults[y] and furthestResults[y][x - 1] then
            colour = tickColour
          end
          if furthestResults[y] and furthestResults[y][x + 1] then
            colour = tickColour
          end
          lsDisplaySystemSprite(1, x, y + current_y, 1, 1, 1, colour)
        end
      end
    end
    if tickColour == RED then
      tickColour = BLUE
    elseif tickColour == BLUE then
      tickColour = GREEN
    else
      tickColour = RED
    end
    lsDoFrame()
    lsSleep(tick_delay)
    checkBreak()
  end
end

-------------------------------------------------------------------------------
-- Returns true if the regionName is a region.
-------------------------------------------------------------------------------
function ScreenSearcher:isRegion(regionName)
  return self.regions[regionName] ~= nil and self.regions[regionName] ~= false
end

-------------------------------------------------------------------------------
-- Returns the box encompassing all pixels for the given regionName, optionally expanded by the parameters.
-------------------------------------------------------------------------------
function ScreenSearcher:getRegionBox(regionName, optionalScreenSizePercentageToExpandBy, optionalFixedValueToExpandBy)

  self:_errorIfNotARegion(regionName)

  if not optionalScreenSizePercentageToExpandBy then
    optionalScreenSizePercentageToExpandBy = 0
  end
  if not optionalFixedValueToExpandBy then
    optionalFixedValueToExpandBy = 0
  end

  local region = self.regions[regionName]
  local xyScreenSize = srGetWindowSize();
  local extraWidth = xyScreenSize[0] * optionalScreenSizePercentageToExpandBy
  local extraHeight = xyScreenSize[1] * optionalScreenSizePercentageToExpandBy

  extraHeight = extraHeight + optionalFixedValueToExpandBy
  extraWidth = extraWidth + optionalFixedValueToExpandBy

  return region:getBox(self.box.left, self.box.top, extraWidth, extraHeight)
end

-------------------------------------------------------------------------------
-- For a given region finds the point in that region which is furthest in distance from the edges of that region
-- Great for calculating the best place to click on a region.
-------------------------------------------------------------------------------
function ScreenSearcher:findFurthestPointFromEdgeForRegion(regionName)
  self:_log(DEBUG, 'Finding furthest point from edge for ' .. regionName)

  local slightlyExpandedOddBox = self.regions[regionName]:getBox(0, 0, 2, 2)
  if not slightlyExpandedOddBox then
    return false
  end
  local c_result = chamfer_distance(slightlyExpandedOddBox, self.screenToRegionMap, regionName)
  local p = makePoint(
    c_result.max_x + slightlyExpandedOddBox.left + self.box.left,
    c_result.max_y + slightlyExpandedOddBox.top + self.box.top)
  p.x = p[0]
  p.y = p[1]
  self:_log(DEBUG, 'Found ' .. regionName .. ' furthest point of ' .. p.x .. ', ' .. p.y .. ' with distance from edge of ' .. c_result.max_dt)
  return p
end

---------------------------------------------------------------------------------------------
--- PRIVATE SCREEN SEARCHER FUNCTIONS, DO NOT CALL THESE DIRECTLY, INSTEAD USE THE ONES ABOVE
---------------------------------------------------------------------------------------------

function ScreenSearcher:_log(level, message)
  veg_log(level, self.logLevel, 'ScreenSearcher', message)
end

-------------------------------------------------------------------------------
-- This is an internal function which reads the screen and compares the new pixel values to the ones in the specified
-- snapshot. If optionalRegionNameToMarkChangesIn is provided then all changed pixels will be put into a region with
-- that name if they are not already dead pixels. If a location is already marked for a region the new region will
-- override and replace the old one.
-- If optionalRegionNameToMarkChangesIn is not provided instead this method will create a new region for every
-- continuously connected area of pixels with an automatically generated name beginning with 'connectedRegion_'
-- and followed by a unique number. This will also override any existing regions, and will also ignore dead areas.
-- However it is possible to end up with 'connectedRegions_' which are not actually connected if you call this
-- multiple times, where one of the subsequent calls overrides an old connected region changing the pixels for it.
-------------------------------------------------------------------------------
function ScreenSearcher:_searchChangedPixelsAndSetupRegions(snapshotToCompareAgainst,
                                                            optionalRegionNameToMarkChangesIn,
                                                            optionalSnapshotToSaveNewPixelsIn,
                                                            createNewConnectedRegions,
                                                            resetOldRegions)
  self:_errorIfSnapshotDoesntExist(snapshotToCompareAgainst)

  self:_log(DEBUG, 'Searching for changed pixels comparing against snapshot ' .. snapshotToCompareAgainst)
  if optionalRegionNameToMarkChangesIn then
    self:_log(DEBUG, 'Marking changes to region ' .. optionalRegionNameToMarkChangesIn)
  end

  if createNewConnectedRegions and optionalRegionNameToMarkChangesIn then
    playErrorSoundAndExit('Cannot set both createNewConnectedRegions and an optionalRegionNameToMarkChangesIn.')
  end


  if resetOldRegions then
    self:_log(DEBUG, 'Resetting old regions...')
    for name, _ in pairs(self.regions) do
      if name ~= self.deadRegionName then
        self.regions[name] = nil
      end
    end
  end

  srReadScreen()

  local newSnapshotPixels = {}
  local changedCount = 0
  local ignoreChangedCount = 0
  local didntChangeCount = 0
  for y = 0, self.box.height do
    newSnapshotPixels[y] = newSnapshotPixels[y] or {}
    for x = 0, self.box.width do
      local newPixel = srReadPixelFromBuffer(self.box.left + x, self.box.top + y)
      newSnapshotPixels[y][x] = newPixel
      local originalPixel = self.snapshots[snapshotToCompareAgainst][y][x]
      self.screenToRegionMap[y] = self.screenToRegionMap[y] or {}
      local existingRegion = self.screenToRegionMap[y][x]
      if resetOldRegions and existingRegion and existingRegion:name() ~= self.deadRegionName then
        self.screenToRegionMap[y][x]:delete(x, y)
        self.screenToRegionMap[y][x] = nil
      end
      if self:_pixelsAreDifferent(newPixel, originalPixel) then
        if optionalRegionNameToMarkChangesIn then
          changedCount = changedCount + self:_markLocationForRegion(x, y, optionalRegionNameToMarkChangesIn)
        elseif createNewConnectedRegions then
          changedCount = changedCount + self:_connectChangedPixelToSurroundingRegions(x, y)
        elseif self:_isNotDeadRegion(x, y) then
          changedCount = changedCount + 1
        else
          ignoreChangedCount = ignoreChangedCount + 1
        end
      else
        didntChangeCount = didntChangeCount + 1
      end
    end
  end
  if optionalSnapshotToSaveNewPixelsIn then
    self.snapshots[optionalSnapshotToSaveNewPixelsIn] = newSnapshotPixels
  end
  self:_log(DEBUG, 'Found ' .. changedCount .. ' changed pixels, ignored ' .. ignoreChangedCount .. ' and ' .. didntChangeCount .. ' did not change.')
  return changedCount
end

function ScreenSearcher:_errorIfSnapshotDoesntExist(newSnapshotName)
  if not self.snapshots[newSnapshotName] then
    if not newSnapshotName then
      playErrorSoundAndExit("Unknown snapshot name provided: " .. newSnapshotName)
    else
      playErrorSoundAndExit("No snapshot name provided")
    end
  end
end

function ScreenSearcher:_errorIfNotARegion(regionName)
  if not self.regions[regionName] then
    playErrorSoundAndExit("Unknown region name provided: " .. regionName)
  end
end

function ScreenSearcher:_isInDeadRegion(x, y)
  return self.screenToRegionMap[y] and self.screenToRegionMap[y][x] and self.screenToRegionMap[y][x]:name() == self.deadRegionName
end

function ScreenSearcher:_isNotDeadRegion(x, y)
  return not self:_isInDeadRegion(x, y)
end

function ScreenSearcher:_markLocationForRegion(x, y, regionName)
  self.screenToRegionMap[y] = self.screenToRegionMap[y] or {}
  if self:_isNotDeadRegion(x, y) or regionName == self.deadRegionName then
    local region = self.regions[regionName]
    local existingRegion = self.screenToRegionMap[y][x]
    if existingRegion then
      existingRegion:delete(x, y)
    end
    if not region then
      region = RegionProxy:new(x, y, regionName)
      self.regions[regionName] = region
    else
      region:add(x, y)
    end
    self.screenToRegionMap[y][x] = region
    return 1
  end
  return 0
end

function ScreenSearcher:_pixelsAreDifferent(oldPixel, newPixel)
  if self.comparisonMode == 'equality' then
    return oldPixel ~= newPixel
  elseif self.comparisonMode == 'compareColorEx' then
    return not compareColorEx(newPixel, oldPixel, self.rgbTolerance, self.hueTolerance)
  else
    playErrorSoundAndExit('Unknown comparison mode set in ScreenSearcher: ' .. self.comparisonMode)
  end
end

-------------------------------------------------------------------------------
-- Given a newly changed pixel at (x,y) this function will check to see if there is an existing
-- region immediately above it or to the left of it. If so it will extend that region to include this new (x,y)
-- co-ordinate. If (x,y) connects two currently separate regions it will join them into one big single region.
-- Will ignore any dead areas.
-------------------------------------------------------------------------------
function ScreenSearcher:_connectChangedPixelToSurroundingRegions(x, y)

  local aboveRegion = false
  local leftRegion = false
  if self:_isInDeadRegion(x, y) then
    return 0
  end

  if y - 1 >= 0 and self.screenToRegionMap[y - 1] then
    aboveRegion = self.screenToRegionMap[y - 1][x]
  end
  if x - 1 >= 0 and self.screenToRegionMap[y] then
    leftRegion = self.screenToRegionMap[y][x - 1]
  end

  if leftRegion and leftRegion:name() == self.deadRegionName then
    leftRegion = nil
  end
  if aboveRegion and aboveRegion:name() == self.deadRegionName then
    aboveRegion = nil
  end

  local existingRegion = self.screenToRegionMap[y][x]
  if existingRegion then
    existingRegion:delete(x, y)
  end
  local resultingRegion = nil
  if aboveRegion and leftRegion then
    local orgName = leftRegion:name()
    local connected = aboveRegion:connect(leftRegion, x, y)
    if connected then
      self.regions[orgName] = nil
    end
    resultingRegion = aboveRegion
  elseif aboveRegion then
    aboveRegion:add(x, y)
    resultingRegion = aboveRegion
  elseif leftRegion then
    leftRegion:add(x, y)
    resultingRegion = leftRegion
  else
    local newConnectedRegionName = 'connectedRegion_' .. self.nextFreeConnectedRegionId
    self.nextFreeConnectedRegionId = self.nextFreeConnectedRegionId + 1
    local newConnectedRegion = RegionProxy:new(x, y, newConnectedRegionName)
    resultingRegion = newConnectedRegion
    self.regions[newConnectedRegionName] = resultingRegion
  end
  self.screenToRegionMap[y][x] = resultingRegion
  return 1
end

-------------------------------------------------------------------------------
-- RegionProxy wraps a real Region object. We use a proxy so we can easily change the underlying Region object
-- without having to say, loop over all the screenToRegionMap locations where a region is currently set.
-------------------------------------------------------------------------------
RegionProxy = {}
function RegionProxy:new(x, y, name)
  local o = {}
  o.region = Region:new(x, y, name)
  return newObject(self, o)
end

function RegionProxy:add(x, y)
  self.region:add(x, y)
end

function RegionProxy:delete(x, y)
  self.region:delete(x, y)
end

function RegionProxy:connect(other_region, connecting_x, connecting_y)
  if other_region:name() ~= self:name() then
    self.region:connect(other_region.region, connecting_x, connecting_y)
    other_region.region = self.region
    return true
  else
    self.region:add(connecting_x, connecting_y)
    return false
  end
end

function RegionProxy:get_center(x, y)
  return self.region:get_center(x, y)
end

function RegionProxy:width()
  return self.region:width()
end

function RegionProxy:height()
  return self.region:height()
end

function RegionProxy:size()
  return self.region.size
end

function RegionProxy:name()
  return self.region.name
end

function RegionProxy:getBox(xOffset, yOffset, extraWidth, extraHeight)
  return self.region:getBox(xOffset, yOffset, extraWidth, extraHeight)
end

-------------------------------------------------------------------------------
-- A Region tracks size and the min and max co-ordinates of an area of changed pixels.
-------------------------------------------------------------------------------
Region = {}
function Region:new(x, y, name)
  local o = {}
  o.size = 1
  o.min_y = y
  o.max_y = y
  o.min_x = x
  o.max_x = x
  o.x_counts = { [x] = 1 }
  o.y_counts = { [y] = 1 }
  o.name = name
  return newObject(self, o)
end

function Region:add(x, y)
  self.size = self.size + 1
  if not self.x_counts[x] then
    self.x_counts[x] = 0
  end
  if not self.y_counts[y] then
    self.y_counts[y] = 0
  end
  self.x_counts[x] = self.x_counts[x] + 1
  self.y_counts[y] = self.y_counts[y] + 1
  self.min_x = math.min(self.min_x, x)
  self.min_y = math.min(self.min_y, y)
  self.max_x = math.max(self.max_x, x)
  self.max_y = math.max(self.max_y, y)
end

function Region:delete(x, y)
  self.size = self.size - 1
  self.x_counts[x] = self.x_counts[x] - 1
  self.y_counts[y] = self.y_counts[y] - 1
  if self.size == 0 then
    self.min_x = nil
    self.max_x = nil
    self.min_y = nil
    self.max_y = nil
  else
    -- Recalculate min maxes in-case the deleted pixel was a min or max one.
    if self.x_counts[x] == 0 then
      if self.min_x == x then
        for i = x + 1, self.max_x do
          if self.x_counts[i] then
            self.min_x = i
            break
          end
        end
      end
      if self.max_x == x then
        for i = self.max_x - 1, self.min_x, -1 do
          if self.x_counts[i] then
            self.max_x = i
            break
          end
        end
      end
    end
    if self.y_counts[y] == 0 then
      if self.min_y == y then
        for i = y + 1, self.max_y do
          if self.y_counts[i] then
            self.min_y = i
            break
          end
        end
      end
      if self.max_y == y then
        for i = self.max_y - 1, self.min_y, -1 do
          if self.y_counts[i] then
            self.max_y = i
            break
          end
        end
      end
    end
  end
end

function Region:connect(other_region, connecting_x, connecting_y)
  self.size = self.size + other_region.size + 1
  self.min_x = math.min(self.min_x, connecting_x, other_region.min_x)
  self.min_y = math.min(self.min_y, connecting_y, other_region.min_y)
  self.max_x = math.max(self.max_x, connecting_x, other_region.max_x)
  self.max_y = math.max(self.max_y, connecting_y, other_region.max_y)
  for x, count in pairs(other_region.x_counts) do
    if not self.x_counts[x] then
      self.x_counts[x] = 0
    end
    self.x_counts[x] = self.x_counts[x] + count
  end
  for y, count in pairs(other_region.y_counts) do
    if not self.y_counts[y] then
      self.y_counts[y] = 0
    end
    self.y_counts[y] = self.y_counts[y] + count
  end
end

function Region:get_center(x_offset, y_offset)
  local center_x = math.floor((self.max_x + self.min_x) / 2) + x_offset
  local center_y = math.floor((self.max_y + self.min_y) / 2) + y_offset
  return { ['x'] = center_x, ['y'] = center_y }
end

function Region:width()
  return self.max_x - self.min_x + 1
end

function Region:height()
  return self.max_x - self.min_x + 1
end

function Region:getBox(xOffset, yOffset, extraWidth, extraHeight)
  if not xOffset then
    xOffset = 0
  end
  if not yOffset then
    yOffset = 0
  end
  if not extraWidth then
    extraWidth = 0
  end
  if not extraHeight then
    extraHeight = 0
  end
  if self.size == 0 or self.min_x == nil or self.min_y == nil then
    return nil
  end
  return makeBox(
    self.min_x + xOffset - extraWidth,
    self.min_y + yOffset - extraHeight,
    self:width() + extraWidth * 2, self:height() + extraHeight * 2)
end

function isInRegion(y, x, screenToRegionMap, regionName)
  return screenToRegionMap[y] and screenToRegionMap[y][x] and regionName == screenToRegionMap[y][x]:name()
end

-------------------------------------------------------------------------------
-- Calculates in two passes the distance for each pixel in the regionName region to the edge of that region.
-- Returns a result object with max_x, max_y and max_dt where the x and y are the co-ordinates local to the box
-- which are furthest from the edge in the region. max_dt is the distance for this pixel to the edge.
-- See https://stackoverflow.com/questions/53678520/speed-up-computation-for-distance-transform-on-image-in-python
-- for the implementation this copies.
-------------------------------------------------------------------------------
function chamfer_distance(box, screenToRegionMap, regionName)

  function fr(r)
    if r == nil then
      return 0
    else
      return r
    end
  end

  local w = box.width
  local h = box.height
  local dt = { [0] = {} }

  local top = box.top
  local left = box.left

  if isInRegion(top, left, screenToRegionMap, regionName) then
    dt[0][0] = 65535
  end
  for x = 1, w - 1 do
    local y = 0
    if isInRegion(y + top, x + left, screenToRegionMap, regionName) then
      dt[y][x] = 3 + fr(dt[y][x - 1])
    end
  end
  for y = 1, h - 1 do
    dt[y] = dt[y] or {}
    if isInRegion(y + top, left, screenToRegionMap, regionName) then
      dt[y][0] = math.min(3 + fr(dt[y - 1][0]), 4 + fr(dt[y - 1][1]))
    end
    for x = 1, w - 2 do
      if isInRegion(y + top, left + x, screenToRegionMap, regionName) then
        dt[y][x] = math.min(4 + fr(dt[y - 1][x - 1]), 3 + fr(dt[y - 1][x]), 4 + fr(dt[y - 1][x + 1]), 3 + fr(dt[y][x - 1]))
      end
    end
    local x = w - 1
    if isInRegion(y + top, x + left, screenToRegionMap, regionName) then
      dt[y][x] = math.min(4 + fr(dt[y - 1][x - 1]), 3 + fr(dt[y - 1][x]), 3 + fr(dt[y][x - 1]))
    end
  end

  -- Backwards pass
  local max_x = 0
  local max_y = 0
  local max_dt = -1
  for x = w - 2, 0, -1 do
    local y = h - 1
    if isInRegion(top + y, x + left, screenToRegionMap, regionName) then
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
    if isInRegion(top + y, left + x, screenToRegionMap, regionName) then
      dt[y][x] = math.min(fr(dt[y][x]), 3 + fr(dt[y + 1][x]), 3 + fr(dt[y + 1][x - 1]))
      if dt[y][x] > max_dt then
        max_x = x
        max_y = y
        max_dt = dt[y][x]
      end
    end
    for x2 = 1, w - 2 do
      if isInRegion(top + y, left + x2, screenToRegionMap, regionName) then
        dt[y][x2] = math.min(fr(dt[y][x2]), 4 + fr(dt[y + 1][x2 + 1]), 3 + fr(dt[y + 1][x2]), 4 + fr(dt[y + 1][x2 - 1]), 3 + fr(dt[y][x2 + 1]))
        if dt[y][x2] > max_dt then
          max_x = x2
          max_y = y
          max_dt = dt[y][x2]
        end
      end
    end
    x = 0
    if isInRegion(top + y, left + x, screenToRegionMap, regionName) then
      dt[y][x] = math.min(fr(dt[y][x]), 4 + fr(dt[y + 1][x + 1]), 3 + fr(dt[y + 1][x]), 3 + fr(dt[y][x + 1]))

      if dt[y][x] > max_dt then
        max_x = x
        max_y = y
        max_dt = dt[y][x]
      end
    end
  end
  --lsDoFrame()
  --local startTime  = lsGetTimer()
  --local displayTime = 10000
  --while lsGetTimer() - startTime < displayTime do
  --  lsPrint(10, 0, 10, 1, 1, 0xFFFFFFff, title or "Displaying distance map for region " .. regionName);
  --  for y = 0, box.height, 1 do
  --    for x = 0, box.width do
  --      local colour = BLACK
  --      if dt[y] and dt[y][x] then
  --        local d = dt[y][x]
  --        if d <= 0 then
  --          colour = RED
  --        elseif d <= 5 then
  --          colour = LIGHT_BLUE
  --        elseif d <= 10 then
  --          colour = BLUE
  --        else
  --          colour = GREEN
  --        end
  --        if d == max_dt then
  --          colour = YELLOW
  --        end
  --      elseif isInRegion(top + y, left + x, screenToRegionMap, regionName) then
  --        colour = PURPLE
  --      end
  --      lsDisplaySystemSprite(1, x, y, 1, 1, 1, colour)
  --    end
  --  end
  --  lsDoFrame()
  --  lsSleep(tick_delay)
  --  checkBreak()
  --end
  local result = {}
  result.dt = dt
  result.max_x = max_x
  result.max_y = max_y
  result.max_dt = max_dt
  return result
end

function drawWrappedText(text, colour, x, y)
  current_y = current_y + lsPrintWrapped(x, y, 10, lsGetWindowSize()[0] - 10, 0.6, 0.6, colour, text)
end
