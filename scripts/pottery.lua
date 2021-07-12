dofile("common.inc");
dofile("settings.inc");

unpinWindows = false;
arrangeWindows = true;

askText = "Mould Jugs, Clay Mortars or Cookpots, without the mouse being used.\n\n"
.. "Pin up windows manually or select the arrange windows checkbox.";


function doit()
	askForWindow(askText);
	config();
		if(arrangeWindows) then
			arrangeInGrid(nil, nil, nil, nil,nil, 10, 40);
		end
	start();
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
		closePopUp();  --If you don't have enough cuttable stones in inventory, then a popup will occur.
		checkMaking();
	end
		if(unpinWindows) then
			closeAllWindows();
		end;
	lsPlaySound("Complete.wav");
end

function config()
  scale = 0.8;
  local z = 0;
  local is_done = nil;
	-- Edit box and text display
	while not is_done do
		checkBreak("disallow pause");
		lsPrint(10, 10, z, scale, scale, 0xFFFFFFff, "Configure Pottery Wheel");
		local y = 40;

		potteryPasses = readSetting("potteryPasses",potteryPasses);
		lsPrint(10, y, z, scale, scale, 0xffffffff, "Passes:");
		is_done, potteryPasses = lsEditBox("potteryPasses", 100, y, z, 50, 30, scale, scale,
									   0x000000ff, potteryPasses);
		if not tonumber(potteryPasses) then
		  is_done = false;
		  lsPrint(10, y+30, z+10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
		  potteryPasses = 1;
		end
		writeSetting("potteryPasses",tonumber(potteryPasses));
		y = y + 35;

		arrangeWindows = readSetting("arrangeWindows",arrangeWindows);
		arrangeWindows = CheckBox(10, y, z, 0xFFFFFFff, "Arrange windows", arrangeWindows, 0.65, 0.65);
		writeSetting("arrangeWindows",arrangeWindows);
		y = y + 32;

		unpinWindows = readSetting("unpinWindows",unpinWindows);
		unpinWindows = CheckBox(10, y, z, 0xFFFFFFff, "Unpin windows on exit", unpinWindows, 0.65, 0.65);
		writeSetting("unpinWindows",unpinWindows);
		y = y + 32;

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
		if mortar then
      cookpotColor = 0x80ff80ff;
    else
      cookpotColor = 0xffffffff;
    end

    jug = readSetting("jug",jug);
    mortar = readSetting("mortar",mortar);
		cookpot = readSetting("cookpot",cookpot);

    if not mortar and not cookpot then
      jug = CheckBox(15, y, z+10, jugColor, " Mould a Jug",
                           jug, 0.65, 0.65);
      y = y + 32;
    else
      jug = false
    end

    if not jug and not cookpot then
      mortar = CheckBox(15, y, z+10, mortarColor, " Mould a Clay Mortar",
                              mortar, 0.65, 0.65);
      y = y + 32;
    else
      mortar = false
    end

		if not jug and not mortar then
      cookpot = CheckBox(15, y, z+10, cookpotColor, " Mould a Cookpot",
                              cookpot, 0.65, 0.65);
      y = y + 32;
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

    if jug or mortar or cookpot then
    lsPrintWrapped(15, y, z+10, lsScreenX - 20, 0.7, 0.7, 0xd0d0d0ff,
                   "Uncheck box to see more options!");

      if lsButtonText(10, lsScreenY - 30, z, 100, 0x00ff00ff, "Begin") then
        is_done = 1;
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
		this = findAllText("This");
		making = findAllText("Mould a " .. product);
			if #making == #this then
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
