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

local lastX = 0;
local lastY = 0;
local status = "Starting";
local format = 1;
local autorun = 0;
local nearby = false;
local spacing = 0;
local file = "dowsing.txt"

function writeDowseLog(x, y, region, name, exact)
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
  logfile = io.open(file,"a+");
  logfile:write(text .. "\n");
  logfile:close();
end

function checkIfMain()
  if not srFindImage("chat/main_chat.png", 7000) then
    return false;
  end

  return true;
end

function getDowseResult()
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

  local chatText = getChatText();
  while not chatText or not chatText[#chatText] do
    checkBreak();
    srReadScreen();
    sleepWithStatus(100, "Waiting for chat", nil, 0.7);
    chatText = getChatText();
  end

  lastLine = chatText[#chatText][2];

  local foundOre;
  local region;
  local x;
  local y;

  region, x, y = string.match(lastLine, ".+ but sand at (%D+) ([-0-9]+%.[0-9]+) ([-0-9]+%.[0-9]+)");
  if (region) then
    if ((x ~= lastX) or (y ~= lastY)) then
      writeDowseLog(x , y, region, "Sand", true);
      status = "Sand at " .. x .. ", " .. y;
      lastX = x;
      lastY = y;
    end
    return;
  end

  foundOre, region, x, y = string.match(lastLine, ".+ vein of (%D+) at (%D+) ([-0-9]+%.[0-9]+) ([-0-9]+%.[0-9]+)");
  if (foundOre) then
    if ((x ~= lastX) or (y ~= lastY)) then
      lsPlaySound("cymbals.wav");
      writeDowseLog(x , y, region, foundOre, true);
      status = foundOre .. " at " .. x .. ", " .. y;
      lastX = x;
      lastY = y;
    end
    return;
  end

  foundOre, region, x, y = string.match(lastLine, ".+ vein of (%D+), somewhere nearby (%D+) ([-0-9]+%.[0-9]+) ([-0-9]+%.[0-9]+)");
  if (foundOre) then
    if ((x ~= lastX) or (y ~= lastY)) then
      lsPlaySound("cymbals.wav");
      if nearby then
        writeDowseLog(x , y, region, foundOre, false);
      end
      status = foundOre .. " near " .. x .. ", " .. y;
      lastX = x;
      lastY = y;
    end
  end
end

function displayConfig()
  while true do
    checkBreak();

    local y = 5;

    lsPrint(10, y, 0, 0.7, 0.7, 0xB0B0B0ff, "This will write a log to dowsing.txt");
    y = y + 25;

    file = readSetting("file", file);
    lsPrint(10, y, 0, 1, 1, 0xFFFFFFff, "File Name:");
    done, file = lsEditBox("file", 125, y, 0, 150, 0, 1, 1, 0x000000ff, file)
    writeSetting("file", file);
    y = y + 35;

    format = readSetting("format", format);
    lsPrint(10, y, 0, 1, 1, 0xFFFFFFff, "Log Format:");
    format = lsDropdown("format", 125, y, 0, 150, format, formats);
    writeSetting("format", format);
    y = y + 35;

    nearby = readSetting("nearby", nearby);
    lsPrint(10, y, 0, 1, 1, 0xFFFFFFff, "Log Nearby");
    nearby = CheckBox(125, y, 0, 0xFFFFFFff, "", nearby, 1, 1);
    writeSetting("nearby", nearby)
    y = y + 35;

    lsPrint(10, y, 0, 1, 1, 0xFFFFFFff, "Auto Run:");
    autorun = lsDropdown("autorun", 125, y, 0, 150, autorun, directions);
    y = y + 35;

    if autorun > 1 then
      spacing = readSetting("spacing", spacing);
      lsPrint(10, y, 0, 1, 1, 0xFFFFFFff, "Auto Dowse");
      done, spacing = lsEditBox("spacing", 125, y, 0, 55, 0, 1, 1, 0x000000ff, spacing)
      spacing = tonumber(spacing);
      lsPrint(190, y, 0, 1, 1, 0xFFFFFFff, "coords");
      writeSetting("spacing", spacing);
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
  lsPrint(10, 10, 0, 0.7, 0.7, 0xB0B0B0ff, status);

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
  srReadScreen();
  local button = waitForImage("dowsing.png", 72000, "Waiting to dowse\n\n Last Log: " .. status, nil, 6000);
  if not button then
    fatalError("Unable to find dowsing button");
  end
  safeClick(button[0], button[1]);
  srReadScreen();
  getDowseResult();
end

function doit()
  askForWindow([[
Dowses With Ducks

This program will record each dowsing from main chat, and log them to dowsing.txt

With Auto Run Off, you must manually move and dowse.

With Auto Run On, it will run in the selected direction, stopping every "Auto Dowse" coords to dowse.

Hover over the ATITD window and press shift.
]]);

  displayConfig();
  lsDoFrame();

  if autorun > 1 then
    setCameraView(CARTOGRAPHER2CAM);
  end

  if spacing > 0 then
    dowse();
  end

  local i = 0;
  while true do
    displayStatus();

    if spacing > 0 then
      walk(spacing);
      dowse();
    else
      walk(1);
      srReadScreen();
      getDowseResult();
    end

    checkBreak();
    lsSleep(50);
  end
end
