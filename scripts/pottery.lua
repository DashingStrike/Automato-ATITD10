dofile("common.inc");
dofile("settings.inc");

----------------------------------------
--          Global Variables          --
----------------------------------------
hotkeyTaskNames = {"Jug", "Clay Motar", "Cookpot"};
dropdown_values = {"Shift Key", "Ctrl Key", "Alt Key", "Mouse Wheel Click"};
total_delay_time = 72000;
dropdown_cur_value = 1;

window_w = 235;
window_h = 125;

askText = "Mould Jugs, Clay Mortars and Cookpots\n\nSelect from either a pinned window configuration "
.. "or mouse movement hotkeys.";

wmText = "Tap Ctrl on pottery wheels to open and pin.\nTap Alt on pottery wheels to open, pin and stash.";
----------------------------------------

function doit()
	askForWindow(askText);
	promptParameters();
	if pinnedMode then
		windowManager("Pottery Wheel Setup", wmText, false, true, window_w, window_h, nil, 20, 25);
		sleepWithStatus(500, "Starting... Don\'t move mouse!");
		unpinOnExit(start);
	elseif hotkeyMode then
    getPoints();
		clickSequence();
  end
end

function start()
	for i=1, potteryPasses do
		-- refresh windows
		refreshWindows();
		lsSleep(500);
			if jug then
				clickAllText("Jug");
			elseif mortar then
				clickAllText("Mortar");
			elseif cookpot then
				clickAllText("Cookpot");
			end
		lsSleep(500);
		closePopUp();  --If you don't have enough clay in your inventory, then a popup will occur.
		checkMaking();
	end
	lsPlaySound("Complete.wav");
end

function promptParameters()
  scale = 1.1;
  local z = 0;
  local is_done = nil;
  -- Edit box and text display
  while not is_done do
    -- Make sure we don't lock up with no easy way to escape!
    checkBreak();
    local y = 40;
    lsSetCamera(0,0,lsScreenX*scale,lsScreenY*scale);
	    if pinnedMode and not hotkeyMode then
				potteryPasses = readSetting("potteryPasses",potteryPasses);
				lsPrint(10, y-30, z, scale, scale, 0xffffffff, "Passes:");
				is_done, potteryPasses = lsEditBox("potteryPasses", 100, y-28, z, 50, 30, scale, scale,
											   0x000000ff, potteryPasses);
					if not tonumber(potteryPasses) then
					  is_done = false;
					  lsPrint(160, y-25, z+10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
					  potteryPasses = 1;
					end
				writeSetting("potteryPasses",tonumber(potteryPasses));
				y = y + 35;
				lsPrintWrapped(10, y-25, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
	      "Task Settings\n-------------------------------------------");

				if jug then
					jugColor = 0x80ff80ff;
				else
					jugColor = 0xffffffff;
				end
				if mortar then
					mortarColor = 0x80ff80ff;
				else
					mortarColor = 0xffffffff;
				end
				if cookpot then
					cookpotColor = 0x80ff80ff;
				else
					cookpotColor = 0xffffffff;
				end

				jug = readSetting("jug",jug);
				mortar = readSetting("mortar",mortar);
				cookpot = readSetting("cookpot",cookpot);

				if not mortar and not cookpot then
					jug = CheckBox(10, y+5, z, jugColor, " Mould a Jug",
															 jug, 0.65, 0.65);
					y = y + 15;
				else
					jug = false
				end

				if not jug and not cookpot then
					mortar = CheckBox(10, y+5, z, mortarColor, " Mould a Clay Mortar",
																	mortar, 0.65, 0.65);
					y = y + 15;
				else
					mortar = false
				end

				if not jug and not mortar then
					cookpot = CheckBox(10, y+5, z, cookpotColor, " Mould a Cookpot",
																	cookpot, 0.65, 0.65);
					y = y + 15;
				else
					cookpot = false
				end

				writeSetting("jug",jug);
				writeSetting("mortar",mortar);
				writeSetting("cookpot",cookpot);

				if jug then
					product = "Jug";
				elseif mortar then
					product = "Clay Mortar";
				elseif cookpot then
					product = "Cookpot";
				end
	    else
	      pinnedMode = false;
	    end

    if hotkeyMode and not pinnedMode then
      lsPrint(10, y-25, z, scale, scale, 0xFFFFFFff, "Hotkey:");
      dropdown_cur_value = lsDropdown("ArrangerDropDown", 100, 17, 0, 200, dropdown_cur_value, dropdown_values);
      y = y + 32;

      hotkeyTask = readSetting("hotkeyTask",hotkeyTask);
      lsPrint(10, y-23, z, scale, scale, 0xFFFFFFff, "Task:");
      hotkeyTask = lsDropdown("hotkeyTask", 100, 50, 0, 200, hotkeyTask, hotkeyTaskNames);
      writeSetting("hotkeyTask",hotkeyTask);
      y = y + 32;

			potteryPasses = readSetting("potteryPasses",potteryPasses);
			lsPrint(10, y-23, z, scale, scale, 0xffffffff, "Passes:");
			is_done, potteryPasses = lsEditBox("potteryPasses", 100, y-20, z, 80, 30, scale, scale,
										   0x000000ff, potteryPasses);
				if not tonumber(potteryPasses) then
				  is_done = false;
				  lsPrint(10, y+30, z+10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
				  potteryPasses = 1;
				end
			writeSetting("potteryPasses",tonumber(potteryPasses));
			lsPrintWrapped(10, y+15, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
      "Task Settings\n-------------------------------------------");
      y = y + 62;
			lsPrint(10, y-13, z, 0.8, 0.8, 0xffffffff, "Mouse Movement Delay (ms):");
      is_done, mouseDelay = lsEditBox("mouseDelay", 230, y-15, 0, 50, 30, 1.0, 1.0, 0x000000ff, 100);
      mouseDelay = tonumber(mouseDelay);
	      if not mouseDelay then
	        is_done = false;
	        lsPrint(10, y+22, 10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
	        mouseDelay = 100;
	      end
				if hotkeyTask == 3 then
					y = y + 32;
					lsPrint(10, y-14, z, 0.8, 0.8, 0xffffffff, "Cookpot Hotkey:");
		      is_done, cookpotHotkey = lsEditBox("cookpotHotkey", 140, y-15, 0, 50, 30, 1.0, 1.0, 0x000000ff, 100);
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
			lsPrintWrapped(10, y+15, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
			"Mode Settings\n---------------------------------------");
			y = y + 5;
			pinnedMode = CheckBox(10, y+45, z, pinnedModeColor, " Pinned Window Mode", pinnedMode, 0.65, 0.65);
      writeSetting("pinnedMode",pinnedMode);
		  y = y + 22;
			lsPrint(10, y+50, z, 0.65, 0.65, 0xFFFFFFff, helpText);
			y = y + 22;
			lsPrintWrapped(10, y+50, z+10, lsScreenX - 20, 0.7, 0.7, 0xD0D0D0ff,
		  "Stand where you can reach all tubs with all ingredients on you.");
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
		  "Stand where you can reach all tubs with all ingredients on you.");
    end

	if pinnedMode and potteryPasses ~= 1 then
		if lsButtonText(10, lsScreenY - 30, z, 100, 0x00ff00ff, "Begin") then
			is_done = 1;
    end
    else
    if hotkeyMode and potteryPasses ~= 1 then
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

function checkMaking()
	while 1 do
		refreshWindows();
		srReadScreen();
		wheel = findAllText("Wheel");
		making = findAllText("Mould a " .. product);
			if #making == #wheel then
				break; --We break this while statement because Making is not detect, hence we're done with this round
			end
		sleepWithStatus(999, "Waiting for " .. product .. "s to finish", nil, 0.7, "Monitoring Pinned Window(s)");
	end
end

function refreshWindows()
  srReadScreen();
  this = findAllText("This");
	  for i = 1, #this do
	    clickText(this[i]);
	  end
  lsSleep(100);
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
	    "Set Pottery Wheel Locations (" .. #clickList .. ")");
    local y = 60;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Select camera and zoom level");
    y = y + 20
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "that best fits the pottery wheels in screen.")
    y = y + 20
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Suggest: F8F8 view.")
    y = y + 20
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Lock ATITD screen with Alt+L")
    y = y + 40;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "MAKE SURE CHAT IS MINIMIZED!")
    y = y + 40;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "1) Set all pottery wheel locations:");
    y = y + 20;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Hover mouse, " .. key .. " over each")
    y = y + 20;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "pottery wheel.")
    y = y + 30;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "2) After setting all pottery wheel locations:")
    y = y + 20;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Click Start to begin checking pottery wheels.")

    if #clickList >= 1 then -- Only show start button if one or more pottery wheel was selected.
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
	startTime = lsGetTimer();
		for l=1, potteryPasses do
			for i=1,#clickList do
        checkBreak();
        srSetMousePos(clickList[i][1], clickList[i][2]);
        lsSleep(150); -- ~65+ delay needed before the mouse can actually move.
        MakeProduct();
      end
			local time_left = total_delay_time - #clickList * mouseDelay;
			lsSleep(100);
			closePopUp(); -- Screen clean up
			sleepWithStatus(time_left,"Pass " .. l .. " of " .. potteryPasses .. "\nWaiting for jugs to finish");
	end
  lsPlaySound("Complete.wav");
  lsMessageBox("Elapsed Time:", getElapsedTime(startTime), 1);
end

function MakeProduct()
  checkBreak();
  closePopUp(); -- Screen clean up
		if hotkeyTask == 1 then
			product = "Jug"
		  srKeyEvent('j'); -- Mould a Jug [J]
		elseif hotkeyTask == 2 then
			product = "Clay Mortar"
			srKeyEvent('m'); -- Mould a Clay Mortar [M]
		elseif hotkeyTask == 3 then
			product = "Cookpot"
			srKeyEvent(cookpotHotkey); -- Mould a Cookpot
		end
	closePopUp(); -- Screen clean up
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
