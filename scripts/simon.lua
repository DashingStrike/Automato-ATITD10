dofile("common.inc");
dofile("settings.inc");

askText = "Simon v1.13\n\nSets up a list of points and then clicks on them in sequence.\n\nCan optionally add a timer to wait between each pass (ie project takes a few minutes to complete).\n\nOr will watch Stats Timer (red/black) for clicking.";

local is_stats = true;
local clickDelay = 150;
local passDelay = 0;
local refresh = true;
local clickList = readSetting("clickList", {});

local CLICK_POS = 1;
local CLICK_TEXT = 2;
local CLICK_IMG = 3;

local CLICK_ACTIONS = {
  "Position",
  "Text",
  "Image",
};

function setActions()
  local was_held = lsControlHeld();
  local is_done = false;
  local mx = 0;
  local my = 0;
  local z = 0;
  local unique = math.random();
  while not is_done do
    checkBreak();

    mx, my = srMousePos();
    local is_held = lsControlHeld();
    if is_held and not was_held then
      table.insert(clickList, {CLICK_POS, mx, my});
      writeSetting("clickList", clickList)
    end
    was_held = is_held;
    local y = 10;

    lsPrintWrapped(5, y, z, lsScreenX - 20, 0.7, 0.7, 0xFFFFFFff, "To add a positional click,\nhover over the screen and hit Ctrl.");
    y = y + 50;

    local _, text = lsEditBox("text" .. unique, 5, y, 0, lsScreenX - 10, 30, 0.7, 0.7, 0x000000ff, text);
    y = y + 25;
    if lsButtonText(5, y, z, 100, 0xFFFFFFff, "Click Text") then
      table.insert(clickList, {CLICK_TEXT, text});
      writeSetting("clickList", clickList)
      text = "";
      unique = math.random();
    end
    if lsButtonText(lsScreenX - 105, y, z, 100, 0xFFFFFFff, "Click Image") then
      srFindImage(text); --will error if image doesn't exist
      table.insert(clickList, {CLICK_IMG, text});
      writeSetting("clickList", clickList)
      text = "";
      unique = math.random();
    end
    y = y + 40;

    local start = math.max(1, #clickList - 10);
    for i=start, #clickList do
      local line = i .. ") Click " .. CLICK_ACTIONS[clickList[i][1]] .. ": ";
      if clickList[i][1] == CLICK_POS then
        line = line  .. clickList[i][2] .. ", " .. clickList[i][3];
      else
        line = line  .. "'" .. clickList[i][2] .. "'";
      end
      lsPrint(15, y, z, 0.5, 0.5, 0xFFFFFFff, line);
      y = y + 15;
    end

    if #clickList > 0 then
      if lsButtonText(5, lsScreenY - 30, z, 90, 0xFFFFFFff, "Done") then
        is_done = 1;
      end

      if lsButtonText(lsScreenX/2 - 45, lsScreenY - 30, 0, 90, 0xFFFFFFff, "Reset") then
        clickList = {};
      end
    end
    if lsButtonText(lsScreenX - 95, lsScreenY - 30, 0, 90, 0xFFFFFFff, "End script") then
      error(quit_message);
    end
    lsDoFrame();
    lsSleep(10);
  end
end

function promptRun()
  local is_done = false;
  local count = 1;
  local scale = 0.7;
  while not is_done do
    checkBreak();
    local y = 10;

    lsPrint(5, 10, 0, scale, scale, 0xFFFFFFff, "Configure Sequence");
    y = y + 30;

    refresh = readSetting("refresh", refresh);
    lsPrint(5, y, 0, scale, scale, 0xFFFFFFff, "Refresh Windows:");
    refresh = CheckBox(125, y, 10, 0xFFFFFFff, "", refresh, scale, scale);
    writeSetting("refresh", refresh);
    y = y + 20;

    is_stats = readSetting("is_stats", is_stats);
    lsPrint(5, y, 0, scale, scale, 0xFFFFFFff, "Wait for stats:");
    is_stats = CheckBox(125, y, 10, 0xFFFFFFff, "", is_stats, scale, scale);
    writeSetting("is_stats", is_stats);
    y = y + 20;

    count = readSetting("count", count);
    lsPrint(5, y, 0, scale, scale, 0xFFFFFFff, "Passes:");
    is_done, count = lsEditBox("count", 125, y, 0, 75, 30, scale, scale, 0x000000ff, count);
    count = tonumber(count);
    if not count then
      is_done = false;
      lsPrint(125, y + 25, 10, 0.5, 0.5, 0xFF2020ff, "NOT A NUMBER");
      count = 1;
    end
    writeSetting("count", count);
    y = y + 40;

    if not is_stats then
      clickDelay = readSetting("clickDelay",clickDelay);
      lsPrint(5, y, 0, scale, scale, 0xFFFFFFff, "Click Delay (ms):");
      lsPrint(5, y + 20, 0, 0.5, 0.5, 0xFFFFFFff, "Time between clicks");
      is_done, clickDelay = lsEditBox("delay", 125, y, 0, 75, 30, scale, scale, 0x000000ff, clickDelay);
      clickDelay = tonumber(clickDelay);
      if not clickDelay then
        is_done = false;
        lsPrint(125, y + 25, 10, 0.5, 0.5, 0xFF2020ff, "NOT A NUMBER");
        clickDelay = 150;
      end
      writeSetting("clickDelay",clickDelay);
      y = y + 40;

      passDelay = readSetting("passDelay", passDelay);
      lsPrint(5, y, 0, scale, scale, 0xFFFFFFff, "Pass Delay (ms):");
      lsPrint(5, y + 20, 0, 0.5, 0.5, 0xFFFFFFff, "Time between passes");
      is_done, passDelay = lsEditBox("passDelay", 125, y, 0, 75, 30, scale, scale, 0x000000ff, passDelay);
      passDelay = tonumber(passDelay);
      if not passDelay then
        is_done = false;
        lsPrint(125, y + 25, 10, 0.5, 0.5, 0xFF2020ff, "NOT A NUMBER");
        passDelay = 0;
      end

      writeSetting("passDelay", passDelay);
    end

    if #clickList > 0 and lsButtonText(5, lsScreenY - 30, 0, 90, 0x20FF20ff, "Begin") then
      is_done = 1;
    end
    if lsButtonText(lsScreenX / 2 - 45, lsScreenY - 30, 0, 90, 0xFFFFFFff, "Setup") then
      setActions();
    end
    if lsButtonText(lsScreenX - 95, lsScreenY - 30, 0, 90, 0xFFFFFFff, "End script") then
      error(quit_message);
    end
    lsSleep(50);
    lsDoFrame();
  end
  return count;
end

function clickSequence(count)
  local message = "";
  for i=1,count do
    local clickedPoints = {};

    if refresh then
      refreshWindows();
    end

    for j=1, #clickList do
      checkBreak();

      local clickedLine = j .. ") Clicked " .. CLICK_ACTIONS[clickList[j][1]] .. " ";
      if clickList[j][1] == CLICK_POS then
        safeClick(clickList[j][2], clickList[j][3]);
        clickedLine = clickedLine .. clickList[j][2] .. ", " .. clickList[j][3] .. "\n";
      elseif clickList[j][1] == CLICK_TEXT then
        local found = clickAllText(clickList[j][2]);
        clickedLine = clickedLine .. "'" .. clickList[j][2] .. "' " .. found .. " times";
      elseif clickList[j][1] == CLICK_IMG then
        local found = clickAllImages(clickList[j][2]);
        clickedLine = clickedLine .. "'" .. clickList[j][2] .. "' " .. found .. " times";
      end
      table.insert(clickedPoints, clickedLine);

      message = "Pass " .. i .. "/" .. count .. " -- ";
      message = message .. "Clicked " .. j .. "/" .. #clickList .. "\n\n";
      local start = math.max(1, #clickedPoints - 10);
      for i=start, #clickedPoints do
        message = message .. clickedPoints[i] .. "\n";
      end

      if is_stats then
        sleepWithStatus(150, "Waiting between clicks\n" .. message, nil, 0.67);
        closePopUp(); -- Check for lag/premature click that might've caused a popup box (You're too tired, wait xx more seconds)
        waitForStats(message .. "Waiting For Stats");
      else
        sleepWithStatus(clickDelay, "Waiting Click Delay\n" .. message, nil, 0.67);
      end
    end
    --if passDelay > 0 and not is_stats and (i < count) then  --Uncomment so you don't have to wait the full passDelay countdown on last pass; script exits on last pass immediately .
    if passDelay > 0 and not is_stats then -- No need for passDelay timer if it's 0 or we're using Wait for Stats option
      sleepWithStatus(math.floor(passDelay), "Waiting on Pass Delay\n" .. message , nil, 0.67);
    end
  end
  lsPlaySound("Complete.wav");
end

function doit()
  askForWindow(askText);

  local is_done = false;
  while not is_done do
    local count = promptRun();
    if count > 0 then
      askForFocus();
      clickSequence(count);
    else
      is_done = true;
    end
  end
end

function waitForStats(message)
  local stats = findStats();
  while not stats do
    sleepWithStatus(500, message, 0xff3333ff);
    stats = findStats();
  end
end

function findStats()
  srReadScreen();
  local endurance = srFindImage("stats/endurance.png");
  if endurance then
    return false;
  end
  local focus = srFindImage("stats/focus.png");
  if focus then
    return false;
  end
  local strength = srFindImage("stats/strength.png");
  if strength then
    return false;
  end
  return true;
end

function closePopUp()
  srReadScreen()
  local ok = srFindImage("OK.png")
  if ok then
    srClickMouseNoMove(ok[0]+5,ok[1],1);
  end
end

function refreshWindows()
  statusScreen("Refreshing Windows ...", nil, 0.7);
  srReadScreen();
  pinWindows = findAllImages("windowCorner.png", nil, 100);
  for i=1, #pinWindows do
    checkBreak();
    safeClick(pinWindows[i][0] + 5, pinWindows[i][1] + 5);
    lsSleep(100);
  end
  lsSleep(500);
end
