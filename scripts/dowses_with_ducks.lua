dofile("common.inc");
dofile("settings.inc");

local mapColors = {
  Sand = "DotWh",
  ["Copper Ore"] = "DotOr",
  ["Iron Ore"] = "DotRd",
  ["Tin Ore"] = "DotLb",
  ["Zinc Ore"] = "DotVi",
  ["Aluminum Ore"] = "DotBl",
  ["Lead Ore"] = "DotPk",
};

local formats = {
  "Wiki Map",
  "Dowsemap",
  "Standard"
}

local directions = {
  "Off",
  "North",
  "South",
  "East",
  "West",
}

local lastResult = "";
local status = "";
local format = 1;
local autorun = 0;
local autodowse = 0;
local spacing = 0;
local nearby = false;
local multipleRods = false;
local file = "dowsing.txt"
local currentRod = "";

function getFileName()
  if not multipleRods then
    return file;
  end

  local name, extension = string.match(file, "(.+)%.(.+)$");
  return name .. "_" .. currentRod .. "." .. extension;
end

function writeDowseLog(x, y, region, name, exact)
  if exact then
    status = name .. " at " .. x .. ", " .. y;
  else
    status = name .. " near " .. x .. ", " .. y;
    if not nearby then
      return;
    end
  end

  local color = mapColors[name];
  if not color then
    color = "DotYe";
  end

  if not exact then
    name = name .. " nearby";
  end

  local text;
  if format == 1 then
    text = "(" .. color .. ") " ..
      string.gsub(x, "%.[0-9]+", "") .. "," ..
      string.gsub(y, "%.[0-9]+", "") .. "," ..
      name .. " @ (" .. x .. ", " .. y .. ") " .. region;
  elseif format == 2 then
    text = string.gsub(x, "%.[0-9]+", "") .. "," ..
      string.gsub(y, "%.[0-9]+", "") .. "," ..
      region .. "," ..
      name;
  else
    text = x .. "," ..
      y .. "," ..
      region .. "," ..
      name;
  end

  logfile = io.open(getFileName(),"a+");
  logfile:write(text .. "\n");
  logfile:close();
end

function checkIfMain()
  if not srFindImage("chat/main_chat.png", 7000) then
    return false;
  end

  return true;
end

function getOreFromLine(line)
  local sand = string.match(line, " detect nothing but sand");
  if sand then
    return "Sand";
  end

  local ore = string.match(line, " vein of (%D+) at");
  if not ore then
    ore = string.match(line, " vein of (%D+), somewhere");
  end

  return ore;
end

function getExactFromLine(line)
  return string.match(line, " at ");
end

function getRegionFromLine(line)
  local region = string.match(line, " at (%D+) [-0-9]+");
  if not region then
    region = string.match(line, " nearby (%D+) [-0-9]+");
  end

  return region;
end

function getCoordsFromLine(line)
  local x, y = string.match(line, "([-0-9]+%.[0-9]+) ([-0-9]+%.[0-9]+)");
  if not x then
    return "", "";
  end

  return x, y;
end

function getDowseResult(wait, init)
  srReadScreen();

  local onMain = checkIfMain();
  if not onMain then
    lsPlaySound("boing.wav");
  end
  while not onMain do
    checkBreak();
    srReadScreen();
    sleepWithStatus(100, "Looking for Main chat screen...\n\nMake sure main chat tab is showing.", nil, 0.7);
    onMain = checkIfMain();
  end

  local startTimer = lsGetTimer();
  repeat
    checkBreak();
    srReadScreen();

    local chatText = getChatText();
    while not chatText or not chatText[#chatText] do
      checkBreak();
      srReadScreen();
      sleepWithStatus(100, "Waiting for chat", nil, 0.7);
      chatText = getChatText();
    end

    local secondToLastLine = chatText[#chatText - 1][2];
    local lastLine         = chatText[#chatText][2];

    local x, y = getCoordsFromLine(lastLine);
    if x ~= "" then
      local foundOre  = getOreFromLine(lastLine);
      local exact     = getExactFromLine(lastLine);
      local region    = getRegionFromLine(lastLine);

      local x2 = "";
      local y2 = "";
      if multipleRods then
        x2, y2    = getCoordsFromLine(secondToLastLine);
      end
      local resultKey = table.concat({x,y,x2,y2}, ",");
      if init then
        lastResult = resultKey;
        return;
      end

      if lastResult ~= resultKey then
        lastResult = resultKey;
        writeDowseLog(x , y, region, foundOre, exact);
        switchRods();

        if foundOre ~= "Sand" and (exact or nearby) then
          lsPlaySound("cymbals.wav");
        end
        return;
      end
    end

    if wait then
      local seconds = math.floor(10.5 - (lsGetTimer() - startTimer) / 1000);
      lsPrintWrapped(10, 10, 0, lsScreenX - 20, 0.7, 0.7, 0xFFFFFFff, "Waiting " .. seconds .. "s for new dowsing line in chat.\n\nIf there are 2 (3 with multiple rods enabled) identical dowsing lines (from dowsing in the exact same spot) the macro won't detect them.\n\nJust move to the next spot and wait out the timer.");
      if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFFFFFFff, "Cancel") then
        return;
      end
      lsDoFrame();
    end
    lsSleep(10);
  until lsGetTimer() - startTimer > 10000 or not wait
end

function displayConfig()
  while true do
    checkBreak();

    local y = 5;

    lsPrint(10, y, 0, 0.7, 0.7, 0xB0B0B0ff, "This will write a log file");
    y = y + 25;

    file = readSetting("file", file);
    lsPrint(10, y, 0, 1, 1, 0xFFFFFFff, "File Name:");
    done, file = lsEditBox("file", 130, y, 0, 150, 0, 1, 1, 0x000000ff, file)
    writeSetting("file", file);
    y = y + 35;

    format = readSetting("format", format);
    lsPrint(10, y, 0, 1, 1, 0xFFFFFFff, "Log Format:");
    format = lsDropdown("format", 130, y, 0, 150, format, formats);
    writeSetting("format", format);
    y = y + 35;

    nearby = readSetting("nearby", nearby);
    lsPrint(10, y, 0, 1, 1, 0xFFFFFFff, "Log Nearby:");
    nearby = CheckBox(130, y, 0, 0xFFFFFFff, "", nearby, 1, 1);
    writeSetting("nearby", nearby)
    y = y + 35;

    multipleRods = readSetting("multipleRods", multipleRods);
    lsPrint(10, y, 0, 1, 1, 0xFFFFFFff, "Multi Rods:");
    multipleRods = CheckBox(130, y, 0, 0xFFFFFFff, "", multipleRods, 1, 1);
    writeSetting("multipleRods", multipleRods)
    y = y + 35;

    lsPrint(10, y, 0, 1, 1, 0xFFFFFFff, "Auto Run:");
    autorun = lsDropdown("autorun", 130, y, 0, 150, autorun, directions);
    y = y + 35;

    lsPrint(10, y, 0, 1, 1, 0xFFFFFFff, "Auto Dowse:");
    if autorun > 1 then
      spacing = readSetting("spacing", spacing);
      done, spacing = lsEditBox("spacing", 130, y, 0, 55, 0, 1, 1, 0x000000ff, spacing)
      spacing = tonumber(spacing);
      lsPrint(190, y, 0, 1, 1, 0xFFFFFFff, "coords");
      writeSetting("spacing", spacing);
      autodowse = true;
    else
      lsPrint(10, y, 0, 1, 1, 0xFFFFFFff, "Auto Dowse");
      autodowse = CheckBox(130, y, 0,0xFFFFFFff, "", autodowse, 1, 1)
    end
    y = y + 35;

    if lsButtonText(10, lsScreenY - 30, 0, 100, 0x00FF00ff, "Start") then
      return;
    end
    if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFFFFFFff, "End script") then
      error("Clicked End Script button");
    end

    lsDoFrame();
  end
end

function displayStatus()
  local message = "Last Found: " .. status;
  if autorun == 1 then
    message = "Please move to the next position.\n\n" .. message;
  end

  lsPrintWrapped(10, 10, 0, lsScreenX - 20, 0.7, 0.7, 0xB0B0B0ff, message);

  if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFFFFFFff, "End script") then
    error "Clicked End Script button";
  end

  lsDoFrame();
end

function walk(distance)
  local coords = findCoords();
  if autorun == 2 then
    coords[1] = coords[1] + distance;
    walkTo(coords);
  elseif autorun == 3 then
    coords[1] = coords[1] - distance;
    walkTo(coords);
  elseif autorun == 4 then
    coords[0] = coords[0] + distance;
    walkTo(coords);
  elseif autorun == 5 then
    coords[0] = coords[0] - distance;
    walkTo(coords);
  end
end

function dowse()
  local count = 1;
  if multipleRods then
    count = 2;
  end

  for i = 1, count do
    srReadScreen();
    local button = waitForImage("dowsing.png", 72000, "Waiting to dowse, stay put.", nil, 6000);
    if not button then
      fatalError("Unable to find dowsing button");
    end
    safeClick(button[0], button[1]);
    getDowseResult(true);
  end
end

function getRodType()
  local rods = findAllText("Dowsing Rod (");
  for i = 1, #rods do
    safeClick(rods[i][0], rods[i][1]);
  end

  lsSleep(100);
  srReadScreen();

  local rodRegion = findText("Deselect as preferred Dowsing", nil, REGION);
  if not rodRegion then
    lsPrintln("No select");
    return nil;
  end

  local rod = findText("Dowsing Rod (", rodRegion);
  if not rod then
    lsPrintln("No rod");
    return nil;
  end

  local type = string.match(rod[2], "Dowsing Rod (%b())");
  if not type then
    lsPrintln("No match");
    return nil;
  end

  return string.lower(string.gsub(type, "[%(%)]", ""));
end

function switchRods()
  if multipleRods then
    local rods = findAllText("Dowsing Rod (");
    while not rods or #rods ~= 2 do
      promptOkay("Please pin both of your dowsing rods", nil, nil, nil, true);
      srReadScreen();
      rods = findAllText("Dowsing Rod (");
    end
    clickAllText("Dowsing Rod (");
    lsSleep(100);

    srReadScreen();
    local select = findText("Select as preferred Dowsing");
    if not select then
      error("Unable to select dowsing rod");
    end
    safeClick(select[0], select[1]);
    lsSleep(100);

    srReadScreen();
    clickAllText("Dowsing Rod (");
    currentRod = getRodType();
    if not currentRod then
      error("Couldn't read current rod");
    end
  end
end

function doit()
  askForWindow([[
Dowses With Ducks

This program will record each dowsing from main chat, and log them to dowsing.txt

With Auto Run Off, you must manually move and dowse.

With Auto Run On, it will run in the selected direction, stopping every "Auto Dowse" coords to dowse.

Hover over the ATITD window and press shift.
]]);

  setGameOptions({}, {}, {
    [TOOLTIPS] = false,
  });

  displayConfig();
  getDowseResult(false, true);
  switchRods();
  lsDoFrame();

  if autorun > 1 then
    setCameraView(CARTOGRAPHER2CAM);
  end

  if spacing > 0 then
    dowse();
  end

  while true do
    displayStatus();

    if spacing > 0 then
      walk(spacing);
      dowse();
    else
      walk(1);
      if autodowse and srFindImage("dowsing.png") then
        dowse();
      else
        getDowseResult();
      end
    end

    checkBreak();
    lsSleep(50);
  end
end
