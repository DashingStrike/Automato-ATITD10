dofile("common.inc");
dofile("settings.inc");

askText = "Two methods available: Use Fertilizer or Water Only.\n\n"
.. "'Right click pins/unpins a menu' must be ON.\n\n"
.. "'Plant all crops where you stand' must be ON.\n\n"
.. "Pin Barley Plant window in TOP-RIGHT.\n\n"
.. "Automato: Slighty in TOP-RIGHT.";

----------------------------------------
--          Global Variables          --
----------------------------------------
num_loops = 1;
grid_w = 4;
grid_h = 4;
is_plant = true;

finish_up = 0;
finish_up_message = "";
use_fert = true;
readClock = true;

-- Tweakable delay values
refresh_time = 60; -- Time to wait for windows to update
walk_time = 750; -- Reduce to 300 if you're fast.

-- Don't touch. These are set according to Jimbly's black magic.
walk_px_y = 320;
walk_px_x = 340;

xyCenter = {};
xyFlaxMenu = {};

-- The barley bed window
window_w = 258;
window_h = 218

--[[
How much of the ATITD screen to ignore (protect the right side of screen from closing windows when finished
max_width_offset will prevent it from reading all the way to the right edge of game client
This should be about 425 if we can use aquaduct. We can use 350 if no aquaduct window is present (to refill jugs).
--]]
max_width_offset = 350
----------------------------------------

-------------------------------------------------------------------------------
-- initGlobals()
--
-- Set up black magic values used for trying to walk a standard grid.
-------------------------------------------------------------------------------

function initGlobals()
  -- Macro written with 1720 pixel wide window

  srReadScreen();
  xyWindowSize = srGetWindowSize();

  local pixel_scale = xyWindowSize[0] / 1720;
  lsPrintln("pixel_scale " .. pixel_scale);

  walk_px_y = math.floor(walk_px_y * pixel_scale);
  walk_px_x = math.floor(walk_px_x * pixel_scale);

  local walk_x_drift = 14;
  local walk_y_drift = 18;
    if (lsScreenX < 1280) then
      -- Have to click way off center in order to not move at high resolutions
      walk_x_drift = math.floor(walk_x_drift * pixel_scale);
      walk_y_drift = math.floor(walk_y_drift * pixel_scale);
    else
      -- Very little drift at these resolutions, clicking dead center barely moves
      walk_x_drift = 1;
      walk_y_drift = 1;
    end

  xyCenter[0] = xyWindowSize[0] / 2 - walk_x_drift;
  xyCenter[1] = xyWindowSize[1] / 2 + walk_y_drift;
  xyFlaxMenu[0] = xyCenter[0] - 43*pixel_scale;
  xyFlaxMenu[1] = xyCenter[1] + 0;
end

-------------------------------------------------------------------------------
-- checkWindowSize()
--
-- Set width and height of barley window based on whether they are guilded.
-------------------------------------------------------------------------------

window_check_done_once = false;
function checkWindowSize()
  if not window_check_done_once then
    srReadScreen();
    window_check_done_once = true;
--     local pos = srFindImageInRange(imgUseable, x-5, y-50, 150, 100)
     local pos = findText("Useable by");
     if pos then
        window_h = window_h + 15;
     end
     pos = findText("Game Master");
     if pos then
        window_h = window_h + 30;
     end
  end
end

-------------------------------------------------------------------------------
-- promptFlaxNumbers()
--
-- Gather user-settable parameters before beginning
-------------------------------------------------------------------------------

function promptFlaxNumbers()
  scale = 0.75;
  local z = 0;
  is_done = nil;
  -- Edit box and text display
  while not is_done do
    local y = 5;
    -- Make sure we don't lock up with no easy way to escape!
    checkBreak();
    lsPrintWrapped(5, y, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
    "Global Settings\n-------------------------------------------");
    y = y + 35;

    -- lsEditBox needs a key to uniquely name this edit box
    --   let's just use the prompt!
    -- lsEditBox returns two different things (a state and a value)
    lsPrint(5, y, z, scale, scale, 0xFFFFFFff, "Passes:");
    num_loops = readSetting("num_loops",num_loops);
    is_done, num_loops = lsEditBox("passes", 85, y, z, 40, 0, scale, scale,
                                   0x000000ff, num_loops);
    if not tonumber(num_loops) then
      is_done = nil;
      lsPrint(135, y, z+10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
      num_loops = 1;
    end
    writeSetting("num_loops",num_loops);
    y = y + 32;
    lsPrint(5, y-10, z, scale, scale, 0xFFFFFFff, "Grid size:");
    grid_w = readSetting("grid_w",grid_w);
    is_done, grid_w = lsEditBox("grid", 85, y-10, z, 40, 0, scale, scale,
                                0x000000ff, grid_w);
    if not tonumber(grid_w) then
      is_done = nil;
      lsPrint(135, y, z+10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
      grid_w = 1;
      grid_h = 1;
    end
    writeSetting("grid_w",grid_w);
    grid_w = tonumber(grid_w);
    grid_h = grid_w;

    lsPrintWrapped(5, y+20, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
    "Plant Settings\n-------------------------------------------");
    y = y + 20;

    if is_plant then
      if lsButtonText(10, lsScreenY - 30, 0, 100, 0x00ff00ff, "Next") then
          is_done = 1;
      end
    y = y + 35;

		if grid_w < 3 then
		  totalWater = 4
		elseif grid_w == 3 then
		  totalWater = 5
		elseif grid_w == 4 then
		  totalWater = 6
		else
		  totalWater = 7;
		end

    use_fert = readSetting("use_fert",use_fert);
      if use_fert then
        use_fert = CheckBox(10, y, z, 0xff8080ff, " Use Fertilizer (Uncheck for Water Only)", use_fert, 0.7, 0.7);
        totalWater = 7;
        totalFertilizer = 4;
      else
        use_fert = CheckBox(10, y, z, 0x8080ffff, " Use Water Only (Check for Fertilizer)", use_fert, 0.7, 0.7);
        totalFertilizer = 0;
      end
    writeSetting("use_fert",use_fert);
    y = y + 25;

    readClock = readSetting("readClock",readClock);
    readClock = CheckBox(10, y-5, z, 0xFFFFFFff, " Read Clock (Find Coords/Walk to StartPos)", readClock, 0.7, 0.7);
    writeSetting("readClock",readClock);
    y = y + 5;

    lsPrintWrapped(5, y+10, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
    "-------------------------------------------");
    y = y + 20;

      if use_fert then
        lsPrintWrapped(10, y+10, z+10, lsScreenX - 20, 0.7, 0.7, 0xD0D0D0ff, "Plant/Harvest a " .. grid_w .. "x" ..
        grid_w .. " grid of " .. num_loops .. " times\n\nRequires:\n(" .. math.floor(grid_w * grid_w * num_loops) ..
        ") Barley\n(" .. math.floor(grid_w * grid_w * num_loops*totalWater) .. ") Water\n" ..
        "(" .. math.floor(grid_w * grid_w * num_loops*totalFertilizer) .. ") Fertilizer\n\n"..
        "Yields: 2-10+ per plant (10 = no weeds)");
      else
        lsPrintWrapped(10, y+10, z+10, lsScreenX - 20, 0.7, 0.7, 0xD0D0D0ff,"Plant/Harvest a " .. grid_w .. "x" ..
        grid_w .. " grid of " .. num_loops .. " times\n\nRequires:\n(" .. math.floor(grid_w * grid_w * num_loops) ..
        ") Barley\n(" .. math.floor(grid_w * grid_w * num_loops*totalWater) .. ") Water\n\n" ..
        "Yields: 2+ per plant");
      end
    end

    if is_done and (not num_loops or not grid_w) then
      error 'Canceled';
    end

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFF0000ff, "End script") then
      error "Clicked End Script button";
    end

    lsDoFrame();
    lsSleep(tick_delay);
  end
end

-------------------------------------------------------------------------------
-- getPlantWindowPos()
-------------------------------------------------------------------------------

lastPlantPos = nil;

function getPlantWindowPos()
  srReadScreen();
  local plantPos = findText("Plant");
  if plantPos then
    plantPos[0] = plantPos[0] + 20;
    plantPos[1] = plantPos[1] + 10;
  else
    plantPos = lastPlantPos;
    if plantPos then
      safeClick(plantPos[0], plantPos[1]);
      lsSleep(refresh_time);
    end
  end
  if not plantPos then
    error 'Could not find \'Barley\' on plant window';
  end
  lastPlantPos = plantPos;
  return plantPos;
end

-------------------------------------------------------------------------------
-- doit()
-------------------------------------------------------------------------------

function doit()

  promptFlaxNumbers();
  askForWindow(askText);
  initGlobals();
  local startPos;
  local z = 0;

  if readClock then
    srReadScreen();
    startPos = findCoords();
      if not startPos then
        error("ATITD clock not found. Try unchecking Read Clock option if problem persists");
      end
    lsPrintln("Start pos:" .. startPos[0] .. ", " .. startPos[1]);
  end

  setCameraView(CARTOGRAPHER2CAM);
  drawWater();
  startTime = lsGetTimer();

  for loop_count=1, num_loops do
    ticks = -1;
    fertilizerUsed = 0;
    waterUsed = 0;
    quit = false;
    error_status = "";
    plantAndPin(loop_count);
    dragWindows(loop_count);
    statusScreen("Adding 2 Water/Fertilizer ...",nil, nil, 0.7);
    waterBarley(); -- Do initial 2 water
    fertilizeBarley(); -- Do initial 2 fertilizer


  while 1 do
    checkBreak();
    findWaterBar();

	if not barleyWaterBar then
	  ticks = ticks + 1;
		if ticks+2 <= totalWater then
      waterBarley();
		end

		if ticks+2 <= totalFertilizer then
      fertilizeBarley();
		end
			if (ticks < totalWater - 1) and ticks ~= 0 then
        sleepWithStatus(999, "Added Water / Fertilizer",nil, 0.7, "Tended Barley");
			end
      end


	if ticks == totalWater - 1 then
	    break;
	end

	if finish_up == 0 then
		if lsButtonText(lsScreenX - 110, lsScreenY - 60, z, 100, 0xFFFFFFff, "Finish up") then
      finish_up = 1;
      finish_up_message = "\n\nFinishing up ..."
		end
	else
		if lsButtonText(lsScreenX - 110, lsScreenY - 60, z, 100, 0x80ff80ff, "Undo") then
      finish_up = 0;
      finish_up_message = ""
		end
	end

  statusScreen("Watching top-left window for tick ...\n\nTicks since planting: " .. ticks .. "/" .. totalWater - 1 .. "\n\n" ..
  "[" .. waterUsed .. "/" .. totalWater*goodPlantings .. "]  Jugs of Water Used "  .. "\n[" .. fertilizerUsed .. "/" .. totalFertilizer*goodPlantings .. "]  Fertilizer Used\n\n[" .. loop_count .. "/" .. num_loops .. "]  Current Pass\n\nElapsed Time: " .. getElapsedTime(startTime) .. finish_up_message, nil, nil, 0.7);

  lsSleep(100);
  end -- while

  sleepWithStatus(1000, "Ticks since planting: " .. ticks .. "/" .. totalWater - 1 .. "\n\n[" .. waterUsed .. "/" .. totalWater*goodPlantings .. "]  Jugs of Water Used "  .. "\n[" .. fertilizerUsed .. "/" .. totalFertilizer*goodPlantings .. "] Fertilizer Used\n\n[" .. loop_count .. "/" .. num_loops .. "]  Current Pass\n\nElapsed Time: " .. getElapsedTime(startTime) .. finish_up_message,nil, 0.7, "Ready for Harvesting");

    harvestAll();
    walkHome(startPos);
    drawWater();
	if finish_up == 1 or quit then
	  break;
	end
  end
  lsPlaySound("Complete.wav");
  lsMessageBox("Elapsed Time:", getElapsedTime(startTime), 1);
end

-------------------------------------------------------------------------------
-- plantAndPin()
--
-- Walk around in a spiral, planting flax seeds and grabbing windows.
-------------------------------------------------------------------------------

function plantAndPin(loop_count)
  local xyPlantFlax = getPlantWindowPos();

  -- for spiral
  local dxi=1;
  local dt_max=grid_w;
  local dt=grid_w;
  local dx={1, 0, -1, 0};
  local dy={0, -1, 0, 1};
  local num_at_this_length = 3;
  local x_pos = 0;
  local y_pos = 0;
  local success = true;
  goodPlantings = 0;

  for y=1, grid_h do
    for x=1, grid_w do
      statusScreen("(" .. loop_count .. "/" .. num_loops .. ") Planting " ..
                   x .. ", " .. y .. "\n\nElapsed Time: " .. getElapsedTime(startTime));
      success = plantHere(xyPlantFlax);
      if not success then
        break;
      end

      -- Move to next position
      if not ((x == grid_w) and (y == grid_h)) then
        lsPrintln('walking dx=' .. dx[dxi] .. ' dy=' .. dy[dxi]);
	lsSleep(40);
        x_pos = x_pos + dx[dxi];
        y_pos = y_pos + dy[dxi];
	local spot = getWaitSpot(xyFlaxMenu[0], xyFlaxMenu[1]);
        safeClick(xyCenter[0] + walk_px_x*dx[dxi],
                  xyCenter[1] + walk_px_y*dy[dxi], 0);

        spot = getWaitSpot(xyFlaxMenu[0], xyFlaxMenu[1]);
	if not waitForChange(spot, 1500) then
	  error_status = "Did not move on click.";
	  break;
	end
        lsSleep(walk_time);
        waitForStasis(spot, 1500);
        dt = dt - 1;
        if dt == 1 then
          dxi = dxi + 1;
          num_at_this_length = num_at_this_length - 1;
          if num_at_this_length == 0 then
            dt_max = dt_max - 1;
            num_at_this_length = 2;
          end
          if dxi == 5 then
            dxi = 1;
          end
          dt = dt_max;
        end
      else
        lsPrintln('skipping walking, on last leg');
      end
    end
    checkBreak();
    if not success then
      break;
    end
  end
  local finalPos = {};
  finalPos[0] = x_pos;
  finalPos[1] = y_pos;
  return finalPos;
end

-------------------------------------------------------------------------------
-- plantHere(xyPlantFlax)
--
-- Plant a single flax bed, get the window, pin it, then stash it.
-------------------------------------------------------------------------------

function plantHere(xyPlantFlax)
  -- Plant
  lsPrintln('planting ' .. xyPlantFlax[0] .. ',' .. xyPlantFlax[1]);
  local bed = clickPlant(xyPlantFlax);
  if not bed then
    return false;
  end

  -- Bring up menu
  lsPrintln('menu ' .. bed[0] .. ',' .. bed[1]);
  if not openAndPin(bed[0], bed[1], 3500) then
    error_status = "No window came up after planting.";
    return false;
  end

  goodPlantings = goodPlantings + 1;

  -- Check for window size
  checkWindowSize();

  -- Move window into corner
  stashWindow(bed[0] + 5, bed[1], BOTTOM_RIGHT);
  return true;
end

function clickPlant(xyPlantFlax)
  local result = xyFlaxMenu;
  local spot = getWaitSpot(xyFlaxMenu[0], xyFlaxMenu[1]);
  safeClick(xyPlantFlax[0], xyPlantFlax[1], 0);

  spot = getWaitSpot(xyFlaxMenu[0], xyFlaxMenu[1])
  local plantSuccess = waitForChange(spot, 1500);
  if not plantSuccess then
    error_status = "No barley bed was placed when planting.";
    result = nil;
  end
  return result;
end

-------------------------------------------------------------------------------
-- dragWindows(loop_count)
--
-- Move flax windows into a grid on the screen.
-------------------------------------------------------------------------------

function dragWindows(loop_count)
  statusScreen("(" .. loop_count .. "/" .. num_loops .. ")  " ..
               "Dragging Windows into Grid" .. "\n\nElapsed Time: " .. getElapsedTime(startTime));
--    arrangeStashed(nil, waterGap, window_w, window_h);
    arrangeStashed();
end

-------------------------------------------------------------------------------
-- walkHome(loop_count, finalPos)
--
-- Walk back to the origin (southwest corner) to start planting again.
-------------------------------------------------------------------------------

function walkHome(finalPos)
  -- Close all empty windows
--  closeEmptyAndErrorWindows();
  closeAllWindows(0,0, xyWindowSize[0]-max_width_offset, xyWindowSize[1]);

  if readClock then
    walkTo(finalPos);
  end

  -- Refresh any empty windows (in case we used out last seed, re-vive the previously plant window
  srReadScreen();
  closedPlantWindow = srFindImage("WindowEmpty.png")
  if closedPlantWindow then
    srClickMouseNoMove(closedPlantWindow[0]+2, closedPlantWindow[1]+2);
  end
end


function waterBarley()
  srReadScreen();
  barleyWaterImage = findAllImages("barley/barleyWater.png");
    if #barleyWaterImage == 0 then
      error("Could not find 'Water:' text in barley pinned menu (Top Left corner only)");
    else
		for i=#barleyWaterImage, 1, -1  do
			checkBreak();
			safeClick(barleyWaterImage[i][0]+192, barleyWaterImage[i][1]+3);
			waterUsed = waterUsed + 1;
		end
    end
end


function fertilizeBarley()
  srReadScreen();
  barleyWaterImage = findAllImages("barley/barleyWater.png");
    if #barleyWaterImage == 0 then
      error("Could not find 'Water:' text in barley pinned menu (Top Left corner only)");
    elseif use_fert then
		for i=#barleyWaterImage, 1, -1  do
			checkBreak();
			safeClick(barleyWaterImage[i][0]+192, barleyWaterImage[i][1]+23);
			fertilizerUsed = fertilizerUsed + 1;
		end
    end
end


function findWaterBar()
  srReadScreen();
  barleyWaterBar = srFindImageInRange("barley/barleyWaterFull.png", 0, 0, window_w, window_h);
end



function harvestAll()
  srReadScreen();
  harvest = findAllImages("barley/BarleyHarvest.png");
    if #harvest == 0 then
       error("No harvest images found");
    else
	for i=#harvest, 1, -1  do
	  safeClick(harvest[i][0]+5, harvest[i][1]+5);
	  lsSleep(100);
	end
    end

  local totalHarvested = #harvest

    while #harvest > 0 do
      srReadScreen();
      harvest = findAllImages("barley/BarleyHarvest.png");
      sleepWithStatus(100, "Harvested " .. totalHarvested .. " plants!\n\nWaiting for windows to catch up!\n\nElapsed Time: " .. getElapsedTime(startTime) .. finish_up_message, nil, 0.7, "Please standby");
    end
  closeWindowsFast();
end


function closeWindowsFast()
	srReadScreen();
	local allTextReferences = findAllText("This is");
	for buttons=1, #allTextReferences do
		srClickMouseNoMove(allTextReferences[buttons][0]+20, allTextReferences[buttons][1]+5, 1);
	end
end
