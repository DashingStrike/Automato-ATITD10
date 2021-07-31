dofile("common.inc");
dofile("settings.inc")

-- TODO: Test/adapt for regulator 0. I'm concerned that some of the logic/thresholds may not be portable between R0 and R1.
-- TODO: Add better handling of oxygen, specifically to avoid snuffing the fire.
-- TODO: Add experimental/observation mode for 1 hearth usage.
-- TODO: Reorder functions to move important logic to the top.

-- Explanantion of methodology:
-- This script is based on utilizing a few behaviors to achieve efficient use of wood during charcoal
-- generation. First, while at low wood values (10-25%), three things are true: heat drops faster,
-- oxygen is consumed less when the oxygen is closed, and oxygen is built up faster when the vent is
-- neutral. Secondly, heat generally is only built up when wood values are in the middle range (25-50%).
-- Thirdly, wood is consumed faster when it is higher. Using all these behaviors, this script tries to
-- generate charcoal over 2-3 cycles of heat generation and heat conservation. During the heat
-- generation phase, wood is added to build the heat. Once a heat has risen above a certain threshold,
-- it switches to the heat conservation phase. During the heat conservation phase, the vent is
-- manipulated to minimze heat loss without adding anymore wood. When the heat drops below a certain
-- threshold, it switches back to the heat generation phase.

askText = "EXPERIMENTAL: May have some issues, notably with snuffing the fire.\n\nRegulator 1 is the most tested currently. YMMV for regulator 0.\n\nAutomatically runs many charcoal hearths or ovens simultaneously.\n\nMake sure this window is in the TOP-RIGHT corner of the screen.\n\nTap Shift (while hovering ATITD window) to continue.";

wmText = "Tap Ctrl on Charcoal Hearths or Ovens\nto open and pin. Tap Alt to open, pin\nand stash.";

ButtonBegin = 1;
ButtonWood = 2;
ButtonWater = 3;
ButtonCloseVent = 4;
ButtonNormalVent = 5;
ButtonOpenVent = 6;

useOven = true; -- Default to using a CC Oven. You can use a CC Hearth with checkbox in options()
setRegulator = true; -- Automatically set the regulator to the provided level.
regulatorList = {"0","1","2","3","4","5"};
regulatorLevel = "0";
regulatorIndex = 0;

buttons = {
  {
    image = "charcoal/begin.png",
    offset = makePoint(25, 10)
  },
  {
    image = "charcoal/wood.png",
    offset = makePoint(0, 25)
  },
  {
    image = "charcoal/water.png",
    offset = makePoint(0, 25)
  },
  {
    image = "charcoal/vent.png",
    offset = makePoint(18, 25)
  },
  {
    image = "charcoal/vent.png",
    offset = makePoint(34, 25)
  },
  {
    image = "charcoal/vent.png",
    offset = makePoint(52, 25)
  }
};

woodAddedTotal = 0;
waterAddedTotal = 0;

-- Entry point for the script.
function doit()
  askForWindow(askText);
  windowManager("Charcoal Setup", wmText, nil, true, 364, 303, nil, nil, nil);
  unpinOnExit(ccMenu);
end

function ccMenu()
  local scale = 0.7
  local passCount = 1;
  local done = false;
  while not done do
    local z = 0
    local y = 10

    passCount = readSetting("passCount", passCount)
    lsPrint(10, y, z, scale, scale, 0xFFFFFFff, "How many passes?")

    done, passCount = lsEditBox("passCount", 140, y, z, 50, 0, scale, scale, 0x000000ff, passCount)
    if not tonumber(passCount) then
      done = nil
      lsPrint(200, y, z + 10, 0.7, 0.7, 0xFF2020ff, "NUMBER REQ")
      passCount = 1
    end

    passCount = tonumber(passCount)
    writeSetting("passCount", passCount)
    y = y + 26

    if not useOven and setRegulator then
      lsPrint(10, y, 0, scale, scale, 0xffffffff, "Regulator Level:");
      regulatorLevel = lsDropdown("regulatorLevel", 140, y-5, 0, 100, regulatorLevel, regulatorList);
      if regulatorLevel == "0" then
        regulatorIndex = 0;
      else
        regulatorIndex = 1;
      end
      y = y + 32;
    end

    lsPrintWrapped(
      10,
      y,
      z + 10,
      lsScreenX - 20,
      0.7,
      0.7,
      0xffff40ff,
      "Initialisation Settings:\n-------------------------------------------"
    )
    y = y + 5;

    useOven = readSetting("useOven",useOven);
    if useOven then
      useOven = CheckBox(10, y+30, z, 0x99c2ffff, " Using CC Oven(s) (Uncheck for CC Hearth(s))", useOven, 0.65, 0.65);
      y = y + 26
    else
      useOven = CheckBox(10, y+30, z, 0xffffffff, " Using CC Hearth(s) (Check for CC Oven(s))", useOven, 0.65, 0.65);
      y = y + 20
      setRegulator = CheckBox(10, y+30, z, 0xffffffff, " Automatically set the Regulator level",
      setRegulator, 0.65, 0.65);
      y = y + 26
    end
    writeSetting("useOven",useOven);
    y = y + 26

    if passCount > 1 then
      plural = "passes"
    else
      plural = "pass"
    end

    lsPrintWrapped(
      10,
      y-5,
      z + 10,
      lsScreenX - 20,
      0.7,
      0.7,
      0xffff40ff,
      "-------------------------------------------"
    )

    if ButtonText(10, lsScreenY - 30, z, 100, 0x00ff00ff, "Start !", 0.9, 0.9) then
      done = true;
    end

    passCount = tonumber(passCount)
    writeSetting("passCount", passCount)
    y = y + 26

    if useOven then
      local ccVolume = 200;
      lsPrintWrapped(
        10,
        y + 7,
        z + 10,
        lsScreenX - 20,
        0.7,
        0.7,
        0xD0D0D0ff,
        "The macro will exectue " .. passCount .. " " .. plural .. " which will generate an output of "
        .. ccVolume .. " per Charcoal Oven"
      )
    else
      local ccVolume = 100;
      y = y + 24
      lsPrintWrapped(
        10,
        y + 7,
        z + 10,
        lsScreenX - 20,
        0.7,
        0.7,
        0xD0D0D0ff,
        "The macro will exectue " .. passCount .. " " .. plural .. " which will generate an output of "
        .. ccVolume .. " per Charcoal Hearth"
      )
    end

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFF0000ff, "End script") then
      error "Clicked End Script button"
    end

    lsDoFrame();
    lsSleep(25);
    checkBreak();
  end

  askForFocus();

  startTime = lsGetTimer();
  for i = 1, passCount do
    woodAdded = 0;
    waterAdded = 0;
    woodx1Click = 0;
    drawWater(1); -- Refill Jugs. The parameter of 1 means don't do the animation countdown. Since we won't be running somewhere, not needed
    lsSleep(100);
    Do_Take_All_Click(); -- Make sure ovens are empty. If a previous run didn't complete and has wood leftover, will cause a popup 'Your oven already has wood' and throw macro off
      if not useOven and setRegulator then
        setRegulatorLevel();
      elseif useOven then
        regulatorIndex = 0;
      end
    clickAllImages(buttons[ButtonBegin].image, buttons[ButtonBegin].offset[0], buttons[ButtonBegin].offset[1]);
    lsSleep(1500);
    ccRun(i, passCount);
  end

  Do_Take_All_Click(); -- All done, empty ovens
  lsPlaySound("Complete.wav");
  lsMessageBox("Elapsed Time:", getElapsedTime(startTime), 1);
end

OsHeat = 1;
OsOxygen = 2;
OsWood = 3;
OsWater = 4;
OsDanger = 5;
OsProgress = 6;
OsVent = 7;
OsExpectWoodChange = 8;
OsExpectWaterChange = 9;
OsInitial = 10;

OsVentClosed = 1;
OsVentNormal = 2;
OsVentOpen = 3;

-- Oven State represents the state of all bars, plus the current vent setting (to avoid redundant clicks).
-- The bar state value represents the leftmost pixel that is NOT blue.
-- A bar state of 0 means the bar is empty, while (BarStateRange + 1) is a full bar.

BarStateStart = 58; -- Pixel offset from oven window image.
BarStateEnd = 254;  -- Pixel offset from oven window image.
BarStateRange = BarStateEnd - BarStateStart;
BarStateRangeFinishedBonus = 10;
BarWoodAddValue = 20;
BarWaterAddValue = 12;

BarProgressGreenPosition = makePoint(62, 110); -- About 25%, but doesn't really matter where we check.
BarGreenColor = 0x01F901;
BarBlueColor = 0x0101F9;

BarYs = {
  15, -- OsHeat
  33, -- OsOxygen
  50, -- OsWood
  70, -- OsWater
  90, -- OsDanger
  110 -- OsProgress
};

function copyOvenState(oven)
  local result = {};

  result[OsHeat] = oven[OsHeat];
  result[OsOxygen] = oven[OsOxygen];
  result[OsWood] = oven[OsWood];
  result[OsWater] = oven[OsWater];
  result[OsDanger] = oven[OsDanger];
  result[OsProgress] = oven[OsProgress];
  result[OsVent] = oven[OsVent];
  result[OsExpectWoodChange] = oven[OsExpectWoodChange];
  result[OsExpectWaterChange] = oven[OsExpectWaterChange];
  result[OsInitial] = oven[OsInitial];

  return result;
end

function updateBarState(oven, prevBar, barY)
  local expect = false;
  local testPoint = makePoint(BarStateStart + prevBar, barY);
  local done = false;

  if testPoint[0] == BarStateStart then
    -- Handle case where the bar was empty, which seemed to not work well.
    testPoint[0] = testPoint[0] + 4;
  end

  while not done do
    if pixelMatchFromBuffer(oven, testPoint, BarBlueColor, 4) then
      if expect then
        -- Bar is still here, continue searching.
        testPoint[0] = testPoint[0] + 1;
      else
        -- Bar has been found. Look for where it ends now.
        expect = true;
        testPoint[0] = testPoint[0] + 1;
      end
    else
      if expect then
        -- Found the pixel that represents the end of the bar.
        done = true;
      else
        -- Bar isn't here, so look for it.
        testPoint[0] = testPoint[0] - 1;
      end
    end

    if BarStateEnd < testPoint[0] then
      -- Bar is full?!
      testPoint[0] = BarStateEnd;
      done = true;
    end
    if BarStateStart > testPoint[0] then
      -- Bar is empty.
      testPoint[0] = BarStateStart;
      done = true;
    end
  end

  return testPoint[0] - BarStateStart;
end

-- Takes oven and previousState.
-- Returns changed, newState.
function updateOvenState(oven, ovenState)
  local result = copyOvenState(ovenState);

  result[OsHeat] = updateBarState(oven, ovenState[OsHeat], BarYs[OsHeat]);
  result[OsOxygen] = updateBarState(oven, ovenState[OsOxygen], BarYs[OsOxygen]);
  result[OsWood] = updateBarState(oven, ovenState[OsWood], BarYs[OsWood]);
  result[OsWater] = updateBarState(oven, ovenState[OsWater], BarYs[OsWater]);
  result[OsDanger] = updateBarState(oven, ovenState[OsDanger], BarYs[OsDanger]);
  if pixelMatchFromBuffer(oven, BarProgressGreenPosition, BarGreenColor, 4) then
    result[OsProgress] = BarStateRange + BarStateRangeFinishedBonus;
  else
    result[OsProgress] = updateBarState(oven, ovenState[OsProgress], BarYs[OsProgress]);
  end

  -- TODO: Just do boolean operations here instead?
  local changed = false;
  if result[OsHeat] ~= ovenState[OsHeat] then
    changed = true;
  elseif result[OsOxygen] ~= ovenState[OsOxygen] then
    changed = true;
  elseif result[OsWood] ~= ovenState[OsWood] and not ovenState[OsExpectWoodChange] then
    changed = true;
  elseif result[OsWater] ~= ovenState[OsWater] and not ovenState[OsExpectWaterChange] then
    changed = true;
  elseif result[OsDanger] ~= ovenState[OsDanger] then
    changed = true;
  elseif result[OsProgress] ~= ovenState[OsProgress] then
    changed = true;
  elseif result[OsInitial] then
    changed = true;
  end

  result[OsExpectWoodChange] = false;
  result[OsExpectWaterChange] = false;
  return changed, result;
end

function setupOvenStates(ovens)
  local result = {};
  for i = 1, #ovens do
    result[i] = {}
    result[i][OsHeat] = BarStateRange / 2;
    result[i][OsOxygen] = BarStateRange / 2;
    result[i][OsWood] = BarStateRange / 2;
    result[i][OsWater] = 0;
    result[i][OsDanger] = BarStateRange / 2;
    result[i][OsProgress] = 0;
    result[i][OsVent] = OsVentNormal;
    result[i][OsExpectWoodChange] = false;
    result[i][OsExpectWaterChange] = false;
    result[i][OsInitial] = true;
    ignore, result[i] = updateOvenState(ovens[i], result[i]);
  end
  return result;
end

function findOvens()
  local result = findAllImages("ThisIs.png");
  for i = 1, #result do
    local corner = findImageInWindow("charcoal/mm-corner.png",
                     result[i][0], result[i][1], 100);
    if not corner then
      error("Failed to find corner of cc window.");
    end
    result[i][0] = corner[0];
    result[i][1] = corner[1];
  end
  return result;
end

function findButton(pos, index)
  return findImageInWindow(buttons[index].image, pos[0], pos[1]);
end

function clickButton(pos, index, counter)
  local count = nil;

  local buttonPos = findButton(pos, index);
  if buttonPos then
    safeClick(buttonPos[0] + buttons[index].offset[0], buttonPos[1] + buttons[index].offset[1]);
    count = 1;
  end

  if counter ~= nil and count ~= nil then
    if index == 3 then -- Water
      waterAdded = waterAdded + count;
      waterAddedTotal = waterAddedTotal + count;
    end
    if index == 2 then -- Wood
      woodAdded = woodAdded + count;
      woodAddedTotal = woodAddedTotal + count;
    end
  end
end

-- This starts, monitors, and finishes a single charcoal hearth.
-- The user is still required to run the hearth manually.
-- Used for testing.
function ccMonitor(pass, passCount)
  srReadScreen();
  local ovens = findOvens();
  local states = setupOvenStates(ovens);
  local done = false;
  while not done do
    done = true;
    local changed = false;
    if not findButton(ovens[1], ButtonBegin) then
      changed, states[1] = updateOvenState(ovens[1], states[1]);
      done = false;
    end

    local changedText = "No";
    if changed then
      changedText = "Yes";
    end

    sleepWithStatus(500,
      "Waiting on next tick ...\n\n" ..
      "Changed: " .. changedText .. "\n\n" ..
      "Heat:    " .. states[1][OsHeat] .. "/" .. BarStateRange .. "\n\n" ..
      "Oxygen:  " .. states[1][OsOxygen] .. "/" .. BarStateRange .. "\n\n" ..
      "Wood:    " .. states[1][OsWood] .. "/" .. BarStateRange .. "\n\n" ..
      "Water:   " .. states[1][OsWater] .. "/" .. BarStateRange .. "\n\n" ..
      "Danger:  " .. states[1][OsDanger] .. "/" .. BarStateRange .. "\n\n" ..
      "Prog:    " .. states[1][OsProgress] .. "/" .. BarStateRange .. "\n\n" ..
      "Elapsed Time: " .. getElapsedTime(startTime), nil, 0.7);

    srReadScreen();
  end
end

function ccRun(pass, passCount)
  srReadScreen();
  local ovens = findOvens();
  local states = setupOvenStates(ovens);
  local done = false;
  while not done do
    done = true;
    for i = 1, #ovens do
      if not findButton(ovens[i], ButtonBegin) then
        states[i] = processOven(ovens[i], states[i]);
        done = false;
      end
    end

    sleepWithStatus(500,
      "Waiting on next tick ...\n\n" ..
      "[" .. pass .. "/" .. passCount .. "] Passes\n\n" ..
      "Totals: [This Pass/All Passes]\n\n" ..
      "[".. woodAdded*3 .. "/" .. woodAddedTotal * 3 .. "] Wood Used - Actual\n" ..
      "[" .. woodAdded .. "/" .. woodAddedTotal .. "] 'Add Wood' Button Clicked (x1)\n\n"..
      "[" .. waterAdded .. "/" .. waterAddedTotal .."] Water Used\n" ..
      "             (Excluding cooldown water)\n\n\n" ..
      "Elapsed Time: " .. getElapsedTime(startTime), nil, 0.7);

    srReadScreen();
  end
end

BarHeatMin = { BarStateRange * 0.44, BarStateRange * 0.44 };
BarHeatFinishMin = { BarStateRange * 0.55, BarStateRange * 0.55 };
BarHeatLow = { BarStateRange * 0.74, BarStateRange * 0.74 };
BarHeatMax = { BarStateRange * 0.86, BarStateRange * 0.86 };
BarOxygenMin = { BarStateRange * 0.03, BarStateRange * 0.03 };
BarWoodSimmerMin = { BarStateRange * 0.25, BarStateRange * 0.25 };
BarWoodBuildMin = { BarStateRange * 0.35, BarStateRange * 0.35 };
BarWoodBuildMax = { BarStateRange * 0.43, BarStateRange * 0.43 };
BarWoodHeatGrow = { BarStateRange * 0.53, BarStateRange * 0.53 };
BarWaterFinishMin = { BarStateRange * 0.15, BarStateRange * 0.15 };
BarWaterFinishMax = { BarStateRange * 0.25, BarStateRange * 0.25 };
BarDangerWary = { BarStateRange * 0.82, BarStateRange * 0.82 };
BarDangerMax = { BarStateRange * 0.92, BarStateRange * 0.92 };
BarProgressAlmostDone = { BarStateRange * 0.85, BarStateRange * 0.85 };

BarOxygenToWoodRatioToOpenVent = { 0.52, 0.49 };
BarOxygenEventClosedVentSignal = { 0.15, 0.15 };
BarOxygenMinGrowthWhileOpen = { 0.10, 0.10 };
BarHeatFinishHeatToWoodMultiplier = { 1, 1 };

-- Default management of oxygen when it doesn't really matter.
function manageSafeOxygen(oven, newState, ovenState)
  if newState[OsOxygen] < BarOxygenMin[regulatorIndex] then
    if newState[OsOxygen] < ovenState[OsOxygen] then
      -- Oxygen is low and dropping. Open up the vent.
      if newState[OsVent] == OsVentClosed then
        newState[OsVent] = OsVentNormal;
        clickButton(oven, ButtonNormalVent);
      elseif newState[OsVent] == OsVentNormal and ovenState[OsOxygen] - newState[OsOxygen] >= 0.9 * newState[OsOxygen] then
        newState[OsVent] = OsVentOpen;
        clickButton(oven, ButtonOpenVent);
      end
    end
  elseif newState[OsVent] == OsVentNormal and ovenState[OsOxygen] - newState[OsOxygen] >= BarOxygenEventClosedVentSignal[regulatorIndex] * newState[OsWood] then
    -- Oxygen might be dropping due to an event that half closes the vent, which can reduce oxygen a lot.
    newState[OsVent] = OsVentOpen;
    clickButton(oven, ButtonOpenVent);
  elseif newState[OsVent] == OsVentOpen and newState[OsOxygen] - ovenState[OsOxygen] < BarOxygenMinGrowthWhileOpen[regulatorIndex] * newState[OsWood] then
    -- Oxygen might have been dropping due to an event that half closes the vent, which can reduce oxygen a lot.
    -- Do nothing because the opened vent didn't do as much as we expected.
  elseif newState[OsOxygen] >= BarOxygenToWoodRatioToOpenVent[regulatorIndex] * newState[OsWood] then -- More than half as much oxygen as wood.
    if newState[OsHeat] < BarHeatMax[regulatorIndex] then
      -- Heat is down a bit and oxygen is getting high. Close down the vent.
      if newState[OsVent] ~= OsVentClosed then
        newState[OsVent] = OsVentClosed;
        clickButton(oven, ButtonCloseVent);
      end
    end
  else
    -- Set the vent to neutral otherwise.
    if newState[OsVent] ~= OsVentNormal then
      newState[OsVent] = OsVentNormal;
      clickButton(oven, ButtonNormalVent);
    end
  end
end

function processOven(oven, ovenState)
  local changed = false;
  local newState = {};
  changed, newState = updateOvenState(oven, ovenState);

  if changed then
    -- A tick occurred. Check and handle things in the following order based on priority:
    -- Progress done?
    -- Burn out danger?
    -- Did the fire get snuffed?
    -- Coast to the end?
    -- Might snuff the fire?
    -- Heat is high enough to coast for a bit?
    -- If nothing else, try to build up the heat.

    if newState[OsProgress] >= BarStateRange + BarStateRangeFinishedBonus then -- Progress done?
      -- The oven is done and just needs to cool down.
      if newState[OsWater] < BarWaterFinishMin[regulatorIndex] then
        while newState[OsWater] < BarWaterFinishMax[regulatorIndex] do -- Add water to dump that heat.
          clickButton(oven, ButtonWater);
          newState[OsWater] = newState[OsWater] + BarWaterAddValue;
          newState[OsExpectWaterChange] = true;
        end
      end

      if newState[OsVent] ~= OsVentOpen then
        -- Open the vent to dump heat faster.
        newState[OsVent] = OsVentOpen;
        clickButton(oven, ButtonOpenVent);
      end
    elseif newState[OsDanger] > BarDangerWary[regulatorIndex] then -- Burn out danger?
      if newState[OsDanger] > BarDangerMax[regulatorIndex] and newState[OsDanger] >= ovenState[OsDanger] then
        -- Danger is very high and didn't change or got worse since last tick. Take action!
        clickButton(oven, ButtonWater, 1);
        newState[OsWater] = newState[OsWater] + BarWaterAddValue;
        newState[OsExpectWaterChange] = true;
      end

      -- Since danger is high, definitely don't add wood, but manage the oxygen.
      manageSafeOxygen(oven, newState, ovenState);
    elseif newState[OsWood] == ovenState[OsWood] and newState[OsOxygen] >= ovenState[OsOxygen] and not newState[OsInitial] then -- Snuffed the fire?
      -- TODO: Determine when coasting won't work and just open the vent to end it quicker.
      -- All that can be done is to not waste more wood and hope to coast to the end.
      if newState[OsVent] ~= OsVentClosed then
        newState[OsVent] = OsVentClosed;
        clickButton(oven, ButtonCloseVent);
      end
    elseif newState[OsProgress] > BarProgressAlmostDone[regulatorIndex] and newState[OsHeat] > BarHeatFinishMin[regulatorIndex] then -- Coast to the end?
      -- Nearly done. Can avoid adding wood if the heat stays decent.
      if newState[OsHeat] > BarHeatLow[regulatorIndex] then
        -- Heat is looking good. Just manage oxygen.
        manageSafeOxygen(oven, newState, ovenState);
      elseif (newState[OsHeat] - BarHeatFinishMin[regulatorIndex]) * BarHeatFinishHeatToWoodMultiplier[regulatorIndex] > (BarStateRange - newState[OsProgress]) then
        -- Heat might be good if it doesn't drop too fast.
        manageSafeOxygen(oven, newState, ovenState);
      elseif newState[OsHeat] >= ovenState[OsHeat] then
        -- Heat isn't dropping, so might also be good.
        manageSafeOxygen(oven, newState, ovenState);
      else
        -- TODO: At this point, might need special logic to build heat up enough to finish.
        -- Heat is dropping and pretty low compared to how much progress to go. Might not be able to coast, despite wanting to.
        clickButton(oven, ButtonWood, 1);
        newState[OsWood] = newState[OsWood] + BarWoodAddValue;
        newState[OsExpectWoodChange] = true;
        while newState[OsWood] < BarWoodBuildMin[regulatorIndex] do
          clickButton(oven, ButtonWood, 1);
          newState[OsWood] = newState[OsWood] + BarWoodAddValue;
        end

        manageSafeOxygen(oven, newState, ovenState);
      end
    --elseif newState[OsOxygen] <= expectedOxygenChange(newState) then -- Might snuff the fire?
    -- TODO: Implement.
    elseif newState[OsHeat] > BarHeatMax[regulatorIndex] then -- Can coast for a bit?
      -- Heat is high enough to just coast.
      -- TODO: Might need a special state for this?
      manageSafeOxygen(oven, newState, ovenState);
    else -- Try to build up the heat.
      if newState[OsHeat] < BarHeatMin[regulatorIndex] then
        -- Heat is very low and we need to take extreme measures to raise it.
        while newState[OsWood] < BarWoodHeatGrow[regulatorIndex] do
          clickButton(oven, ButtonWood, 1);
          newState[OsWood] = newState[OsWood] + BarWoodAddValue;
          newState[OsExpectWoodChange] = true;
        end

        if newState[OsOxygen] < newState[OsWood] then
          -- Need to build oxygen for a big burst.
          clickButton(oven, ButtonOpenVent);
          newState[OsVent] = OsVentOpen;
        else
          manageSafeOxygen(oven, newState, ovenState);
        end
      elseif newState[OsHeat] < BarHeatLow[regulatorIndex] then
        -- Heat is a bit low, but not too bad.
        while newState[OsWood] < BarWoodBuildMax[regulatorIndex] do
          clickButton(oven, ButtonWood, 1);
          newState[OsWood] = newState[OsWood] + BarWoodAddValue;
          newState[OsExpectWoodChange] = true;
        end

        manageSafeOxygen(oven, newState, ovenState);
      elseif newState[OsHeat] >= ovenState[OsHeat] then
        -- Heat is going up, so just manage oxygen.
        manageSafeOxygen(oven, newState, ovenState);
      else
        -- Heat is going down, maybe bump it up again.
        if newState[OsOxygen] < BarOxygenToWoodRatioToOpenVent[regulatorIndex] * newState[OsWood] then
          -- Only add wood if the vent wouldn't be closed this tick.
          if newState[OsWood] < BarWoodSimmerMin[regulatorIndex] then
            clickButton(oven, ButtonWood, 1);
            clickButton(oven, ButtonWood, 1);
            newState[OsWood] = newState[OsWood] + BarWoodAddValue + BarWoodAddValue;
            newState[OsExpectWoodChange] = true;
          end
        end

        manageSafeOxygen(oven, newState, ovenState);
      end
    end
  end

  newState[OsInitial] = false;
  return newState;
end

function Do_Take_All_Click()
  statusScreen("Checking / Emptying Ovens ...", nil, 0.7);
  -- refresh windows
  clickAll("ThisIs.png", 1);
  lsSleep(100);

  clickAll("take.png", 1);
  lsSleep(100);

  clickAll("everything.png", 1);
  lsSleep(100);

  -- refresh windows, one last time so we know for sure the machine is empty (Take menu disappears)
  clickAll("ThisIs.png", 1);
  lsSleep(100);
end

function setRegulatorLevel()
  srReadScreen();
  clickAllText("Regulator...")
  waitForText("Regulation Level", 500)
  srReadScreen();
  clickAllText("Set Level " .. regulatorLevel - 1)
end

function clickAll(image_name)
  -- Find buttons and click them!
  srReadScreen();
  local buttons = findAllImages(image_name);

  if #buttons == 0 then
    -- statusScreen("Could not find specified buttons...");
    -- lsSleep(1500);
  else
    -- statusScreen("Clicking " .. #buttons .. "button(s)...");
    if up then
      for i = #buttons, 1, -1  do
        srClickMouseNoMove(buttons[i][0]+5, buttons[i][1]+3);
        lsSleep(per_click_delay);
      end
    else
      for i = 1, #buttons  do
        srClickMouseNoMove(buttons[i][0]+5, buttons[i][1]+3);
        lsSleep(per_click_delay);
      end
    end
    -- statusScreen("Done clicking (" .. #buttons .. " clicks).");
    -- lsSleep(100);
  end
end
