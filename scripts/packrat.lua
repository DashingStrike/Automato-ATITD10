dofile("common.inc");
dofile("settings.inc");

local containerRegion;
local containerName;
local containerCurrent;
local containerMax;
local containerConfig;

local http;

function round(value)
  return math.floor(value + 0.5);
end

function findContainer()
  containerName = nil;
  containerCurrent = 0;
  containerMax = 0;
  containerConfig = {};

  srReadScreen();
  containerRegion = findText("% full", nil, REGION);
  if not containerRegion then
    return;
  end

  local containerText = parseText(containerRegion.x, containerRegion.y, containerRegion.width - 20, containerRegion.height);
  local line3 = containerText[3][2];
  if string.sub(line3, 0, 6) == "Browse" then
    return;
  end
  containerName = line3;

  local line2 = containerText[2][2];
  containerCurrent, containerMax = string.match(line2, "(%d+) of (%d+)");
  containerCurrent = tonumber(containerCurrent);
  containerMax = tonumber(containerMax);

  if containerName then
    containerConfig = readSetting(containerName, {});
  end
end

function stashContainer()
  local stash = waitForText(
    "Stash",
    60000,
    "Waiting for 'Stash' text on the screen.",
    containerRegion
  );

  if not stash then
    return;
  end

  clickText(stash);
  lsSleep(200);

  srReadScreen();
  srSetMousePos(stash[0] + 21, stash[1] + 8);
  local stashWindow = getWindowBorders(stash[0] + 22, stash[1] + 9)
  srSetMousePos(stashWindow.x, stashWindow.y);
  safeClick(stashWindow.x + 5, stashWindow.y + 5, 1);

  repeat
    if stashItems(stashWindow) == false then
      break;
    end

    srReadScreen();
    local scrollbar = findImage("storage/scroll.png", stashWindow);
    local scrollBottom = findImage("storage/scrollBottom.png", stashWindow);
    if scrollbar then
      if not scrollBottom then
        local downArrow = findImage("storage/downArrow.png", stashWindow);
        for i = 1, 30 do
          safeClick(downArrow[0] + 5, downArrow[1] + 5);
          lsSleep(10);
          checkBreak();
        end
        lsSleep(50);
      end
    end
    checkBreak();
  until not scrollbar or scrollBottom

  lsSleep(50);
  srReadScreen();
  safeClick(stashWindow.x + 5, stashWindow.y + 5, 1);
  lsSleep(50)
  safeClick(containerRegion.x + 5, containerRegion.y + 5);
end

function stashItems(stashWindow)
  for item, _ in pairs(containerConfig) do
    srReadScreen();

    if string.sub(item, -3, -1) == "..." then
      local text = findText(item, stashWindow);
      if text then
        clickText(text);
        lsSleep(50);
        srReadScreen();
        local all = findText("All");
        if all then
          clickText(all);
          if handleFull() then
            return false;
          end
        end
      end
      return
    end

    local lines = findAllText(item, stashWindow, REGEX);
    for i = 1, #lines do
      if string.find(lines[i][2], "^" .. item .. " %(") then
        clickText(lines[i]);

        if handleFull() then
          return false;
        end

        waitAndClickImage("max.png");

        lsSleep(50);
        safeClick(stashWindow.x + 5, stashWindow.y + 5);

        lsSleep(50);
        checkBreak();
      end
    end
    checkBreak();
  end

  return true;
end

function handleFull()
  lsSleep(50);
  srReadScreen();
  local ok = findImage("ok.png");
  if ok then
    clickText(ok);
    return true;
  end

  return false;
end

function openContainer()
  local mousePos = getMousePos();
  safeClick(mousePos[0], mousePos[1]);
  local found = waitForText("% full", 1000);
  srSetMousePos(mousePos[0] - 20, mousePos[1] - 20)
  if found then
    findContainer();

    if next(containerConfig) ~= nil then
      stashContainer();
    end
  end
end

function sortConfig(config)
  local sortTable = {};
  for item, _ in pairs(config) do
    table.insert(sortTable, item);
  end

  table.sort(sortTable);

  return sortTable;
end

function import(url)
  if not http then
    http = require("ssl.https");
  end

  local body, status, auth = http.request(url);
  if status ~= 200 then
    sleepWithStatus(2000, "Error Fetching Data.\nStatus: " .. status .. "\nBody: " .. body .. "\nAuth: " .. table.concat(auth, ", "));
    return;
  end

  print(body);

  local file = io.open("scripts/Settings.packrat.lua.txt", "r");
  if file then
    local backup = io.open("scripts/Settings.packrat.lua.backup." .. getTime("datetime3") .. ".txt", "w");

    backup:write(file:read("*all"));
    backup:close();
    file:close();
  end

  file = io.open("scripts/Settings.packrat.lua.txt", "w+");

  file:write(body);
  file:close();

  settingsInitialized = false;
  initialize();

  lsDoFrame();
  lsPrint(10, 10, 0, 1.0, 1.0, 0xFFFFFFff, "Import complete");
  lsDoFrame();
  lsSleep(2000);
end

function displayImport()
  while true do
    lsPrintWrapped(10, 10, 0, lsScreenX - 20, 0.7, 0.7, 0xFFFFFFff, [[
  This will backup your current settings.
  Imports new settings from the interwebz.
  Pastebin is an easy place to host them.
    * Be sure to use raw format.
]]);

    lsPrint(10, 280, 0, 1.0, 1.0, 0xFFFFFFff, "Url:");
    local _, importUrl = lsEditBox("packrat_import", 50, 280, 0, 240, 25, 1.0, 1.0, 0x000000ff);

    if lsButtonText(10, lsScreenY - 30, 0, 80, 0x0000FFff, "Import") then
     import(importUrl);
    end

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 80, 0xFFFFFFff, "Back") then
      return;
    end

    lsDoFrame();
    checkBreak();
    lsSleep(50);
  end
end

function displayConfig()
  local unique = math.random();
  local newConfig = {};

  for item, _ in pairs(containerConfig) do
    newConfig[item] = true;
  end

  while true do
    local y = 5;
    lsScrollAreaBegin("setting_mushrooms", 5, y, 0, 280, 280);

    for _, item in pairs(sortConfig(newConfig)) do
      if lsButtonText(5, y, 1, 25, 0xFF0000ff, "-") then
        newConfig[item] = nil;
      end
      lsPrint(35, y, 1, 1.0, 1.0, 0xFFFFFFff, item);
      y = y + 30;
    end

    lsScrollAreaEnd(y);

    local done, newItem = lsEditBox('new_item' .. unique, 5, 290, 1, 290, 25, 1.0, 1.0, 0x000000ff, newItem);
    if done then
      newConfig[newItem] = true;
      unique = math.random();
    end

    if lsButtonText(10, lsScreenY - 30, 0, 80, 0x00FF00ff, "Save") then
      containerConfig = newConfig;
      writeSetting(containerName, containerConfig);
      return;
    end

    if lsButtonText(100, lsScreenY - 30, 0, 80, 0xFFFFFFff, "Cancel") then
      return;
    end

    lsDoFrame();
    checkBreak();
    lsSleep(50);
  end
end

function displayStatus()
  local message = "Open a storage container to configure it.\n Or tap ctrl over a container to auto stash.";
  if containerRegion ~= nil then
    if (containerName) then
      message = "Found container: " .. containerName .. "\n" ..
        round(containerCurrent / containerMax * 100) .. "% full (" .. containerCurrent .. " of " .. containerMax .. ")";

      if next(containerConfig) ~= nil then
        if lsButtonText(10, lsScreenY - 30, 0, 80, 0x00FF00ff, "Stash") then
          stashContainer();
        end

        if (lsControlHeld()) then
          while (lsControlHeld()) do
            checkBreak();
            lsSleep(50);
          end
          stashContainer();
        end
      end

      if lsButtonText(100, lsScreenY - 30, 0, 80, 0xFFFFFFff, "Config") then
        displayConfig();
      end
    else
      message = "Found container, but it has no label."
    end
  else
    if lsButtonText(100, lsScreenY - 30, 0, 80, 0xFFFF00ff, "Import") then
      displayImport();
    end
  end

  lsPrintWrapped(10, 10, 0, lsScreenX - 20, 0.7, 0.7, 0xB0B0B0ff, message);

  if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFFFFFFff, "End script") then
    error "Clicked End Script button";
  end

  lsDoFrame();
end

function doit()
  askForWindow([[
Packrat

This program will help with stashing stuff into storage containers.

Default behavior requires an exact match.
Supports categories, like "Metal...", that stash all
Supports lua pattern matching in item names.

Hover over the ATITD window and press shift.
]]);

  while true do
    findContainer();
    displayStatus();

    if (lsControlHeld()) then
      while (lsControlHeld()) do
        checkBreak();
        lsSleep(50);
      end
      openContainer();
    end

    checkBreak();
    lsSleep(50);
  end
end
