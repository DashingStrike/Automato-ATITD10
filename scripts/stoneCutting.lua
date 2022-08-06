-- stoneCutting.lua v1.1
-- by Rhaom - v1.0 added September 13, 2019
-- Merged rockSaw.lua & masonsBench.lua into a single script
-- Tribisha July 23, 2021: Added option to take all after each pass.
-- MacPhisto - v1.1 - June 21, 2022: Added hotkey mode.


dofile("common.inc");
dofile("settings.inc");

----------------------------------------
--          Global Variables          --
----------------------------------------
buildings = {"Rock Saw", "Mason's Bench"};

-- The timings are set to 30s less than amount of minutes the item should take to complete in 'real time'.
-- The first building started will be watched and the timer should run out before it is actually finished.
-- The macro will then check that building every second until it finishes.
buildingOptions = {
	{ -- Rock Saw
		tasks = {"Flystones", "Pulley", "Cut Stone"},
		hotkeys = {'F', 'P', 'C'},
		timings = {330000, 570000, 150000},
		resources = {'Medium Stone', 'Cuttable Stone', 'Cuttable Stone'}
	},
	{
		tasks = {"Small Stone Block", "Crucible", "Nail Mould"},
		hotkeys = {'B', 'C', 'N'},
		timings = {270000, 570000, 390000},
		resources = {'Medium Stones', 'Medium Stones', 'Medium Stones'}
	}
};
selector_values = {"Shift Key", "Ctrl Key", "Alt Key", "Mouse Wheel Click"};
selector_cur_value = 1;

arrangeWindows = true;
askText = "Stone cutting v1.0 - by Rhaom" ..
"\n\nMerged functionality from rockSaw.lua and masonsBench.lua into a single stoneCutting script." ..
"\n\nPin up windows manually or use the Arrange Windows option to pin/arrange windows." ..
"\n\nv1.1 - MacPhisto - Hotkey Mode!!";

-------------------------------------------------------------------------------
function doit()
	askForWindow(askText);
	setup();
	if pinnedMode then
		windowManager(nil, nil, false, false, nil, nil, nil, 10, 25);
		sleepWithStatus(500, "Starting... Don\'t move mouse!");		
		unpinOnExit(startPinned);
	elseif hotkeyMode then
    	getPoints();
		startHotkey();
  	end
end

function setup()
	scale = 1.1;
	local z = 0;
	local is_done = nil;
	-- Edit box and text display
	while not is_done do
		-- Make sure we don't lock up with no easy way to escape!
		checkBreak("disallow pause");		
		lsSetCamera(0,0,lsScreenX*scale,lsScreenY*scale);
		local y = 7;
		y = drawModeUI(y, z);

		if pinnedMode and not hotkeyMode then 
			is_done, y = drawPinnedUI(y, z, is_done);
		elseif hotkeyMode and not pinnedMode then
			is_done, y = drawHotkeyUI(y, z, is_done);
		end
		
		lsPrintWrapped(10, lsScreenY - 75, z+20, lsScreenX - 20, 0.7, 0.7, 0xD0D0D0ff, "---------------------------------------------------------------");
		lsPrintWrapped(10, lsScreenY - 60, z+20, lsScreenX - 20, 0.75, 0.75, 0xD0D0D0ff, "Stand where you can reach all buildings!")
		if pinnedMode and passCount ~= 1 and (rockSawConfigured or masonBenchConfigured) then
			if lsButtonText(10, lsScreenY - 30, z+20, 100, 0x00ff00ff, "Begin") then
				is_done = 1;
			end
		elseif hotkeyMode and (passCount ~= nil and passCount > 0) then
			if lsButtonText(10, lsScreenY - 30, z+20, 100, 0x00ff00ff, "Next") then
				is_done = 1;				
			end
		end
	
		if lsButtonText(lsScreenX - 110, lsScreenY - 30, z+20, 100, 0xFF0000ff, "End script") then
			error "Clicked End Script button";
		end
		
		lsDoFrame();
		lsSleep(tick_delay);
	end
end

function drawModeUI(y, z)
	local pinnedModeColor = 0xffffffff;
	local hotkeyModeColor = 0xffffffff;
	local helpText = "Check Hotkey or Pinned Mode to Begin"
	pinnedMode = readSetting("pinnedMode",pinnedMode);
	hotkeyMode = readSetting("hotkeyMode",hotkeyMode);

	if pinnedMode then
		pinnedModeColor = 0x80ff80ff;
		helpText = "Uncheck to switch to Hotkey Mode"
	elseif hotkeyMode then
		hotkeyModeColor = 0x80ff80ff;
		helpText = "Uncheck to switch to Pinned Mode"
	end

	if not pinnedMode and not hotkeyMode then
		lsPrintWrapped(10, y, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff, "Mode Settings\n---------------------------------------");
		y = y + 28;
		pinnedMode = CheckBox(10, y, z, pinnedModeColor, " Pinned Window Mode", pinnedMode, 0.65, 0.65);
		writeSetting("pinnedMode",pinnedMode);
		y = y + 22;
		hotkeyMode = CheckBox(10, y, z, hotkeyModeColor, " Hotkey Mode", hotkeyMode, 0.65, 0.65);
		writeSetting("hotkeyMode",hotkeyMode);
		y = y + 28;
		lsPrint(10, y, z, 0.65, 0.65, 0xFFFFFFff, helpText);
	elseif pinnedMode and not hotkeyMode then
		lsPrintWrapped(10, y, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff, "Mode Settings\n---------------------------------------");
		y = y + 28;
		pinnedMode = CheckBox(10, y, z, pinnedModeColor, " Pinned Window Mode", pinnedMode, 0.65, 0.65);
		writeSetting("pinnedMode",pinnedMode);
		y = y + 22;
		lsPrint(10, y, z, 0.65, 0.65, 0xFFFFFFff, helpText);
	elseif hotkeyMode and not pinnedMode then
		lsPrintWrapped(10, y, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff, "Mode Settings\n---------------------------------------");
		y = y + 28;
		hotkeyMode = CheckBox(10, y, z, hotkeyModeColor, " Hotkey Mode", hotkeyMode, 0.65, 0.65);
		writeSetting("hotkeyMode",hotkeyMode);
		pinnedMode = false;
		writeSetting("pinnedMode",pinnedMode);
		y = y + 22;
		lsPrint(10, y, z, 0.65, 0.65, 0xFFFFFFff, helpText);							
	end	

	return y + 28; 
end

function drawPinnedUI(y, z, is_done)
	checkBreak("disallow pause");

	lsPrintWrapped(10, y, z+10, lsScreenX - 20, 0.7, 0.7, 0xffff40ff, 
		"Global Settings\n-------------------------------------------");
	y = y + 35;

	passCount = readSetting("passCount",tonumber(passCount));
    lsPrint(15, y, z, scale, scale, 0xffffffff, "Passes :");
    is_done, passCount = lsEditBox("passCount", 110, y, z, 50, 30, scale, scale, countColor or 0x000000ff, passCount);
	passCount = tonumber(passCount);
    if not passCount then
		countColor = 0xFF2020ff;
      	is_done = false;      	
	  	lsPrint(153, y-3, z+10, 1.3, 1.3, countColor, "!");
	  	lsPrint(165, y+4, z+10, 0.65, 0.65, countColor, "MUST BE A NUMBER");
      	passCount = 1;
	else
		countColor = 0x000000ff;
    end
    writeSetting("passCount",passCount);
    
	y = y + 28;
	takeAll = readSetting("takeAll",takeAll);
	takeAll = CheckBox(30, y, z, 0xFFFFFFff, "Take all after each pass", takeAll, 0.65, 0.65);
	writeSetting("takeAll",takeAll);
	y = y + 28;

	lsPrintWrapped(10, y, z+10, lsScreenX - 20, 0.7, 0.7, 0xffff40ff, 
		"Product Settings\n-------------------------------------------");
	y = y + 35;
	rockSaw = readSetting("rockSaw",rockSaw);
	masonBench = readSetting("masonBench",masonBench);
	if not masonBench then
	  rockSaw = CheckBox(15, y, z+10, 0xFFFFFFff, "Cut stones on a Rocksaw", rockSaw, 0.65, 0.65);
	  writeSetting("rockSaw",rockSaw);
	  writeSetting("nailmould",false);
	  writeSetting("crucible",false);
	  writeSetting("stoneblock",false);
	  y = y + 22;
	end

	if not rockSaw then
	  masonBench = CheckBox(15, y, z+10, 0xFFFFFFff, "Cut stones on a Masons Bench", masonBench, 0.65, 0.65);
	  writeSetting("masonBench",masonBench);
	  writeSetting("cutstone",false);
	  writeSetting("flystone",false);
	  writeSetting("pulley",false);
	  y = y + 22;
	end

    if cutstone then 
      cutstoneColor = 0x80ff80ff;
    else
      cutstoneColor = 0xffffffff;
    end
    if flystone then
      flystoneColor = 0x80ff80ff;
    else
      flystoneColor = 0xffffffff;
    end
    if pulley then
      pulleyColor = 0x80ff80ff;
    else
      pulleyColor = 0xffffffff;
    end
	if nailmould then
      nailmouldColor = 0x80ff80ff;
    else
      nailmouldColor = 0xffffffff;
    end
    if crucible then
      crucibleColor = 0x80ff80ff;
    else
      crucibleColor = 0xffffffff;
    end
    if stoneblock then
      stoneblockColor = 0x80ff80ff;
    else
      stoneblockColor = 0xffffffff;
    end

    nailmould = readSetting("nailmould",nailmould);
    crucible = readSetting("crucible",crucible);
    stoneblock = readSetting("stoneblock",stoneblock);
    cutstone = readSetting("cutstone",cutstone);
    flystone = readSetting("flystone",flystone);
    pulley = readSetting("pulley",pulley);

	if rockSaw then
		if not flystone and not pulley then
		  cutstone = CheckBox(25, y, z+10, cutstoneColor, " Make Cut Stones from Cuttable Stone",
							   cutstone, 0.65, 0.65);
		  y = y + 25;
		else
		  cutstone = false
		end

		if not cutstone and not pulley then
		  flystone = CheckBox(25, y, z+10, flystoneColor, " Make a Pair of Flystones from Med Stone",
								  flystone, 0.65, 0.65);
		  y = y + 25;
		else
		  flystone = false
		end

		if not cutstone and not flystone then
		  pulley = CheckBox(25, y, z+10, pulleyColor, " Make a Pulley from Cuttable Stone",
								  pulley, 0.65, 0.65);
		  y = y + 25;
		else
		  pulley = false;
		end
	end

	if masonBench then
		if not crucible and not stoneblock then
		  nailmould = CheckBox(25, y, z+10, nailmouldColor, " Cut a Medium Stone into a Nail Mould",
							   nailmould, 0.65, 0.65);
		  y = y + 25;
		else
		  nailmould = false
		end

		if not nailmould and not stoneblock then
		  crucible = CheckBox(25, y, z+10, crucibleColor, " Cut a Medium Stone into a Crucible",
								  crucible, 0.65, 0.65);
		  y = y + 25;
		else
		  crucible = false
		end

		if not nailmould and not crucible then
		  stoneblock = CheckBox(25, y, z+10, stoneblockColor, " Cut a Medium Stone into a Small Stone Block",
								  stoneblock, 0.65, 0.65);
		  y = y + 25;
		else
		  stoneblock = false;
		end
	end

    writeSetting("nailmould",nailmould);
    writeSetting("crucible",crucible);
    writeSetting("stoneblock",stoneblock);
    writeSetting("cutstone",cutstone);
    writeSetting("pulley",pulley);
    writeSetting("flystone",flystone);

    if nailmould then
      product = "Nail Moulds";
    elseif crucible then
      product = "Crucibles";
    elseif stoneblock then
      product = "Small Stone Blocks";
    elseif cutstone then
      product = "Cut Stones";
    elseif flystone then
      product = "Pair Flystones";
    elseif pulley then
      product = "Pulleys";
    end

	rockSawConfigured = rockSaw and (cutstone or flystone or pulley);
	masonBenchConfigured = masonBench and (nailmould or crucible or stoneblock);

	return is_done, y;
end

function drawHotkeyUI(y, z, is_done)
	checkBreak("disallow pause");
	lsPrintWrapped(10, y, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff, "Task Settings\n-------------------------------------------");
	
	y = y + 32;
	building = readSetting("building",building);
	lsPrint(10, y, z, scale, scale, 0xFFFFFFff, "Building:");
	building = lsDropdown("building", 100, y, z, 200, building, buildings);
	writeSetting("building",building);
	if lastBuilding ~= building then
		lastBuilding = building;
		lastTask = nil;
	end
	
	y = y + 28;
	hotkeyTask = readSetting("hotkeyTask",hotkeyTask);
	lsPrint(10, y, z, scale, scale, 0xFFFFFFff, "Product:");
	hotkeyTask = lsDropdown("hotkeyTask", 100, y, z, 200, hotkeyTask, buildingOptions[building].tasks);
	writeSetting("hotkeyTask",hotkeyTask);
	if lastTask ~= hotkeyTask then
		lastTask = hotkeyTask;
		hotkey = buildingOptions[building].hotkeys[hotkeyTask]
	end
	
	y = y + 32;
	passCount = readSetting("passCount",tonumber(passCount));
	lsPrint(10, y, z, scale, scale, 0xffffffff, "Passes:");
	is_done, passCount = lsEditBox("passCount", 100, y, z, 50, 30, scale, scale, countColor or 0x000000ff, passCount);
	passCount = tonumber(passCount);
	if not passCount or passCount == 0 then
		countColor = 0xFF2020ff;
		is_done = false;
		lsPrint(143, y-3, z+10, 1.3, 1.3, countColor, "!");
		lsPrint(155, y+4, z+10, 0.65, 0.65, countColor, "MUST BE A NUMBER");
	else
		countColor = 0x000000ff;
	end
	writeSetting("passCount",passCount);
	
	y = y + 28;
	takeAll = readSetting("takeAll",takeAll);
	takeAll = CheckBox(25, y, z+10, 0xFFFFFFff, "Take all after each pass", takeAll, 0.65, 0.65);
	writeSetting("takeAll",takeAll);	
	
	y = y + 28;
	lsPrintWrapped(10, y, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff, "Hotkey Settings\n---------------------------------------");
	
	y = y + 28;
	lsPrint(10, y, z, scale, scale, 0xFFFFFFff, "Selector:");
	selector_cur_value = lsDropdown("ArrangerDropDown", 100, y, z, 200, selector_cur_value, selector_values);	

	y = y + 28;
	lsPrint(10, y, z,scale, scale, 0xffffffff, "Hotkey:");		
	is_done, hotkey = lsEditBox(buildingOptions[building].tasks[hotkeyTask].."_hotkey", 100, y, 0, 30, 30, 0.8, 0.8, 0x000000ff, hotkey);

	y = y + 28;
	lsPrint(10, y, z, 0.8, 0.8, 0xffffffff, "Mouse Movement Delay (ms):");
	is_done, mouseDelay = lsEditBox("mouseDelayHotkey", 230, y-3, z, 60, 30, 0.8, 0.8, delayColor or 0x000000ff, 100);
	mouseDelay = tonumber(mouseDelay);
	if not mouseDelay then
		delayColor = 0xFF2020ff;
		is_done = false;
		lsPrint(283, y-5, z+10, 1.3, 1.3, delayColor, "!");
		lsPrint(290-120, y-20, z+10, 0.65, 0.65, delayColor, "MUST BE A NUMBER");		
	else 
		delayColor = 0x000000ff;
	end


	return is_done, y;
end

-- Pinned Mode --
function startPinned()
	--sleepWithStatus(2000, product)
	for i=1, passCount do
		-- refresh windows
		message = "Refreshing"
		refreshWindows();
		lsSleep(500);

		message = "Clicking " .. product;

		if cutstone then
				clickAllText("Cut Stone");
			elseif flystone then
				clickAllText("Flystones");
			elseif pulley then
				clickAllText("Pulley");
			elseif nailmould then
				clickAllText("Nail Mould");
			elseif crucible then
				clickAllText("Crucible");
			elseif stoneblock then
				clickAllText("Small Stone Block");
		end

		lsSleep(500);
		closePopUp();  --If you don't have enough cuttable stones in inventory, then a popup will occur.
		checkMaking();
	end
	lsPlaySound("Complete.wav");
end

function refreshWindows()
    srReadScreen();
    this = findAllText("This");
    for i = 1, #this do
        clickText(this[i]);
    end
    lsSleep(100);
end

function checkMaking()
			while 1 do
				refreshWindows();
				srReadScreen();
				making = findAllText("Making")
					if #making == 0 then
						if(takeAll) then
					    	clickAllText("Take");
			        		lsSleep(100);
			        		clickAllText("Everything");
  			      			lsSleep(50);
			      		end
						break; --We break this while statement because Making is not detect, hence we're done with this round
					end
				sleepWithStatus(999, "Waiting for " .. product .. " to finish", nil, 0.7, "Monitoring Pinned Window(s)");
			end
end
-- Pinned Mode --

-- Hotkey Mode --
function getPoints()
	clickList = {};
	  local was_shifted = lsShiftHeld();
	
	  if (selector_cur_value == 1) then
	  was_shifted = lsShiftHeld();
	  key = "tap Shift";
	  elseif (selector_cur_value == 2) then
	  was_shifted = lsControlHeld();
	  key = "tap Ctrl";
	  elseif (selector_cur_value == 3) then
	  was_shifted = lsAltHeld();
	  key = "tap Alt";
	  elseif (selector_cur_value == 4) then
	  was_shifted = lsMouseIsDown(2); --Button 3, which is middle mouse or mouse wheel
	  key = "click MWheel ";
	  end
	
	  local is_done = false;
	  local z = 0;
	  while not is_done do
		mx, my = srMousePos();
		local is_shifted = lsShiftHeld();
	
		if (selector_cur_value == 1) then
		  is_shifted = lsShiftHeld();
		elseif (selector_cur_value == 2) then
		  is_shifted = lsControlHeld();
		elseif (selector_cur_value == 3) then
		  is_shifted = lsAltHeld();
		elseif (selector_cur_value == 4) then
		  is_shifted = lsMouseIsDown(2); --Button 3, which is middle mouse or mouse wheel
		end
	
		if is_shifted and not was_shifted then
		  clickList[#clickList + 1] = {mx, my};
		  lsPlaySound("beepping.wav");
		end
		was_shifted = is_shifted;
		checkBreak();
		lsPrint(10, 10, z, 0.7, 0.7, 0xFFFFFFff, "Set ".. buildings[building] .." Locations (" .. #clickList .. ")");

		 		
		verify = readSetting("verify",verify);
		verify = CheckBox(25, 28, z+10, verifyColor or 0xFFFFFFff, "Verify Locations before starting", verify, 0.7, 0.7);
		writeSetting("verify",verify);
		
		if (verify) then verifyColor = 0x80FF80ff; 
		else verifyColor = 0xFFFFFFff; 
		end

		local y = 60;
		lsPrintWrapped(5, y, z, lsScreenX-5, 0.6, 0.6, 0xf0f0f0ff, "Select camera and zoom level " ..
		"that best fits the " .. buildings[building] .. "s in screen.");
		y = y + 30
		lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Suggest: F8F8 view.");
		y = y + 15
		lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Lock ATITD screen with Alt+L");
		
		y = y + 30;
		lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "1) Set " .. buildings[building] .. " locations:");
		y = y + 15;
		lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Hover mouse, " .. key .. " over each " .. buildings[building] .. ".");
		
		y = y + 30;
		lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "2) After setting all locations:");
		y = y + 15;
		lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Click Start to begin!");
		if (verify) then
			y = y + 15;
			lsPrintWrapped(5, y, z, lsScreenX-5, 0.6, 0.6, 0xf0f0f0ff, "All locations you selected will be tested to verify that " ..
			"they are located correctly on a valid building. " ..
			"Any invalid locations will prompt for an update.")		
			y = y + 45;
			lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Once each location is valid the macro will start!");
		end

		y = y + 30;
		lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "3) During macro operation:");
		y = y + 15;
		lsPrintWrapped(5, y, z, lsScreenX-5, 0.6, 0.6, 0xf0f0f0ff, "Chat must be minimized during the time commands " ..	
			"are being sent to the buildings. The macro is smart enough to know that the chat is not minimized " ..
			"and will wait for you minimize it before continuing.");


		if #clickList >= 1 then -- Only show start button if one or more pottery wheel was selected.
		  	if lsButtonText(10, lsScreenY - 30, z, 100, 0xFFFFFFff, "Start") then				
				is_done = 1;
		  	end
		end
	
		if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff, "End script") then
		  error "Clicked End Script button";
		end
	
		lsDoFrame();
		lsSleep(50);
	  end	  

	  if (verify) then verifyPoints(); end
end

function verifyPoints()
	local counter = 1;
	for i=1,#clickList do
		statusScreen("Verifying Location " .. counter .. " / " .. #clickList .. " Remaining",nil, nil, 0.7);
		checkBreak();
		while (not isValidBuilding(i)) do 
			lsPlaySound("fail.wav");			
			resetPoint(i);
			sleepWithStatus(1500, "New location will be verified and the macro will continue. Don't touch the mouse!", nil, 0.7, "Don't touch the mouse!");
		end
		counter = counter + 1
		lsSleep(100);
	end
end

function startHotkey()
	local product = buildingOptions[building].tasks[hotkeyTask];
	local startTime = lsGetTimer();
	for l=1, passCount do
		-- Make sure talking to other people doesn't break everything!
		while (not isChatMinimized()) do
			sleepWithStatus(999, "Paused while waiting for you to minimize your chat...", nil, 0.7, "Waiting on chat!");
		end

		local counter = 1;
		for i=1,#clickList do
			statusScreen("Processsing Task\n\n" .. counter .. " / " .. #clickList .. " Remaining",nil, nil, 0.7);
	        checkBreak();
	        srSetMousePos(clickList[i][1], clickList[i][2]);
	        lsSleep(150); -- ~65+ delay needed before the mouse can actually move.
	        sendCommands();
			counter = counter + 1
	    end
				
		local time_left = buildingOptions[building].timings[hotkeyTask] - #clickList * mouseDelay;
		lsSleep(100);
		closePopUp(); -- Screen clean up

		watchProgress(time_left, l, product);
	end
	
	lsPlaySound("Complete.wav");
	lsMessageBox("Elapsed Time:", getElapsedTime(startTime), 1);
end
	
function sendCommands() 
	checkBreak();
	
	if (takeAll) then
		srKeyEvent('t');
		lsSleep(50)
	end
	print("Sending: " .. hotkey);
	srKeyEvent(hotkey);
	lsSleep(50);

	closePopUp();
end

function watchProgress(time_left, currentPass, product)
	checkBreak();
	
	openAndPin(clickList[1][1], clickList[1][2], 3000);
	print("Finding: This is [-A-Za-z]+ " .. buildings[building]);
	local win = findText("This is [-A-Za-z]+ " .. buildings[building], nil, REGION + REGEX);
	--print(dump(win));

	local  finished = false;
	while not finished do		
		sleepWithStatus(time_left,"Pass " .. currentPass .. " of " .. passCount .. "\nWaiting for " .. product .. "s to finish"); 
		safeClick(clickList[1][1]+5, clickList[1][2]+5);
		srReadScreen();
		if findText("Making", win) then
			-- The building is still working. We're going to recheck every second now
			time_left = 1000;
			lsSleep(100);			
		else
			-- The first building has finished.
			finished = true;
			safeClick(clickList[1][1]+5, clickList[1][2]+5, 1);

			-- We're going to wait a tiny bit so we don't overtake the buildings that are still running
			-- when we start sending commands to the buildings again!
			sleepWithStatus(2500,"Reticulating Splines..."); 
		end
	end	
end

function isChatMinimized()
	srReadScreen();
	local min = srFindImage("chat/chat_min.png");

	if (min) then 
		return true; 
	end

	return (false);
end

function isValidBuilding(i) 
	local result = false;
	local region = {};
	region[0] = clickList[i][1]+5;
	region[1] = clickList[i][2]+5;
	region[2] = 220;
	region[3] = 90;
	local searchBox = regionToBox(region);

	srClickMouse(clickList[i][1], clickList[i][2], 1);
	if (not waitForImage("ThisIs.png", 2000) and not findText(buildings[building], searchBox)) then
		result = false;
	else 
		result = true;
	end
	safeClick(clickList[i][1]-5, clickList[i][2]-5);	

	return result;
end

function resetPoint(index)
	local was_shifted = lsShiftHeld();
	
	if (selector_cur_value == 1) then
	was_shifted = lsShiftHeld();
	key = "tap Shift";
	elseif (selector_cur_value == 2) then
	was_shifted = lsControlHeld();
	key = "tap Ctrl";
	elseif (selector_cur_value == 3) then
	was_shifted = lsAltHeld();
	key = "tap Alt";
	elseif (selector_cur_value == 4) then
	was_shifted = lsMouseIsDown(2); --Button 3, which is middle mouse or mouse wheel
	key = "click MWheel ";
	end
  
	local is_done = false;
	local z = 0;
	while not is_done do
	  mx, my = srMousePos();
	  local is_shifted = lsShiftHeld();
  
	  if (selector_cur_value == 1) then
		is_shifted = lsShiftHeld();
	  elseif (selector_cur_value == 2) then
		is_shifted = lsControlHeld();
	  elseif (selector_cur_value == 3) then
		is_shifted = lsAltHeld();
	  elseif (selector_cur_value == 4) then
		is_shifted = lsMouseIsDown(2); --Button 3, which is middle mouse or mouse wheel
	  end
  
	  if is_shifted and not was_shifted then
		clickList[index] = {mx, my};
		is_done = 1;
	  end
	  was_shifted = is_shifted;
	  checkBreak();
	  lsPrint(10, 10, z, 0.7, 0.7, 0xFFFFFFff, "Reset Location of ".. buildings[building] .." (" .. index .. ")");

	  local y = 60;
	  lsPrintWrapped(10, y, z, lsScreenX-10, 0.7, 0.7, 0xf0f0f0ff, "The mouse position might already be close to the invalid location. " ..
	  "Align the mouse with " .. buildings[building] .. " (" .. index..") and " .. key .. "!");


	  if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff, "End script") then
		error "Clicked End Script button";
	  end
  
	  lsDoFrame();
	  lsSleep(50);
	end
end
-- Hotkey Mode


function closePopUp()
	while 1 do
	  srReadScreen()
	  local ok = srFindImage("OK.png")
	  if ok then
		statusScreen("Found and Closing Popups ...", nil, 0.7);
		srClickMouseNoMove(ok[0]+5,ok[1],1);
		lsSleep(100);
	  else
		break;
	  end
	end
end

-- debugging
function dump(o)
	if type(o) == 'table' then
	   local s = '{ '
	   for k,v in pairs(o) do
		  if type(k) ~= 'number' then k = '"'..k..'"' end
		  s = s .. '['..k..'] = ' .. dump(v) .. ','
	   end
	   return s .. '} '
	else
	   return tostring(o)
	end
  end