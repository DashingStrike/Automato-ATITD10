dofile("common.inc");
dofile("settings.inc");

----------------------------------------
--          Global Variables          --
----------------------------------------
askText = singleLine([[
  Automatically runs many paper presses, adding/removing linen/pelt as necessary.
]])

wmText = "Tap Ctrl on paper presses to open and pin.\nTap Alt on paper presses to open, pin and stash.";

paperList = {"Papyrus Paper","Wood Paper"};
do_dry = false;

----------------------------------------

function doit()
	askForWindow(askText);
  windowManager("Paper Press Setup", wmText, false, true, 420, 145, nil, 10, 25);
	config();
  askForFocus();
  doPaper();
end

function config()
  scale = 1.1;
  local z = 0;
  local is_done = nil;

	-- Edit box and text display
	while not is_done do
    -- Make sure we don't lock up with no easy way to escape!
    checkBreak();
    local y = 40;
    paper_passes = readSetting("paper_passes",tonumber(paper_passes));
    lsPrint(10, y-30, z, scale, scale, 0xffffffff, "Passes:");
    is_done, paper_passes = lsEditBox("paper_passes", 115, y-28, z, 50, 30, scale, scale,
                               0x000000ff, paper_passes);
      if not tonumber(paper_passes) then
        is_done = false;
        lsPrint(160, y-25, z+10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
        paper_passes = 1;
      end
    writeSetting("paper_passes",tonumber(paper_passes));
    y = y + 32;

    paperType = readSetting("paperType",paperType);
    lsPrint(10, y-26, 0, scale, scale, 0xffffffff, "Product:");
    paperType = lsDropdown("paperType", 115, y-25, 0, 170, paperType, paperList);
    y = y + 12;
    writeSetting("paperType",paperType);

    lsPrintWrapped(10, y, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
    "Task Settings\n-------------------------------------------");
    y = y + 32;

    do_dry = readSetting("do_dry",do_dry);
    if paperType == 1 then
      do_dry = CheckBox(10, y, z, 0xFFFFFFff, " Automatically dry linen", do_dry, 0.65, 0.65);
      if do_dry then
        lsPrintWrapped(10, y+30, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
        "Pin Drying Hammocks if you want the macro to dry linen each pass.\n\n" ..
        "You may need to manually adjust Drying Hammock positions if having problems.");
      end
    elseif paperType == 2 then
      do_dry = CheckBox(10, y, z, 0xFFFFFFff, " Automatically dry rabbit pelt", do_dry, 0.65, 0.65);
      if do_dry then
        lsPrintWrapped(10, y+30, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
        "Pin Drying Hammocks if you want the macro to dry rabbit pelt each pass.\n\n" ..
        "You may need to manually adjust Drying Hammock positions if having problems.");
      end
    else
      do_dry = false;
    end
    writeSetting("do_dry",do_dry);

      if lsButtonText(10, lsScreenY - 30, z, 100, 0x00ff00ff, "Begin") then
        is_done = 1;
      end

    	if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFF0000ff,
            "End script") then
        error "Clicked End Script button";
      end
	  lsDoFrame();
	  lsSleep(32);
	end
end

function doPaper()
  if paperType == 1 then
    product = "Papyrus Paper"
    productTimer = 75000
  else
    product = "Wood Paper"
    productTimer = 105000
  end

	for i=1, paper_passes do
		-- refresh windows
		refreshWindows();
		lsSleep(200);
    makePaper(1, product);
		sleepWithStatus(productTimer, "[" .. i .. "/" .. paper_passes .. "] Waiting for 1st batch of paper to finish", nil, 0.7);
    makePaper(2, product);
		sleepWithStatus(productTimer, "[" .. i .. "/" .. paper_passes .. "] Waiting for 2nd batch of paper to finish", nil, 0.7);
      if product == "Wood Paper" then
        makePaper(2, product);
        sleepWithStatus(productTimer, "[" .. i .. "/" .. paper_passes .. "] Waiting for 3rd batch of paper to finish", nil, 0.7);
        makePaper(2, product);
        sleepWithStatus(productTimer, "[" .. i .. "/" .. paper_passes .. "] Waiting for 4th batch of paper to finish", nil, 0.7);
        makePaper(2, product);
        sleepWithStatus(productTimer, "[" .. i .. "/" .. paper_passes .. "] Waiting for 5th batch of paper to finish", nil, 0.7);
        makePaper(2, product);
        sleepWithStatus(productTimer, "[" .. i .. "/" .. paper_passes .. "] Waiting for 6th batch of paper to finish", nil, 0.7);
      end
    removeWetPressLining(product);
    lsSleep(200);
    if do_dry then
      dryPressLining(product, lining);
    end
	end
end

function makePaper(make_num, product)
  refreshWindows();

  if make_num == 1 and product == "Papyrus Paper" then
		clickAllText("Line the press with Linen");
		lsSleep(200);

		clickAllText("Make some papyrus paper");
		lsSleep(200);
	elseif make_num == 1 and product == "Wood Paper" then
		clickAllText("Line the press with Rabbit Pelts");
		lsSleep(200);

		clickAllText("Dry wet wood paper");
		lsSleep(200);
  elseif make_num == 2 and product == "Papyrus Paper" then
    clickAllText("Make some papyrus paper");
    lsSleep(200);
  elseif make_num == 2 and product == "Wood Paper" then
    clickAllText("Dry wet wood paper");
    lsSleep(200);
	end
end

function dryPressLining(product, lining)
  if product == "Papyrus Paper" then
    lining = "Linen"
  else
    lining = "Rabbit Pelts"
  end

  refreshWindows();
  srReadScreen();
	racks = findAllText("Dry Wet " .. lining);
  	for j=1, #racks do
      clickText(racks[j]);
      lsSleep(200);
      clickMax();
      lsSleep(100);
    end
  sleepWithStatus(200000,"Waiting for " .. lining .. " to dry...", nil, 0.7);
  refreshWindows();
  clickAllText("Take");
  lsSleep(100);
  clickAllText("Everything");
  lsSleep(50);
  refreshWindows();
end

function removeWetPressLining(product)
  if product == "Papyrus Paper" then
		clickAllText("Remove the Linen from the press");
		lsSleep(200);
  else
    clickAllText("Remove the Rabbit Pelts from the press");
    lsSleep(200);
  end
		clickAllText("Take...");
		lsSleep(200);
		clickAllText("Everything");
		lsSleep(200);
end

----------------------------------------
--         Utility Functions          --
----------------------------------------

function refreshWindows()
  srReadScreen();
  this = findAllText("This is");
    for i=1,#this do
      clickText(this[i]);
    end
  lsSleep(150);
end
