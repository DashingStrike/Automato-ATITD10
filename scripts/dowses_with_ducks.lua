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

local lastX = 0;
local lastY = 0;
local status = "";
local format = 1;
local autorun = false;

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
      name;
  else
    text = x .. "," ..
      y .. "," ..
      region .. "," ..
      name;
  end
  logfile = io.open("dowsing.txt","a+");
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
    sleepWithStatus(100, "Copying chat", nil, 0.7);
    chatText = copyAllChatLines();
  end

  lastLine = chatText[#chatText][2];

  local foundOre;
  local region;
  local x;
  local y;

  region, x, y = string.match(lastLine, ".+ detect nothing but sand at (%D+) ([-0-9]+%.[0-9]+) ([-0-9]+%.[0-9]+)");
  if (region) then
    if ((x ~= lastX) or (y ~= lastY)) then
      writeDowseLog(x , y, region, "Sand", true);
      status = "Sand at " .. x .. ", " .. y;
      lastX = x;
      lastY = y;
    end
    return;
  end

  foundOre, region, x, y = string.match(lastLine, ".+ detect an underground vein of (%D+) at (%D+) ([-0-9]+%.[0-9]+) ([-0-9]+%.[0-9]+)");
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

  foundOre, region, x, y = string.match(lastLine, ".+ detect a vein of (%D+), somewhere nearby (%D+) ([-0-9]+%.[0-9]+) ([-0-9]+%.[0-9]+)");
  if (foundOre) then
    if ((x ~= lastX) or (y ~= lastY)) then
      lsPlaySound("cymbals.wav");
      status = foundOre .. " near " .. x .. ", " .. y;
      lastX = x;
      lastY = y;
    end
  end
end

function doDisplay()
  local y = 5;

  lsPrint(10, y, 0, 0.7, 0.7, 0xB0B0B0ff, "This will write a log to dowsing.txt");
  y = y + 25;

  format = readSetting("dowse_format", format);
  lsPrint(10, y, 0, 1, 1, 0xFFFFFFff, "Log Format:");
  format = lsDropdown("dowse_format", 125, y, 0, 150, format, formats);
  writeSetting("dowse_format", format);
  y = y + 35;

  autorun = CheckBox(10, y, 0, 0xFFFFFFff, "Auto Run", autorun, 0.7, 0.7);
  y = y + 25;

  lsPrint(10, y, 0, 0.7, 0.7, 0xB0B0B0ff, status);

  if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff, "End script") then
    error "Clicked End Script button";
  end

  lsDoFrame();
end

function doit()
  askForWindow([[
Dowses With Ducks

This program will record each dowsing from main chat, and log them to dowsing.txt

Autorun just clicks in the upper part of the screen occasionally, so keep it clear.

Hover over the ATITD window and press shift.
]]);
  local xyScreenSize = srGetWindowSize();
  local i = 0;
  while true do
    if (i % 10) == 0 then
      srReadScreen();
      getDowseResult();
    end

    if autorun and (i % 30) == 0 then
      safeClick(xyScreenSize[0] / 2, xyScreenSize[1] / 3);
    end

    checkBreak();
    lsSleep(50);
    doDisplay();

    if not lastAuto and auto then
      i = 0;
    else
      i = i + 1;
    end
  end
end
