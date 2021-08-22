dofile("common.inc");

----------------------------------------
--          Global Variables          --
----------------------------------------
delay_time = 100;
lag_wait_after_click = 1500;
directions1 = {"Eastern", "Northern", "Southern", "Western"};
directions2 = {"Down", "Left", "Right", "Up"};
tolerance = 9000;
----------------------------------------

function doit()
  local num_workers=0;
    while ((not num_workers) or (num_workers < 2) or (num_workers > 5)) do
      num_workers = promptNumber("How many Workers (2-4)?", 4);
    end
  local my_index = 0;
    while ((not my_index) or (my_index < 1) or (my_index > num_workers)) do
      my_index = promptNumber("Which Worker # are you (1-" .. num_workers .. ")?", 1);
    end
  askForWindow("Quarrier #" .. my_index
  .. ", make sure the Skills window (END) is visible and quarry window is pinned.");
  local end_red;
  -- Initialize span
  has_been_raised = findText("has been raised");
    if not has_been_raised then
      error "Could not find text 'has been raised by'";
    end
  local span = string.match(has_been_raised[2], "raised by (%d+)");
  -- Initialize last directions
  local last_directions = {};
  for i=1, num_workers do
    last_directions[i] = {};
    last_directions[i][1] = -1;
    last_directions[i][2] = -1;
  end

  -- Refresh quarry window
  refreshWindows();
  local different = nil;

  while 1 do
    lsSleep(delay_time);
    srReadScreen();
    local quarry = findText("This is");
      if not quarry then
        error "Could not find quarry window";
      end

    eatOnion();

    -- Check END
    endurance = srFindImage("stats/endurance.png");
    if endurance then
      end_red = true;
    else
      end_red = nil;
    end

    -- Look for num_workers rows of Work This text
    local bounds = srGetWindowBorders(quarry[0], quarry[1]);
    local positions = {};
    local directions = {{}, {}, {}, {}};
    for index=1, num_workers do
      pos = srFindImageInRange("quarry/Quarry-WorkTheQuarry.png", bounds[0]+5, bounds[1]+5, 250, 200, tolerance);
        if not pos then
          error ("Could not find 'Work The Quarry' #" .. index);
        end
      positions[index] = pos;
      -- Find the directional text
      local my_direction1 = nil;
      for direction=1,4 do
        if srFindImageInRange("quarry/Quarry-" .. directions1[direction] .. ".png",
        pos[0], pos[1], 250, 10, tolerance) then
          my_direction1 = direction;
        end
      end
      if not my_direction1 then
        error ("Could not find direction1 for index #" .. index);
      end
      local my_direction2 = nil;
      for direction=1,4 do
        if srFindImageInRange("quarry/Quarry-" .. directions2[direction] .. ".png",
        pos[0], pos[1], 250, 10, tolerance) then
          my_direction2 = direction;
        end
      end
      if not my_direction2 then
        error ("Could not find direction2 for index #" .. index);
      end
      directions[index][1] = my_direction1;
      directions[index][2] = my_direction2;

      bounds[1] = pos[1] + 10; -- Don't find the same one!
    end

    -- Compare against last time
    closePopUp();
    for i=1,num_workers do
      if not ((last_directions[i][1] == directions[i][1]) and (last_directions[i][2] == directions[i][2])) then
        different = 1;
      end
      last_directions[i][1] = directions[i][1];
      last_directions[i][2] = directions[i][2];
    end

    -- Sort
    sorted = {1, 2, 3, 4};
    for i=1,num_workers do
      for j=i+1,num_workers do
        if ((directions[sorted[i]][1] > directions[sorted[j]][1]) or
          ((directions[sorted[i]][1] == directions[sorted[j]][1]) and
          (directions[sorted[i]][2] > directions[sorted[j]][2]))) then
          sorted[i], sorted[j] = sorted[j], sorted[i];
        end
      end
    end

    -- Check to see if span indicator has changed!
    has_been_raised = findText("has been raised");
      if not has_been_raised then
        error "Could not find text 'has been raised by'";
      end
    local new_span = string.match(has_been_raised[2], "raised by (%d+)");
      if new_span ~= span then
        different = 1;
      end
    span = new_span;

    -- Display status and debug info
    lsPrint(10, 10, 0, 0.7, 0.7, 0xB0B0B0ff, "Hold Ctrl+Shift to end this script.");
    lsPrint(10, 20, 0, 0.7, 0.7, 0xB0B0B0ff, "Hold Alt+Shift to pause this script.");
    if end_red then
      lsPrint(10, 60, 0, 1, 1, 0xFF8080ff, "Waiting for Endurance timer to reset...");
    elseif different then
      lsPrint(10, 60, 0, 1, 1, 0x20FF20ff, "Quarrying...");
    else
      lsPrint(10, 60, 0, 1, 1, 0xFFFFFFff, "Waiting for change...");
    end
    for index=1, num_workers do
      color = 0xFFFFFFff;
      if index == my_index then
        color = 0xDFFFDFff;
      end
      lsPrint(10, 80 + 15*index, 0, 0.7, 0.7, color, "#" .. index .. " - #" .. sorted[index] .. " "
      .. positions[sorted[index]][0] .. "," .. positions[sorted[index]][1] .. " = "
      .. directions1[directions[sorted[index]][1]] .. "-" .. directions2[directions[sorted[index]][2]]);
    end
    if lsButtonText(lsScreenX - 110, lsScreenY - 30, nil, 100, 0xFFFFFFff, "End script") then
      error "Clicked End Script button";
    end
    -- display log
    checkBreak("button_pause");
    lsDoFrame();

    if end_red then
      -- Do nothing
      -- Refresh quarry window
      refreshWindows();
    elseif different then
      index = sorted[my_index];
      -- Click my button!
      srClickMouseNoMove(positions[index][0]+5, positions[index][1]+1, 0);
      sleepWithStatus(lag_wait_after_click,"Clicked: " .. directions1[directions[index][1]] .. "-"
      .. directions2[directions[index][2]] .. "\n\nSlight pause for potential lag to catch up!", nil, 0.7);
      different = nil;
      -- Refresh the window
      refreshWindows();
    else
      -- Refresh quarry window
      refreshWindows();
    end
  end
end

function eatOnion()
  srReadScreen();
  buffed = srFindImage("stats/enduranceBuff.png");
    if buffed then
      return;
    end
  local consume = findText("Consume");
    if not consume then
      return;
    end
  safeClick(consume[0],consume[1]);
  waitForImage("stats/enduranceBuff.png", 3000, "Waiting for the green endurance icon to appear");
end

function refreshWindows()
  srReadScreen();
  this = findAllText("This is");
    for i=1,#this do
      clickText(this[i]);
    end
  lsSleep(150);
end

function closePopUp()
  while 1 do
    srReadScreen()
    local ok = srFindImage("OK.png")
	    if ok then
	      statusScreen("Found and Closing Popups ...", nil, 0.7);
	      srClickMouseNoMove(ok[0]+5,ok[1]);
	      lsSleep(100);
	    else
	      break;
	    end
  end
end
