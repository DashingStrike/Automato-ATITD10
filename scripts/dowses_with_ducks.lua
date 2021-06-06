dofile("common.inc");

local mapColors = {
  sand = "DotWh",
  ["Copper Ore"] = "DotOr",
  ["Iron Ore"] = "DotRd",
  ["Tin Ore"] = "DotLb",
  ["Zinc Ore"] = "DotVi",
  ["Aluminum Ore"] = "DotBl",
  ["Lead Ore"] = "DotPk",
  unrecognized = "DotYe",
};

local lastX = 0;
local lastY = 0;
local status = "";
local wikiMapFormat = true;

function writeDowseLog(x, y, region, name, exact)
  local color = mapColors[name];
  if not color then
    color = "Dot";
  end

  if not exact then
    name = name .. " nearby";
  end

  local text;
  if wikiMapFormat then
    text = "(" .. color .. ") " .. x .. "," .. y .. " ," .. name .. " @ (" .. x .. ", " .. y .. ") " .. region;
  else
    text = x .. "," .. y .. "," .. region .. "," .. name;
  end
  logfile = io.open("dowsing.txt","a+");
  logfile:write(text .. "\n");
  logfile:close();
end

function checkIfMain()
  if not srFindImage("chat/main_chat.png") then
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

  region, x, y = string.match(lastLine, "You detect nothing but sand at (%D+) ([-0-9]+) ([-0-9]+)");
  if (region) then
    if ((x ~= lastX) or (y ~= lastY)) then
      writeDowseLog(x , y, region, "sand", true);
      status = "Sand at " .. x .. ", " .. y;
      lastX = x;
      lastY = y;
    end
    return;
  end

  foundOre, region, x, y = string.match(lastLine, "You detect an underground vein of (%D+) at (%D+) ([-0-9]+) ([-0-9]+)");
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

  foundOre, region, x, y = string.match(lastLine, "You detect a vein of (%D+), somewhere nearby (%D+) ([-0-9]+) ([-0-9]+)");
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
  wikiMapFormat = CheckBox(10, y, 0, 0xFFFFFFff, "Log Wiki Map Format", wikiMapFormat, 0.7, 0.7);
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

Hover over the ATITD window and press shift.
]]);
  windowSize = srGetWindowSize();
  local i = 0;
  while true do
    if (i % 10) == 0 then
      srReadScreen();
      getDowseResult();
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
