-- Vegetable Macro for Tale 7 by thejanitor.
--
-- Thanks to veggies.lua for the build button locations
-- Updated 29-SEP-2017 by Silden to take into account UI changes that meant the windows would not close properly
-- Updated 30-SEP-2017 by Silden to increase default values to cater for long veg names, such as Cabbage

dofile("common.inc")
dofile("settings.inc")
dofile("screen_searcher.inc")
dofile("veg_janitor/plant.inc")
dofile("veg_janitor/plant_controller.inc")
dofile("veg_janitor/util.inc")
dofile("veg_janitor/ui.inc")
dofile("veg_janitor/list.inc")
dofile("veg_janitor/vector.inc")
dofile("veg_janitor/screen.inc")
dofile("veg_janitor/calibration.inc")
dofile("veg_janitor/logger.inc")

WARNING = [[
1. In Options -> Interface Options
    1. You Must SET: UI Size to %125
    2. You Must ENABLE: "Use the chat area instead of popups for many messages"
    3. You Must ENABLE: "Position Menus to right of mouse"
    4. You Must ENABLE: "Right-Click Pins/Unpins a Menu"
2. In Options -> One-Click and Related
    1. You must DISABLE: "Plant all crops where you stand"
    2. You must ENABLE: "Auto take piles of upto 50 portable items"
3. In Options -> Video
    1. You must set: "Shadow Quality" and "Time of Day" lighting to the lowest possible settings
    2. Ideally run Veg Janitor in windowed mode with the window resized to be about 1280x1000 in size.
4. Press F8 F8 F8 to set the camera in top down mode
5. Press ALT-L to lock the camera so it doesn't move accidentally
6. Do not move once the macro is running and you must be standing on a tile with water available to refill
7. Do not stand directly on or nearby animated water as this can break the plant detection
8. Click the seed you wish to plant and ensure the seed window with the "Plant" button is pinned and visible
9. Make sure on the previous screen you have selected the same seed name as the open seed window.
10. Open the Main chat tab to automatically stop the macro when the ground is not suitable.
11. Do not use the mouse whilst the macro is running.
12. DO NOT STAND NEAR WATER OR ANY OTHER ANIMATED OBJECTS. IF WATER IS WITHIN HALF A SCREEN SIZE DISTANCE FROM YOUR
    CHARACTER BAD THINGS WILL HAPPEN.
]]

RED = 0xFF2020ff
BLACK = 0x000000ff
WHITE = 0xFFFFFFff


-- Used to control the plant window placement and tiling.
WINDOW_HEIGHT = 120 -- Was 80
WINDOW_WIDTH = 280 -- Was 220
WINDOW_OFFSET_X = 150
WINDOW_OFFSET_Y = 150

function doit()
  lsRequireVersion(2, 54);
  while true do
    local config = getUserParams()
    reset_log()
    veg_log(NONE, NONE, 'veg_janitor', 'Starting run in log level ' .. LOG_LEVEL_TO_NAME[config.debug_log_level])
    askForWindowAndSetupGlobals(config)
    gatherVeggies(config)
  end
end

function askForWindowAndSetupGlobals(config)
  if config.calibration_mode then
    config.num_runs = config.num_calibration_runs or 10
    config.num_plants = 1
    config.pre_look = true
    config.search_for_seed_bags = true
    config.record_plant_animation = false
  else
    local plant_config = config.plants[config.seed_type][config.seed_name]
    if plant_config and plant_config.stage_advance_timings and plant_config.stage_advance_timings.calibrated then
      local calibration_version = plant_config.stage_advance_timings.calibration_version
      if not calibration_version or calibration_version < 1 then
        print('Forcing re-calculation of calibration data due to version update!')
        calculate_and_update_calibration_settings(config, config.seed_type, config.seed_name)
      end
    end
  end

  local isis_bounty = config.plants['Cucumbers']["Isis' Bounty"]
  if not isis_bounty then
    config.plants['Cucumbers']["Isis' Bounty"] = {
      ["stages"] = 4,
      ["stage_advance_timings"] = {
        [1] = 16000,
        [2] = 13000,
        [3] = 13000,
        [4] = 13000,
      }
    ,
      ["waters"] = 3,
      ["type"] = "Cucumbers",
      ["yield"] = 4,
    }
    write_config(config)
  else
    if not isis_bounty["stage_advance_timings"] or #isis_bounty["stage_advance_timings"] ~= 4 then
      isis_bounty["stage_advance_timings"] = {
        [1] = 16000,
        [2] = 13000,
        [3] = 13000,
        [4] = 13000,
      }
      write_config(config)
    end
  end

  local min_jugs = config.num_waterings * config.num_plants * config.num_stages
  local min_seeds = config.num_plants
  local one = 'You will need ' .. min_jugs .. ' jugs of water and ' .. min_seeds .. ' seeds \n'
  local two = '\n Press Shift over ATITD window to continue.'
  askForWindow(one .. two)
  setupGlobals(config)
end

DIRECTION_NAMES = {
  'NORTH',
  'SOUTH',
  'WEST',
  'EAST',
  'NORTH_WEST',
  'NORTH_EAST',
  'SOUTH_WEST',
  'SOUTH_EAST'
}

function setupGlobals(config)
  NORTH = Vector:new { 0, -1 }
  SOUTH = Vector:new { 0, 1 }
  WEST = Vector:new { -1, 0 }
  EAST = Vector:new { 1, 0 }
  NORTH_WEST = NORTH + WEST
  NORTH_EAST = NORTH + EAST
  SOUTH_WEST = SOUTH + WEST
  SOUTH_EAST = SOUTH + EAST
  DOUBLE_SOUTH = SOUTH * 2
  DOUBLE_NORTH = NORTH * 2
  DOUBLE_WEST = WEST * 2
  DOUBLE_EAST = EAST * 2

  MOVE_BTNS = {
    [NORTH] = Vector:new { 48, 30 },
    [SOUTH] = Vector:new { 48, 71 },
    [NORTH_EAST] = Vector:new { 70, 30 },
    [WEST] = Vector:new { 30, 50 },
    [EAST] = Vector:new { 70, 50 },
    [NORTH_WEST] = Vector:new { 30, 30 },
    [SOUTH_EAST] = Vector:new { 70, 67 },
    [SOUTH_WEST] = Vector:new { 30, 67 }
  }
  PLANT_LOCATIONS = { next = 1 }
  DIRECTIONS = {
    ['NORTH'] = NORTH,
    ['SOUTH'] = SOUTH,
    ['WEST'] = EAST,
    ['EAST'] = WEST,
    ['NORTH_WEST'] = NORTH_WEST,
    ['NORTH_EAST'] = NORTH_EAST,
    ['SOUTH_WEST'] = SOUTH_WEST,
    ['SOUTH_EAST'] = SOUTH_EAST
  }

  -- TODO FIGURE OUT WHAT THE HORRIBLE HACK WAS
  -- TODO FIX HORRIBLE GLOBAL HACK
  seed_type = config.seed_type
  local order = config.default_plant_location_order
  local seed_order = config.plants[config.seed_type] and config.plants[config.seed_type][config.seed_name] and config.plants[config.seed_type][config.seed_name].plant_location_order
  if seed_order and #seed_order > 0 then
    order = seed_order
  end
  if #order < config.num_plants then
    error('Your plant location and order config setting does not have enough entries to run ' .. config.num_plants .. ' plants, please add more.')
  end
  for i, direction in ipairs(order) do
    PlantLocation:new { direction_vector = DIRECTIONS[direction.direction], num_move_steps = (direction.number_of_moves or 1), direction = direction.direction }
  end

  makeReadOnly(PLANT_LOCATIONS)

  local mid = getScreenMiddle()
  ANIMATION_BOX = makeBox(mid.x - 60, mid.y - 50, 105, 85)
  PLAYER_BOX = makeBox(mid.x - 40, mid.y - 7, 80, 55)
  ARM_BOX = makeBox(mid.x - 90, mid.y - 20, 80, 25)
end

PlantLocation = {}
function PlantLocation:new(o)
  o.move_btn = MOVE_BTNS[o.direction_vector]
  if o.num_move_steps then
    o.direction_vector = o.direction_vector * o.num_move_steps
  else
    o.num_move_steps = 1
  end
  PLANT_LOCATIONS[o.direction_vector] = o
  PLANT_LOCATIONS[PLANT_LOCATIONS.next] = o
  PLANT_LOCATIONS.next = PLANT_LOCATIONS.next + 1
  o.box = makeSearchBox(o.direction_vector, seed_type)
  return newObject(PlantLocation, o, true)
end

function PlantLocation:move()
  -- TODO Only search in the top left region of the screen to improve performance
  local build_arrows = findImage("veg_janitor/build_arrows.png", nil, 7000)
  if not build_arrows then
    srReadScreen()
    local attempts = 0
    while attempts < 5 and not build_arrows do
      attempts = attempts + 1
      if findImage("veg_janitor/patching.png") then
        while findImage("veg_janitor/patching.png") do
          current_y = 10
          srReadScreen()
          checkBreak()
          drawWrappedTextUsingCurrent("Waiting for patching icon to disappear...", WHITE)
          lsDoFrame()
          lsSleep(tick_delay)
        end
      end
      build_arrows = findImage("veg_janitor/build_arrows.png", nil, 7000)
    end
    if not build_arrows then
      playErrorSoundAndExit("Failed to find the build arrows")
    end
  end
  for step = 1, self.num_move_steps do
    click(self.move_btn + Vector:new { build_arrows[0], build_arrows[1] }, false, false)
  end
end

function PlantLocation:show(title)
  displayBox(self.box, false, 3000, title)
end

function displayBox(box, forever, time, title)
  local start = lsGetTimer()
  moveMouse(Vector:new { box.left, box.top })
  while forever or (time and (lsGetTimer() - start) < time) do
    current_y = 10
    srReadScreen()
    srMakeImage("box", box.left, box.top, box.width, box.height)
    if title then
      drawTextUsingCurrent(title, WHITE)
    end
    srShowImageDebug("box", 0, current_y, 0, 1)
    checkBreak()
    if forever or time then
      lsDoFrame()
      lsSleep(10)
    else
      current_y = current_y + box.height
    end
  end
end

function displayBoxes(boxes, forever)
  while forever do
    current_y = 10
    for i, v in ipairs(boxes) do
      srShowImageDebug(v, 0, (i - 1) * 200, 0, 1)
    end
    checkBreak()
    lsDoFrame()
    lsSleep(10)
  end
end

function saveBox(box, name)
  srReadScreen()
  srMakeImage(name, box.left, box.top, box.width, box.height)
end

function repositionAvatar()
  local mid = getScreenMiddle()
  statusScreen("Repositioning Avatar to face N/S ...");
  safeClick(mid.x - 10, mid.y - 100);
  lsSleep(500);
  safeClick(mid.x - 10, mid.y + 170);
  lsSleep(500);
end

SPEED_MODE = false

function checkBreakIfNotSpeed()
  if not SPEED_MODE then
    checkBreak()
  end
end

function debugSearchBoxes(config, plants)
  for i = 1, config.num_plants do
    srReadScreen()
    local buildButton = clickPlantButton(config.seed_name)
    srReadScreen()

    current_y = 10
    plants[i].location:move()
    plants[i].location:show('Showing the search box for plant ' .. i)
    safeClick(buildButton[0] + 70, buildButton[1])
  end
end

function preLocatePlants(config, plants, seedScreenSearcher, dead_player_box)
  veg_log(DEBUG, config.debug_log_level, 'preLocatePlants', 'Prelocating plants...')
  local box = makeLargeSearchBoxAroundPlayer((srGetWindowSize()[0] / 4))
  local plantSearcher = ScreenSearcher:new(box, 'compareColorEx', config.debug_log_level)
  plantSearcher:snapshotScreen('before')
  plantSearcher:markBoxAsDead(dead_player_box)
  veg_log(DEBUG, config.debug_log_level, 'preLocatePlants', 'Snapshotted screen and marked player area as dead...')
  if config.debug_log_level >= DEBUG then
    plantSearcher:drawRegions(2000, nil, 'Showing excluded player box')
  end
  for i = config.num_plants, 1, -1 do
    veg_log(DEBUG, config.debug_log_level, 'preLocatePlants', 'Pre-locating plant ' .. i)
    srReadScreen()
    local buildButton = clickPlantButton(config.seed_name)
    srReadScreen()

    plants[i].location:move()
    lsSleep(500)
    veg_log(DEBUG, config.debug_log_level, 'preLocatePlants', 'Marking screen changes as plant ' .. i)
    local numChanged = plantSearcher:markAllChangesAsRegion('before', i)
    veg_log(DEBUG, config.debug_log_level, 'preLocatePlants', 'For plant ' .. i .. ' found it has ' .. numChanged .. ' pixels!')
    veg_log(DEBUG, config.debug_log_level, 'preLocatePlants', 'Setting search box for plant ' .. i)
    plants[i]:set_search_box(plantSearcher:getRegionBox(i, 0.02))

    safeClick(buildButton[0] + 70, buildButton[1])
    veg_log(DEBUG, config.debug_log_level, 'preLocatePlants', 'Done pre-locating plant ' .. i)
  end

  if config.debug_log_level >= DEBUG then
    debugSearchBoxes(config, plants)
  end

  local numSnapsRequired = config.num_plant_snaps or 10
  local numSnapsSoFar = 0

  if config.record_plant_animation then
    veg_log(DEBUG, config.debug_log_level, 'preLocatePlants', 'Recording plant animations.')
    while numSnapsRequired > numSnapsSoFar do
      for i = 1, config.num_plants do
        srReadScreen()
        local buildButton = clickPlantButton(config.seed_name)
        srReadScreen()
        plants[i].location:move()
        lsSleep(200)
        safeClick(buildButton[0], buildButton[1])
      end
      veg_log(DEBUG, config.debug_log_level, 'preLocatePlants', 'Snapshotting now that all plants are on the screen so we only detect moving plant pixels.')
      plantSearcher:snapshotScreen('before')
      local first_stage_time = config.plants[config.seed_type][config.seed_name].stage_advance_timings[1]
      local snapsTaken = recordPlantMovement(plantSearcher, first_stage_time * 0.5, config)
      numSnapsSoFar = numSnapsSoFar + snapsTaken
      lsDoFrame()
      lsPrintWrapped(10, 50, 0, lsScreenX - 20, 1, 1, 0xd0d0d0ff,
        'Waiting for plants to die, ' .. numSnapsRequired - numSnapsSoFar .. ' snapshots left.');
      lsDoFrame()
      lsSleep(first_stage_time * 0.5)
      findSeedAndPickupIfThere(seedScreenSearcher, config.num_plants, config)
    end
  end

  for i = 1, config.num_plants do
    local point = plantSearcher:findFurthestPointFromEdgeForRegion(i)
    veg_log(DEBUG, config.debug_log_level, 'preLocatePlants', 'Saving click location for plant ' .. i .. ' as '.. point.x .. ' , ' .. point.y)
    plants[i].saved_plant_location = point
  end

  if config.debug_log_level >= DEBUG then
    plantSearcher:drawRegions(10000, nil, 'Plant regions:')
  end
end

function displayDebugImages(config, plants, box)
  if config.debug_log_level >= DEBUG then
    for i = 1, config.num_plants do
      for y = box.top, box.top + box.height, 1 do
        for x = box.left, box.left + box.width do
          local sbox = plants[i].search_box.box
          local area = plants[i].search_box.area
          local colour = BLACK
          local inside_player = inside(Vector:new { x, y }, sbox)
          if inside_player then
            colour = WHITE
          end
          if inside_player and area[y - sbox.top] and area[y - sbox.top][x - sbox.left] then
            colour = RED
          end
          lsDisplaySystemSprite(1, x - box.left, y - box.top, 1, 1, 1, colour)
        end
      end
      lsDoFrame()
      lsSleep(500)
    end
    local colours = { GREEN, RED, BLUE, YELLOW, PINK, BROWN, PURPLE, LIGHT_BLUE, GREEN, RED, BLUE, YELLOW }
    for y = box.top, box.top + box.height, 1 do
      for x = box.left, box.left + box.width do
        local found = false
        local colour = BLACK
        for i = 1, config.num_plants do
          local sbox = plants[i].search_box.box
          local area = plants[i].search_box.area
          local inside_player = inside(Vector:new { x, y }, sbox)
          if colour == BLACK and inside_player then
            colour = WHITE
          end
          if inside_player and area[y - sbox.top] and area[y - sbox.top][x - sbox.left] then
            colour = colours[i]
            if found then
              error("Already found at " .. x .. " ," .. y)
            end
            found = true
          end
        end
        lsDisplaySystemSprite(1, x - box.left, y - box.top, 1, 1, 1, colour)
      end
    end
    lsDoFrame()
    lsSleep(500)
  end

end

function recordPlantMovement(plantSearcher, watchTime, config)
  local elapsedTime = 0
  local start = lsGetTimer()
  local numSnaps = 0
  lsDoFrame()

  while elapsedTime < watchTime do
    current_y = 10
    veg_log(DEBUG, config.debug_log_level, 'preLocatePlants', 'SNAPSHOT Number ' .. numSnaps)
    plantSearcher:markChangesAsDeadZone('before')
    elapsedTime = lsGetTimer() - start
    current_y = current_y + lsPrintWrapped(10, current_y, 0, lsScreenX - 20, 1, 1, 0xd0d0d0ff,
      [[Recording the plants movement to reduce click errors, please do not interfere the macro wants this first set of plants to die and will pickup itself...]]);
    lsPrintWrapped(10, current_y, 0, lsScreenX - 20, 1, 1, 0xd0d0d0ff,
      (watchTime - elapsedTime) .. ' ms left, ' .. numSnaps .. ' snapshots taken... ');
    lsDoFrame()
    checkBreak(true)
    numSnaps = numSnaps + 1
  end
  return numSnaps
end
function recordMovement(searcher, config)
  lsDoFrame()

  local num_snaps = config.num_char_snaps or 10
  for i = 1, num_snaps do
    searcher:markChangesAsDeadZone('beforeSeeds')
    lsPrintWrapped(10, 50, 0, lsScreenX - 20, 1, 1, 0xd0d0d0ff,
      [[Recording your characters movement to reduce click errors...]]);
    lsPrintWrapped(10, 100, 0, lsScreenX - 20, 1, 1, 0xd0d0d0ff,
      (num_snaps - i) .. ' snapshots left');
    lsDoFrame()
  end
  if config.debug_log_level >= DEBUG then
    searcher:drawRegions(3000, false, 'Seed searcher dead zones for player:')
  end
  return searcher:getRegionBox(searcher.deadRegionName, nil, 2.5)
end

function findSeedAndPickupIfThere(searcher, num_dead, config)
  lsPrintWrapped(10, 100, 0, lsScreenX - 20, 1, 1, 0xd0d0d0ff, 'Searching for ' .. num_dead .. ' seed bags left over on the floor from failed plants.');
  lsDoFrame()
  srReadScreen()
  local existing_unpin_locs = findAllImages("veg_janitor/pin.png", 4800)
  local start_seed_box_found = srFindImage("veg_janitor/seeds.png",
    4800);
  if start_seed_box_found then
    error([[There was already a seed bag menu opened which would clash with the seed picking up method.
    Please close any existing seed bag menus (the ones opened when you right click on a seed bag on the floor) before running veg janitor.]])

  end
  local width = srGetWindowSize()[0];
  local expected_seed_bag_height = width * 0.0195
  local expected_seed_bag_width = width * 0.01
  local expected_seed_bag_pixel_size = expected_seed_bag_height * expected_seed_bag_width
  local fudge_factor = 0.1
  local pixel_change = math.floor(expected_seed_bag_pixel_size * fudge_factor)
  veg_log(DEBUG, config.debug_log_level, 'findSeedAndPickupIfThere', 'Looking for ' .. num_dead .. ' seeds which must have a region pixel size greater than ' .. pixel_change)
  searcher:markConnectedAreasAsNewRegions('beforeSeeds', nil, true)
  local regions = searcher:getRegions(pixel_change, num_dead + 3)
  veg_log(DEBUG, config.debug_log_level, 'findSeedAndPickupIfThere', 'Found ' .. #regions .. ' changed regions.')
  if config.debug_log_level >= DEBUG then
    searcher:drawRegions(6000, pixel_change, 'Potential Seed Bag Locations:')
  end
  local seeds_picked_up = 0
  for i, region in ipairs(regions) do
    veg_log(DEBUG, config.debug_log_level, 'findSeedAndPickupIfThere', 'Looking for seed ' .. i .. '.')
    local clickLoc = searcher:findFurthestPointFromEdgeForRegion(region:name())
    lsSleep(click_delay)
    srClickMouse(clickLoc.x, clickLoc.y, 1)
    lsSleep(click_delay)
    srReadScreen()
    local seed_box_found = srFindImage("veg_janitor/seeds.png",
      4800);
    if seed_box_found then
      veg_log(DEBUG, config.debug_log_level, 'findSeedAndPickupIfThere', 'Found seed!')
      seeds_picked_up = seeds_picked_up + 1
      lsSleep(click_delay)
      srClickMouse(clickLoc.x - 1, clickLoc.y - 1, 0)
      lsSleep(click_delay)
      srClickMouse(clickLoc.x - 1, clickLoc.y - 1, 0)
      sleepWithStatus(3500, "Waiting for pickup animation...", nil, 0.7, "Please standby");
    else
      veg_log(DEBUG, config.debug_log_level, 'findSeedAndPickupIfThere', 'Failed to find seed closing window!')
      lsSleep(click_delay)
      srClickMouse(clickLoc.x - 1, clickLoc.y - 1, 0)
    end
  end
  if seeds_picked_up < num_dead then
    veg_log(INFO, config.debug_log_level, 'findSeedAndPickupIfThere', 'Failed to pickup all seeds, ' .. num_dead - seeds_picked_up .. ' left to pickup...')
    lsPlaySound("fail.wav");
    local exit = false
    while not lsShiftHeld() and not exit do
      lsPrintWrapped(0, 0, 1, lsScreenX, 0.7, 0.7, 0xFFFFFFff, 'Failed to pickup a seedbag, please without moving your character at all pick up all seeds and then press and hold shift to continue.');
      lsDoFrame();
      lsSleep(tick_delay);
      checkBreak();
    end
    sleepWithStatus(3000, "WARNING VEG JANITOR IS ABOUT TO START DO NOT USE MOUSE OR KEYBOARD")
  end
end

function movementExpectedBecauseOfHarvestingDistance(config)
  for i = 1, config.num_plants do
    local num_steps = PLANT_LOCATIONS[i].num_move_steps
    local dir = PLANT_LOCATIONS[i].direction
    if dir == 'NORTH_WEST' or dir == 'SOUTH_WEST' or dir == 'NORTH_EAST' or dir == 'SOUTH_EAST' then
      if num_steps > 1 then
        return true
      end
    else
      if num_steps > 2 then
        return true
      end
    end
  end
  return false
end

function gatherVeggies(config)
  safeBegin()
  srReadScreen()
  closeEmptyAndErrorWindows()
  local drawResult = drawWater()
  if config.check_for_water_button then
    srReadScreen()
    local r = srFindImage('veg_janitor/no_water.png')
    if not r and not drawResult then
      playErrorSoundAndExit('Cant see water button please make sure it is visible for rewaters')
    end
  end
  local plants = Plants:new { num_plants = config.num_plants, seed_type = config.seed_type,
                              seed_name = config.seed_name,
                              alternate_drag = config.alternate_drag, config = config }
  local seed_searcher = nil

  local movementExpected = movementExpectedBecauseOfHarvestingDistance(config)
  if movementExpected and config.search_for_seed_bags then
    error('Your plant order settings will result in your character moving when harvesting. This will break the seed bag pickup, please either change your plant order settings or disable seed bag pickup.')
  end

  local stop_after_this_run = false
  local pause_after_this_run = false
  local run_number = 0
  while run_number <= config.num_runs do
    run_number = run_number + 1
    local firstRun = run_number == 1
    srReadScreen();
    checkPlantButton()
    if config.reposition_avatar then
      if firstRun or movementExpected then
        repositionAvatar()
      end
    end
    local dead_player_box = false
    if config.search_for_seed_bags or config.pre_look then
      if firstRun or movementExpected then
        local xyScreenSize = srGetWindowSize();
        seed_searcher = ScreenSearcher:new(makeLargeSearchBoxAroundPlayer((xyScreenSize[0] / 4)), 'compareColorEx', config.debug_log_level)
        seed_searcher:snapshotScreen('beforeSeeds')
        dead_player_box = recordMovement(seed_searcher, config)
      else
        -- Resnapshot the empty floor at the start of runs. Otherwise the seed finder will think all pixels have
        -- changed as the lighting changes slowly over the time if we just use an initial snapshot from the very first
        -- run.
        seed_searcher:snapshotScreen('beforeSeeds')
      end
    end
    if config.pre_look then
      if firstRun or movementExpected then
        preLocatePlants(config, plants, seed_searcher, dead_player_box)
      end
    end
    local batch_size = config.planting_batch_size[config.seed_type] or config.planting_batch_size["Default"]
    local sortable_plant_list = {}
    for i = 1, math.min(batch_size, config.num_plants) do
      table.insert(sortable_plant_list, plants[i])
    end
    lsPrintln("Config run " .. run_number)
    local start = lsGetTimer()

    checkBreakIfNotSpeed()
    local num_finished = 0
    local plant_finished = {}
    local num_watering = 0
    local num_dead = 0
    local found = {}
    local j = 1
    while num_finished < #sortable_plant_list do
      checkBreakIfNotSpeed()
      local plant = sortable_plant_list[j]
      if plant:finished() and not plant_finished[plant.index] then
        if plant:died() then
          num_dead = num_dead + 1
        end
        num_finished = num_finished + 1
        plant_finished[plant.index] = true
      end
      if not found[plant.index] and (plant.window_open and not plant_finished[plant.index]) then
        num_watering = num_watering + 1
        found[plant.index] = true
      end
      local num_planted = #sortable_plant_list
      if num_watering == num_planted then
        for i = num_planted + 1, math.min(num_planted + batch_size, config.num_plants) do
          table.insert(sortable_plant_list, plants[i])
        end
      end

      plant:tick(config)
      if config.sorting_mode then
        sort_plants(sortable_plant_list)
      else
        j = j + 1
        if j > #sortable_plant_list then
          j = 1
        end
      end
      local result = display_plants(plants, config, run_number, stop_after_this_run, pause_after_this_run)
      stop_after_this_run = result.stop_after_this_run
      pause_after_this_run = result.pause_after_this_run

      checkBreakIfNotSpeed()
    end

    lsSleep(click_delay)
    drawWater()
    lsSleep(click_delay * 5)
    checkBreak()

    closeEmptyAndErrorWindows()

    if config.search_for_seed_bags and num_dead > 0 then
      findSeedAndPickupIfThere(seed_searcher, num_dead, config)
    end

    local stop = lsGetTimer() + config.end_of_run_wait
    local yield = config.plant_yield_bonus + config.plants[config.seed_type][config.seed_name].yield
    local total = math.floor((3600 / ((stop - start) / 1000)) * config.num_plants * yield) -- default 3, currently 9 veggie yield with pyramids bonus
    for k = 1, config.num_plants do
      if config.calibration_mode then
        if plants[k].bad_calibration then
          print('IGNORING DATA DUE TO BAD CALIBRATION')
          config.num_runs = config.num_runs + 1
        else
          plants[k]:output_calibration_data()
        end
      end
      plants[k]:partiallyResetState()
    end
    if stop_after_this_run then
      break
    end
    if pause_after_this_run then
      local continue = false
      while not (lsShiftHeld() and lsAltHeld()) and not continue do
        current_y = 10
        drawTextUsingCurrent("Veg Janitor is paused. Press and hold Shift and Alt at once to unpause and continue", WHITE)
        drawTextUsingCurrent("DO NOT MOVE DURING THIS PAUSE, IF YOU DO AFTER UNPAUSING IT WILL BREAK, JUST EXIT THE SCRIPT AND RESTART IF YOU MOVE.", RED)
        if drawBottomButton(10, "Continue", GREEN) then
          continue = true
        end
        if drawBottomButton(110, "Exit Script", RED) then
          error "Script exited by user"
        end
        lsSleep(tick_delay)
        checkBreak();
        lsDoFrame()
      end
      sleepWithStatus(3000, "WARNING VEG JANITOR IS ABOUT TO START DO NOT USE MOUSE OR KEYBOARD")
      pause_after_this_run = false
    else
      sleepWithStatus(config.end_of_run_wait, "Running at " .. total .. " veg per hour. ")
    end
    srReadScreen()
    local not_suitables = findAllImages('veg_janitor/not_suitable.png')
    if #not_suitables > 0 then
      lsPlaySound("error.wav");
      error('Your location is no longer suitable for growing vegetables, please move!')
    end
  end
  if config.calibration_mode then
    calculate_and_update_calibration_settings(config, config.seed_type, config.seed_name)
  end
end

function sort_plants(plants)
  table.sort(plants, function(first, second)
    --local comp = first:time_till_death() - second:time_till_death()
    --if comp > 0 then
    --    return false
    --elseif comp < 0 then
    --    return true
    --else
    --    return first.last_ticked_time < second.last_ticked_time
    --end
    --        return first.last_ticked_time < second.last_ticked_time
    if first:time_till_death() < 16000 or second:time_till_death() < 16000 then
      local comp = first:time_till_death() - second:time_till_death()
      if comp > 0 then
        return false
      elseif comp < 0 then
        return true
      else
        return first.last_ticked_time < second.last_ticked_time
      end
    else
      return first.last_ticked_time < second.last_ticked_time
    end
  end)
end

function display_plants(plants, config, run_number, stop_end_of_run, pause_after_this_run)
  current_y = 10
  local num_left = config.num_runs - run_number + 1
  if stop_end_of_run then
    num_left = 0
  end
  if config.calibration_mode then
    drawTextUsingCurrent("CALIBRATION MODE RUNNING, " .. num_left .. " runs remaining...", GREEN)
  else
    drawTextUsingCurrent("VEG JANITOR RUNNING, " .. num_left .. " runs remaining...", GREEN)
  end
  if stop_end_of_run then
    drawTextUsingCurrent('STOPPING AFTER THIS RUN', RED)
  elseif pause_after_this_run then
    drawTextUsingCurrent('PAUSING AFTER THIS RUN', YELLOW)
  else
    drawTextUsingCurrent('Press and hold Shift-Alt to pause veg janitor after this run finishes.', YELLOW)
    drawTextUsingCurrent('Press and hold Ctrl-Alt to stop veg janitor after this run finishes.', RED)
  end
  drawTextUsingCurrent('Press Ctrl-Shift to exit immediately.', WHITE)
  if not stop_end_of_run and not pause_after_this_run then
    if lsControlHeld() and lsAltHeld() then
      stop_end_of_run = true
    end
    if lsShiftHeld() and lsAltHeld() then
      pause_after_this_run = true
    end
  end
  for index, plant in ipairs(plants) do
    local status = plant:status()
    if type(status) == "string" then
      drawTextUsingCurrent('Plant ' .. plant.index .. " is " .. plant:status())
      current_y = current_y + 5
    else
      drawTextUsingCurrent('Plant ' .. plant.index .. " in stage " .. status.stage .. " , next stage in: " .. math.floor(status.next_in / 1000) .. "s")
      local colours = { PINK, PURPLE, BLUE, LIGHT_BLUE }
      local x_so_far = 5
      for i, time in ipairs(status.times) do
        local width
        local colour = colours[i]
        if i == status.stage then
          width = status.next / 250
          colour = RED
        else
          width = time / 250
        end
        lsDisplaySystemSprite(1, x_so_far, current_y, 1, width, 30, colour)
        x_so_far = x_so_far + width
      end
      current_y = current_y + 30
    end
  end
  lsDoFrame()
  local result = {}
  result.stop_after_this_run = stop_end_of_run
  result.pause_after_this_run = pause_after_this_run
  return result
end

-- Simple container object which constructs N plants and allows iteration over them.
Plants = {}
function Plants:new(o)
  for index = 1, o.num_plants do
    local location = PLANT_LOCATIONS[index]
    lsPrintln("Making plant " .. index .. " with location " .. location.direction_vector.x .. " , " .. location.direction_vector.y)
    self[index] = PlantController:new(
      index,
      location,
      o.alternate_drag,
      indexToWindowPos(index),
      o.seed_name,
      o.seed_type,
      o.config.num_waterings,
      o.config,
      findAllImages("veg_janitor/pin.png", 4800)
    )
  end
  return newObject(self, o, true)
end

function Plants:iterate(func, args)
  for index = 1, self.num_plants do
    func(self[index], args)
  end
end

-- Tiling method from Cinganjehoi's original bash script. Tried out the automato common ones but they are slow
-- and broke sometimes? This is super simple and its not the end of the world if it breaks a little during a run.
function indexToWindowPos(index)
  local columns = getNumberWindowColumns()
  local x = WINDOW_WIDTH * ((index - 1) % columns) + WINDOW_OFFSET_X
  local y = WINDOW_HEIGHT * math.floor((index - 1) / columns) + WINDOW_OFFSET_Y
  return Vector:new { x, y }
end

function getNumberWindowColumns()
  local xyWindowSize = srGetWindowSize()
  local width = xyWindowSize[0] * 0.6
  return math.floor(width / WINDOW_WIDTH);
end



-- Create a table of direction string -> box. Each box is where we will search the plant placed for that given direction
-- string.
-- Full of janky hardcoded values.
-- TODO: Make debuging this easier, figure out pixel scaling for different resolutions, get rid of magic numbers.
function makeSearchBox(direction, seed_type)
  local xyWindowSize = srGetWindowSize()
  local screen_size_percentage = (seed_type == "Onions") and 0.1 or 0.06
  local move_step_screen_size_percentage = 0.02
  local search_size = xyWindowSize[0] * screen_size_percentage
  local step_size = xyWindowSize[0] * move_step_screen_size_percentage
  local mid = getScreenMiddle()

  local centre_of_plant = direction * 40 + mid
  --    local offset_mid = mid - { math.floor(search_size / 3), math.floor(search_size / 3) }
  --
  --    local top_left = offset_mid + direction * 40 - Vector:new { 25, 20 }
  local top_left = mid + direction * step_size - { math.floor(search_size / 2), math.floor(search_size / 2) }

  local box = makeBox(top_left.x, top_left.y, search_size, search_size)
  box.direction = direction
  return box
end

