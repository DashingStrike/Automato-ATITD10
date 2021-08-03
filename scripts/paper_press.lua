dofile("common.inc");
dofile("settings.inc");

----------------------------------------
--          Global Variables          --
----------------------------------------
askText = singleLine([[
  Automatically runs many paper presses, adding/removing linen as necessary. Make sure the
  Automato window is in the TOP-RIGHT corner of the screen. 
  \n \nPin Drying Hammocks if you want the macro to dry linen each pass.
  \n \nYou may need to manually adjust Drying Hammock positions if having problems
]])

wmText = "Tap Ctrl on paper presses to open and pin.\nTap Alt on paper presses to open, pin and stash.";
do_dry = readSetting("do_dry",do_dry);

num_loops = readSetting("num_loops",num_loops);
----------------------------------------

function doit()
	askForWindow(askText);
  windowManager("Paper Press Setup", wmText, false, true, 420, 145, nil, 10, 25);
	config();
  askForFocus();
  doPaper();
end

function config()
  scale = 0.8;
  local z = 0;
  local is_done = nil;

	-- Edit box and text display
	while not is_done do
		checkBreak("disallow pause");

		lsPrint(10, 10, z, scale, scale, 0xFFFFFFff, "Configure Paper Making Options:");
		local y = 40;

		num_loops = readSetting("num_loops",tonumber(num_loops));
		lsPrint(10, y, z, scale, scale, 0xffffffff, "Passes:");
		is_done, num_loops = lsEditBox("num_loops", 100, y, z, 50, 30, scale, scale,
									   0x000000ff, num_loops);
		if not tonumber(num_loops) then
		  is_done = false;
		  lsPrint(10, y+30, z+10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
		  num_loops = 1;
		end
		writeSetting("num_loops",tonumber(num_loops));
		y = y + 35;

		do_dry = CheckBox(10, y, z, 0xFFFFFFff, " Dry linen?", do_dry, 0.65, 0.65);
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


function refreshWindows()
  srReadScreen();
  this = findAllText("This is");
    for i=1,#this do
      clickText(this[i]);
    end
  lsSleep(150);
end

function dryLinen()
    refreshWindows();
    srReadScreen();
		racks = findAllText("Dry Wet Linen");
		for j=1, #racks do
      clickText(racks[j]);
      lsSleep(200);
      clickMax();
      lsSleep(100);
    end
    sleepWithStatus(200000,"Waiting for Linen to dry...", nil, 0.7);
    refreshWindows();
	  clickAllText("Take");
    lsSleep(100);
	  clickAllText("Everything");
	  lsSleep(50);
    refreshWindows();
end

function doPaper()
	for i=1, num_loops do

		-- refresh windows
		refreshWindows();
		lsSleep(200);
    makePaper(1);
		sleepWithStatus(75000, "[" .. i .. "/" .. num_loops .. "] Waiting for 1st batch of paper to finish", nil, 0.7);
    makePaper(2);
		sleepWithStatus(75000, "[" .. i .. "/" .. num_loops .. "] Waiting for 2nd batch of paper to finish", nil, 0.7);
    removeWetLinen();
    lsSleep(200);
    if do_dry then
      dryLinen();
    end
	end
end

function makePaper(make_num)
	if make_num == 1 then
		clickAllText("Line the press with Linen");
		lsSleep(200);

		clickAllText("Make some papyrus paper");
		lsSleep(200);
	else
		clickAllText("Make some papyrus paper");
		lsSleep(200);
	end;
end

function removeWetLinen()
		clickAllText("Remove the Linen from the press");
		lsSleep(200);

		clickAllText("Take...");
		lsSleep(200);

		clickAllText("Everything");
		lsSleep(200);
end