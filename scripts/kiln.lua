dofile("common.inc");
dofile("settings.inc");

----------------------------------------
--          Global Variables          --
----------------------------------------
dropdown_values = {"Shift Key", "Ctrl Key", "Alt Key", "Mouse Wheel Click"};
kilnList = {"True Kiln","Reinforced Kiln"};
productNames = { "Wet Clay Bricks", "Wet Clay Mortars", "Wet Firebricks", "Wet Jugs", "Wet Claypots" };
dropdown_cur_value = 1;
total_delay_time = 155000;

window_h = 200;
window_w = 481;

-- Tweakable delay values
refresh_time = 250 -- Time to wait for windows to update

askText = "Automatic Kilns - Produce all of the clay products!";
wmText = "Tap Ctrl on kilns to open and pin.\nTap Alt on kilns to open, pin and stash.";
----------------------------------------

function doit()
  askForWindow(askText);
  promptParameters();
  if pinnedMode then
		windowManager("Kiln Setup", wmText, false, true, window_w, window_h, nil, 20, 25);
		sleepWithStatus(500, "Starting... Don\'t move mouse!");
		unpinOnExit(start);
	elseif hotkeyMode then
    getPoints();
		clickSequence();
  end
end

function promptParameters()
  scale = 1.1;
  local z = 0;
  is_done = nil;
  -- Edit box and text display
  while not is_done do
    -- Make sure we don't lock up with no easy way to escape!
    checkBreak();
    local y = 40;
    lsSetCamera(0,0,lsScreenX*scale,lsScreenY*scale);
	    if pinnedMode and not hotkeyMode then
        kilnPasses = readSetting("kilnPasses",tonumber(kilnPasses));
        lsPrint(10, y-30, z, scale, scale, 0xffffffff, "Passes:");
        is_done, kilnPasses = lsEditBox("kilnPasses", 115, y-28, z, 50, 30, scale, scale,
                                   0x000000ff, kilnPasses);
        if not tonumber(kilnPasses) then
          is_done = false;
          lsPrint(160, y-25, z+10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
          kilnPasses = 1;
        end
        writeSetting("kilnPasses",tonumber(kilnPasses));
        y = y + 32;

        lsPrint(10, y-26, 0, scale, scale, 0xffffffff, "Kiln Type:");
        kiln = lsDropdown("kiln", 115, y-25, 0, 150, kiln, kilnList);
        y = y + 32;

        lsPrint(10, y-20, 0, scale, scale, 0xffffffff, "Product:");
        typeOfProduct = readSetting("typeOfProduct",typeOfProduct);
        typeOfProduct = lsDropdown("typeOfProduct", 115, y-20, 0, 180, typeOfProduct, productNames);
        writeSetting("typeOfProduct",typeOfProduct);
        y = y + 32;
	    else
	      pinnedMode = false;
	    end

    if hotkeyMode and not pinnedMode then
      lsPrint(10, y-25, z, scale, scale, 0xFFFFFFff, "Hotkey:");
      dropdown_cur_value = lsDropdown("ArrangerDropDown", 100, 17, 0, 200, dropdown_cur_value, dropdown_values);
      y = y + 32;

      hotkeyTask = readSetting("hotkeyTask",hotkeyTask);
      lsPrint(10, y-23, z, scale, scale, 0xFFFFFFff, "Task:");
      hotkeyTask = lsDropdown("hotkeyTask", 100, 50, 0, 200, hotkeyTask, productNames);
      writeSetting("hotkeyTask",hotkeyTask);
      y = y + 32;

      kilnPasses = readSetting("kilnPasses",tonumber(kilnPasses));
      lsPrint(10, y-23, z, scale, scale, 0xffffffff, "Passes:");
      is_done, kilnPasses = lsEditBox("kilnPasses", 100, y-20, z, 50, 30, scale, scale,
                                 0x000000ff, kilnPasses);
        if not tonumber(kilnPasses) then
          is_done = false;
          lsPrint(160, y-25, z+10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
          kilnPasses = 1;
        end
      writeSetting("kilnPasses",tonumber(kilnPasses));
      lsPrintWrapped(10, y+15, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
      "Task Settings\n-------------------------------------------");
      y = y + 62;
      repairHotkey = readSetting("repairHotkey",repairHotkey);
      lsPrint(10, y-14, z, 0.8, 0.8, 0xffffffff, "Repair Hotkey:");
      is_done, repairHotkey = lsEditBox("repairHotkey", 140, y-15, 0, 50, 30, 1.0, 1.0, 0x000000ff, 100);
      writeSetting("repairHotkey",repairHotkey);
        if hotkeyTask == 5 then
          y = y + 32;
          claypotHotkey = readSetting("claypotHotkey",claypotHotkey);
          lsPrint(10, y-14, z, 0.8, 0.8, 0xffffffff, "Claypot Hotkey:");
          is_done, claypotHotkey = lsEditBox("claypotHotkey", 140, y-15, 0, 50, 30, 1.0, 1.0, 0x000000ff, 100);
          writeSetting("claypotHotkey",claypotHotkey);
        end
    else
      hotkeyMode = false;
    end

		if pinnedMode then
			pinnedModeColor = 0x80ff80ff;
		else
			pinnedModeColor = 0xffffffff;
		end

		if hotkeyMode then
			hotkeyModeColor = 0x80ff80ff;
		else
			hotkeyModeColor = 0xffffffff;
		end

		if pinnedMode then
      helpText = "Uncheck Pinned Mode to switch to Hotkey Mode"
    elseif hotkeyMode then
      helpText = "Uncheck Hotkey Mode to switch to Pinned Mode"
    else
      helpText = "Check Hotkey or Pinned Mode to Begin"
    end

		pinnedMode = readSetting("pinnedMode",pinnedMode);
		hotkeyMode = readSetting("hotkeyMode",hotkeyMode);

		if not pinnedMode and not hotkeyMode then
			lsPrintWrapped(10, y, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
			"Mode Settings\n---------------------------------------");
			y = y + 5;
			pinnedMode = CheckBox(10, y+25, z, pinnedModeColor, " Pinned Window Mode", pinnedMode, 0.65, 0.65);
      writeSetting("pinnedMode",pinnedMode);
		  y = y + 22;
			hotkeyMode = CheckBox(10, y+25, z, hotkeyModeColor, " Hotkey Mode", hotkeyMode, 0.65, 0.65);
      writeSetting("hotkeyMode",hotkeyMode);
		  y = y + 22;
			lsPrint(10, y+50, z, 0.65, 0.65, 0xFFFFFFff, helpText);
		elseif pinnedMode and not hotkeyMode then
			lsPrintWrapped(10, y-10, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
			"Mode Settings\n---------------------------------------");
			y = y + 5;
			pinnedMode = CheckBox(10, y+5, z, pinnedModeColor, " Pinned Window Mode", pinnedMode, 0.65, 0.65);
      writeSetting("pinnedMode",pinnedMode);
		  y = y + 22;
			lsPrint(10, y+5, z, 0.65, 0.65, 0xFFFFFFff, helpText);
			y = y + 22;
			lsPrintWrapped(10, y+5, z+10, lsScreenX - 20, 0.7, 0.7, 0xD0D0D0ff,
		  "Stand where you can reach all kilns with all ingredients on you.");
		elseif hotkeyMode and not pinnedMode then
			lsPrintWrapped(10, y+15, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
			"Mode Settings\n---------------------------------------");
			y = y + 5;
			hotkeyMode = CheckBox(10, y+25, z, hotkeyModeColor, " Hotkey Mode", hotkeyMode, 0.65, 0.65);
      writeSetting("hotkeyMode",hotkeyMode);
		  y = y + 22;
			lsPrint(10, y+25, z, 0.65, 0.65, 0xFFFFFFff, helpText);
			y = y + 22;
			lsPrintWrapped(10, y+25, z+10, lsScreenX - 20, 0.7, 0.7, 0xD0D0D0ff,
		  "Stand where you can reach all kilns with all ingredients on you.");
    end

	if pinnedMode and kilnPasses ~= 1 then
		if lsButtonText(10, lsScreenY - 30, z, 100, 0x00ff00ff, "Begin") then
			is_done = 1;
    end
    else
    if hotkeyMode and kilnPasses ~= 1 then
      if lsButtonText(10, lsScreenY - 30, z, 100, 0x00ff00ff, "Next") then
        is_done = 1;
      end
    end
	end

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFF0000ff,
      "End script") then
      error "Clicked End Script button";
    end
    lsDoFrame();
    lsSleep(tick_delay);
  end
end

function start()
  for i=1, kilnPasses do
    -- refresh windows
		refreshWindows();
		lsSleep(500);
    srReadScreen();
    statusScreen("Emptying the kilns before starting");
    takeFromKilns(); -- Empty the kilns before starting
    checkRepair();
    srReadScreen();
    clickAllText("with Wood");
    sleepWithStatus(1000,"Adding " .. productNames[typeOfProduct] .. " to the kiln");
    clickAllText(productNames[typeOfProduct]);
    sleepWithStatus(1000,"Firing all kilns");
    clickAllText("Fire the Kiln");
    refreshWindows();
    sleepWithStatus(1500,"Short pause to handle server latency")
    srReadScreen();
    checkFiring();
  end
  lsPlaySound("Complete.wav");
end

function takeFromKilns()
  srReadScreen();
  kilnRegions = findAllText("This is [A-Za-z]+ [A-Za-z]+ Kiln", nil, REGION + REGEX);
  for i = 1, #kilnRegions do
    checkBreak();
    local p = findText("Take...", kilnRegions[i]);
      if (p) then
        safeClick(p[0]+4,p[1]+4);
        lsSleep(refresh_time);
        srReadScreen();
        local e = findText("Everything");
          if (e) then
            safeClick(e[0]+4,e[1]+4);
            lsSleep(refresh_time);
          end
    end
  end
end

function checkRepair()
  refreshWindows();
  lsSleep(refresh_time);
  closePopUp();
  srReadScreen();
  clickAllText("Repair");
  lsSleep(refresh_time);
end

function refreshWindows()
srReadScreen();
  this = findAllText("This");
    for i = 1, #this do
      safeClick(this[i][0]+4,this[i][1]+4);
    end
  lsSleep(refresh_time);
end

function checkFiring()
  while 1 do
    refreshWindows();
    srReadScreen();
    firing = findAllText("Firing");
      if #firing == 0 then
        break; --We break this while statement because Making is not detect, hence we're done with this round
      end
    sleepWithStatus(999, "Waiting for " .. productNames[typeOfProduct]
    .. " to finish", nil, 0.7, "Monitoring / Refreshing Windows")
  end
end

function getPoints()
clickList = {};
  local was_shifted = lsShiftHeld();

  if (dropdown_cur_value == 1) then
  was_shifted = lsShiftHeld();
  key = "tap Shift";
  elseif (dropdown_cur_value == 2) then
  was_shifted = lsControlHeld();
  key = "tap Ctrl";
  elseif (dropdown_cur_value == 3) then
  was_shifted = lsAltHeld();
  key = "tap Alt";
  elseif (dropdown_cur_value == 4) then
  was_shifted = lsMouseIsDown(2); --Button 3, which is middle mouse or mouse wheel
  key = "click MWheel ";
  end

  local is_done = false;
  local z = 0;
  while not is_done do
    mx, my = srMousePos();
    local is_shifted = lsShiftHeld();

    if (dropdown_cur_value == 1) then
      is_shifted = lsShiftHeld();
    elseif (dropdown_cur_value == 2) then
      is_shifted = lsControlHeld();
    elseif (dropdown_cur_value == 3) then
      is_shifted = lsAltHeld();
    elseif (dropdown_cur_value == 4) then
      is_shifted = lsMouseIsDown(2); --Button 3, which is middle mouse or mouse wheel
    end

    if is_shifted and not was_shifted then
      clickList[#clickList + 1] = {mx, my};
    end
    was_shifted = is_shifted;
    checkBreak();
    lsPrint(10, 10, z, 0.7, 0.7, 0xFFFFFFff,
	    "Set Kiln Locations (" .. #clickList .. ")");
    local y = 60;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Select camera and zoom level");
    y = y + 20
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "that best fits the Kilns in screen.")
    y = y + 20
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Suggest: F8F8 view.")
    y = y + 20
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Lock ATITD screen with Alt+L")
    y = y + 40;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "MAKE SURE CHAT IS MINIMIZED!")
    y = y + 40;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "1) Set all Kiln locations:");
    y = y + 20;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Hover mouse, " .. key .. " over each")
    y = y + 20;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Kiln.")
    y = y + 30;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "2) After setting all Kiln locations:")
    y = y + 20;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Click Start to begin checking Kilns.")

    if #clickList >= 1 then -- Only show start button if one or more Kiln was selected.
      if lsButtonText(10, lsScreenY - 30, z, 100, 0xFFFFFFff, "Start") then
        is_done = 1;
      end
    end

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff,
                    "End script") then
      error "Clicked End Script button";
    end

    lsDoFrame();
    lsSleep(50);
  end
end

function clickSequence()
  sleepWithStatus(1500, "Starting... Don\'t move mouse!");
	startTime = lsGetTimer();
  kilnCounter = 1;
  takeCounter = 1;
		for l=1, kilnPasses do
      for i=1,#clickList do
        statusScreen("Filling the Kilns\n\n" .. kilnCounter .. " / " .. #clickList .. " Remaining",nil, nil, 0.7);
        srSetMousePos(clickList[i][1], clickList[i][2]);
        lsSleep(150); -- ~65+ delay needed before the mouse can actually move.
        kilnAction();
        kilnCounter = kilnCounter + 1
      end
		local time_left = total_delay_time - #clickList
		lsSleep(100);
		closePopUp(); -- Screen clean up
		sleepWithStatus(time_left,"Pass " .. l .. " of " .. kilnPasses .. "\nWaiting for products to finish\n\n"
    .. "BE CAREFUL:\nThe macro will resume control of your mouse after the timer has finished!");
      for i=1,#clickList do
        statusScreen("Taking items from the Kilns\n\n" .. takeCounter .. " / " .. #clickList
        .. " Remaining",nil, nil, 0.7);
        srSetMousePos(clickList[i][1], clickList[i][2]);
        lsSleep(150); -- ~65+ delay needed before the mouse can actually move.
        kilnTake();
        takeCounter = takeCounter + 1
      end
	end
  lsPlaySound("Complete.wav");
  lsMessageBox("Elapsed Time:", getElapsedTime(startTime), 1);
end

function kilnTake()
  checkBreak();
  closePopUp(); -- Screen clean up
  srKeyEvent('t');
end

function kilnAction()
  if hotkeyTask == 1 then
    inputkey = "c"
  elseif hotkeyTask == 2 then
    inputkey = "m"
  elseif hotkeyTask == 3 then
    inputkey = "b"
  elseif hotkeyTask == 4 then
    inputkey = "j"
  elseif hotkeyTask == 5 then
    inputkey = claypotHotkey
  end

  checkBreak();
  closePopUp(); -- Screen clean up
  srKeyEvent('w');
  lsSleep(150);
  srReadScreen();
  closePopUp(); -- Screen clean up
  lsSleep(150);
  srKeyEvent(inputkey);
  lsSleep(150);
  srReadScreen();
  closePopUp(); -- Screen clean up
  lsSleep(150);
  srKeyEvent('f');
  closePopUp(); -- Screen clean up
  lsSleep(150);
  srKeyEvent(repairHotkey);
  closePopUp(); -- Screen clean up
end

function closePopUp()
  while 1 do
    srReadScreen()
    local outofresource = srFindImage("YouDont.png");
    local ok = srFindImage("OK.png");
      if ok then
        statusScreen("Found and Closing Popups ...", nil, 0.7);
        safeClick(ok[0]+2,ok[1]+2);
        lsSleep(100);
          if outofresource then
             error("Out of resources");
          end
      else
          break;
      end
  end
end
