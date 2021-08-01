dofile("common.inc");

----------------------------------------
--          Global Variables          --
----------------------------------------
water_count = 0;
refill_jugs = 40;
total_harvests = 0;
total_waterings = 0;
click_delay = 0; -- Overide the default of 50 in common.inc libarary.

askText = singleLine([[
Pin 'Plant Wheat' window up for easy access later. Manually plant and pin up any number of wheat beds.
You must be standing with water icon present and 50 water jugs in inventory.
After you manually plant your wheat beds and pin up each window, Press Shift to continue.
]]);
----------------------------------------

function doit()
  askForWindow(askText);
  refillWater() -- Refill jugs if we can, if not don't return any errors.
  tendWheat()
end

function refillWater()
	water_count = 0;
	refill_jugs = 40;
	lsSleep(100);
	srReadScreen();
	findWater = srFindImage("water.png");

	if findWater then
    statusScreen("Refilling water...");
    srClickMouseNoMove(findWater[0]+3,findWater[1]-5);
    lsSleep(500);
    srReadScreen();
    maxButton = srFindImage("max.png");
      if maxButton then
        srClickMouseNoMove(maxButton[0]+3,maxButton[1]+3);
        lsSleep(500);
      end
    end
end

function tendWheat()
  while 1 do
    local windowcount = clickAllImages("ThisIs.png");
      if windowcount == 0 then
        error 'Did not find any pinned windows'
      end
    sleepWithStatus(300, "Searching " .. windowcount .. " windows for Harvest");

  --Search for Harvest windows. Havest and Water will exist at same time in window,
  srReadScreen();
  local harvest = findAllImages("flax/harvest.png");
    if #harvest > 0 then
      total_harvests = total_harvests + #harvest

      --First, click harvest buttons
      for i=#harvest, 1, -1  do
        srClickMouseNoMove(harvest[i][0]+5, harvest[i][1]+3);
        lsSleep(click_delay);
      end

      --Wait a long moment, it takes a while before the window turns blank, to allow a right click to close it.
      sleepWithStatus(2000, "Harvested " .. windowcount .. " windows...");
      clickAllImages("ThisIs.png");  --Refresh windows to make the harvest windows turn blank
      sleepWithStatus(1000, "Refreshing " .. windowcount .. "/Preparing to Close windows...");

      --Right click to close previously harvested windows
      for i=#harvest, 1, -1  do
        srClickMouseNoMove(harvest[i][0]+5, harvest[i][1]+3);  -- Right click the window to close it.
        lsSleep(150);
      end

      srReadScreen();
      local emptyWindow = srFindImage("WindowEmpty.png")
        if emptyWindow then
          clickAllImages("WindowEmpty.png", 50, 20);
          lsSleep(150);
        end
    end

  srReadScreen();
  -- Refresh windows again
  clickAllImages("ThisIs.png");
  sleepWithStatus(300, "Searching " .. windowcount .. " windows for Water");

  -- Search for Water windows.
  srReadScreen();
  local water = findAllImages("wheat/waterWheat.png");
    if #water > 0 then
      for i=1, #water do
        srClickMouseNoMove(water[i][0]+5, water[i][1]+3);
        lsSleep(click_delay);
        water_count = water_count + #water;
        total_waterings = total_waterings + #water;
        refill_jugs = refill_jugs - #water;
      end
    end

	-- When 40+ water jugs has been consumed, Refill the jugs.
    if water_count >= 40 then
      refillWater();
    end
  sleepWithStatus(3000, "----------------------------------------------\nIf you want to plant more"
  .. " wheat Press Alt+Shift to Pause\n\nOR Use Win Manager button to Pause + Arrange Grids\n"
  .. "----------------------------------------------\nWaterings SINCE Jugs Refill: " .. water_count .. "\n"
  .. "Waterings UNTIL Jugs Refill: " .. refill_jugs .. "\n----------------------------------------------\n"
  .. "Total Waterings: " .. total_waterings .. "\nTotal Harvests: " .. total_harvests, nil, 0.7);

  end
end
