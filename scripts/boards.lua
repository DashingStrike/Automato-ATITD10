-- boards.lua v1.1 -- Revised by Tallow, Rewrite by Manon to also click repair and use mostly OCR.
-- Run a set of Sawmills or Wood Planes to generate boards.
--

dofile("common.inc");
dofile("settings.inc");

function doit()
  promptParameters();
  askForWindow("Open and pin as many Wood Planes as you want to use.\n\nAutomatically planes boards from any number of Wood Plane or Carpentry Shop windows. Will repair the wood planes. Make sure to carry Slate blades!\n\nThe automato window must be in the TOP-RIGHT corner of the screen.\nStand where you can reach all Wood Planes with all ingredients on you.");
  if (arrangeWindows) then
    arrangeInGrid(false, false, 360, 130);
  end
  while not waitForStats() do
    sleepWithStatus(999, "Waiting for black stats window to appear")
    checkBreak()
  end
  while (true) do
    checkBreak();
    closePopUp();
    refreshWindows();
    planeBoardsAuto(); -- Planes Boards
    repairBoards(); -- Repairs Wood Planes
    planeBoards(); -- Planes Boards
  end
end

function promptParameters()
  arrangeWindows = true;
  unpinWindows = true;
  carpShop = true;
  scale = 1.1;

  local z = 0;
  local is_done = nil;
  local value = nil;
  -- Edit box and text display
  while not is_done do
    -- Make sure we don't lock up with no easy way to escape!
    checkBreak();

    local y = 5;

    lsSetCamera(0, 0, lsScreenX * scale, lsScreenY * scale);

    lsPrintWrapped(10, y, z + 10, lsScreenX - 20, 0.7, 0.7, 0xD0D0D0ff,
      "Board Maker V2.0 Rewrite by Manon for T9\n\n");

    carpShop = readSetting("carpShop", carpShop);
    carpShop = lsCheckBox(10, 40, z, 0xFFFFFFff, "Use carpentry shop", carpShop);
    writeSetting("carpShop", carpShop);
    y = y + 32;

    lsPrintWrapped(10, 60, z + 10, lsScreenX - 20, 0.7, 0.7, 0xD0D0D0ff,
      "Will use Carpentry Shops instead of Wood Planes to plane boards.");

    arrangeWindows = readSetting("arrangeWindows", arrangeWindows);
    arrangeWindows = lsCheckBox(10, 100, z, 0xFFFFFFff, "Arrange windows", arrangeWindows);
    writeSetting("arrangeWindows", arrangeWindows);
    y = y + 32;

    lsPrintWrapped(10, 120, z + 10, lsScreenX - 20, 0.7, 0.7, 0xD0D0D0ff,
      "Will sort your pinned Wood Planes or Carpentry Shops into a grid on your screen.");

    unpinWindows = readSetting("unpinWindows", unpinWindows);
    unpinWindows = lsCheckBox(10, 160, z, 0xFFFFFFff, "Unpin windows on exit", unpinWindows);
    writeSetting("unpinWindows", unpinWindows);
    y = y + 32;

    lsPrintWrapped(10, 180, z + 10, lsScreenX - 20, 0.7, 0.7, 0xD0D0D0ff,
      "On exit will close all windows when you close this macro.\n\nPress OK to continue.");

    if lsButtonText(10, (lsScreenY - 30) * scale, z, 100, 0xFFFFFFff, "OK") then
      is_done = 1;
    end

    if lsButtonText((lsScreenX - 100) * scale, (lsScreenY - 30) * scale, z, 100, 0xFFFFFFff,
      "End script") then
      error "Clicked End Script button";
    end

    lsDoFrame();
    lsSleep(tick_delay);
  end
  if (unpinWindows) then
    setCleanupCallback(cleanup); -- unpin all open windows
  end
end

function refreshWindows()
  srReadScreen();
  this = findAllText("This is");
  for i = 1, #this do
    clickText(this[i]);
  end
  lsSleep(100);
end

function repairBoards()
  srReadScreen();

  if not carpShop then
    clickrepair = findAllText("Repair this Wood Plane");
  else
    clickrepair = findAllText("Install");
  end

  for i = 1, #clickrepair do
    clickText(clickrepair[i]);
    lsSleep(100);
  end
end
function planeBoardsAuto()
  srReadScreen();

  if carpShop then
    if not found_autoplane_window then
      clickplane = findAllText("Start planing", false, REGION);
      carpentryShop = findAllText("Carpentry Shop")
      if (#carpentryShop < 1) then
        error("Could not any Carpentry Shops.");
      end
      statusScreen("Found " .. #carpentryShop .. " Wood Planes.\n Found " .. #clickplane .. " Start Planing buttons.");
      if #clickplane > 0 then
        found_autoplane_window = clickplane[1]
      end
    end
    if found_autoplane_window then
      if not autoplaning_started then
        local start = find_text_mutliple("start", found_autoplane_window)
        if not start then
          sleepWithStatus(5000, "Lost the auto plane window immediately, picking a new one")
          found_autoplane_window = false
          planeBoardsAuto()
        end
        last_auto_plane_time = lsGetTimer()
        clickText(start)
        lsSleep(100)
        autoplaning_started = true
      else
        srReadScreen()
        local broken = find_text_mutliple("install", found_autoplane_window)
        if broken then
          clickText(broken)
          lsSleep(100)
          srReadScreen()
          local start = find_text_mutliple("start", found_autoplane_window)
          if not start then
            sleepWithStatus(5000, "Lost the auto plane window after repairing, picking a new one")
            found_autoplane_window = false
            planeBoardsAuto()
          end
          clickText(start)
          lsSleep(100)
          autoplaning_started = true
        else
          srReadScreen()
          local start = find_text_mutliple("start", found_autoplane_window)
          if start and (not last_auto_plane_time or (lsGetTimer() - last_auto_plane_time) > 20000) then
            clickText(start)
            lsSleep(100)
            autoplaning_started = true
            last_auto_plane_time = lsGetTimer()
          end
          if not start then
            sleepWithStatus(5000, "Lost the auto plane window whilst running , picking a new one")
            found_autoplane_window = false
            planeBoardsAuto()
          end
        end
      end
    end


  end

  lsSleep(100);

end

function find_text_mutliple(text, box)
  local text_parse = false
  for i = 1, 2 do
    srReadScreen()
    text_parse = findImage("boards/" .. text .. ".png", box)
    sleepWithStatus(100, "Attempt " .. i .. " to find " .. text )
    if text_parse then
      return text_parse
    end
  end
  return false
end

function planeBoards()
  srReadScreen();

  if not carpShop then
    clickplane = findAllText("Plane a piece");
    woodplane = findAllText("Wood Plane")
    if (#woodplane < 1) then
      error("Could not any Wood Planes.");
    end
    statusScreen("Found " .. #woodplane .. " Wood Planes.\nPlaning  " .. #clickplane .. " Boards\nRepaired " .. #clickrepair .. " Wood Planes.");
  else
    clickplane = findAllText("wood into boards");
    carpentryShop = findAllText("Carpentry Shop")
    if (#carpentryShop < 1) then
      error("Could not any Carpentry Shops.");
    end
    statusScreen("Found " .. #carpentryShop .. " Wood Planes.\nRepaired " .. #clickrepair .. " Wood Planes.");
  end

  for i = 1, #clickplane do
    if not waitForStats() then
      statusScreen("Can't see stat's window, stopping manual planing until visible or black again.")
      return
    end
    if not found_autoplane_window or not inside(clickplane[i], found_autoplane_window) then
      print("Clicking " .. i )
      clickText(clickplane[i]);
    else
      print("Skipping " .. i )
    end
  end
  lsSleep(100);

end
function inside(vector, box)
  local x, y = vector[0], vector[1]
  return (x >= box.left and x <= box.right) and (y >= box.top and y <= box.bottom)
end

function waitForStats()
  srReadScreen();
  return srFindImage("statclicks/endurance_black_small.png");
end

function cleanup()
  if (unpinWindows) then
    closeAllWindows();
  end
end

function closePopUp()
  while 1 do
    -- Perform a loop in case there are multiple pop-ups behind each other; this will close them all before continuing.
    checkBreak();
    srReadScreen();
    OK = srFindImage("OK.png");
    if OK then
      srClickMouseNoMove(OK[0] + 2, OK[1] + 2, true);
      lsSleep(100);
    else
      break ;
    end
  end
end
