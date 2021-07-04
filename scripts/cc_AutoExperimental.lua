dofile("common.inc");

askText = "EXPERIMENTAL: May have some issues, notably with snuffing the fire.\n\nAutomatically runs many charcoal hearths or ovens simultaneously.\n\nMake sure this window is in the TOP-RIGHT corner of the screen.\n\nTap Shift (while hovering ATITD window) to continue.";

wmText = "Tap Ctrl on Charcoal Hearths or Ovens\nto open and pin. Tap Alt to open, pin\nand stash.";

ButtonBegin = 1;
ButtonWood = 2;
ButtonWater = 3;
ButtonCloseVent = 4;
ButtonNormalVent = 5;
ButtonOpenVent = 6;

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
  --function windowManager(title, message, allowCascade, allowWaterGap, varWidth, varHeight, sizeRight, offsetWidth, offsetHeight)
  windowManager("Charcoal Setup", wmText, nil, nil, nil, nil, nil, nil, nil);   --add 16 extra pixels to window height because window expands with 'Take...' menu after first batch is created
  unpinOnExit(ccMenu);
end

function ccMenu()
  local passCount = 1;
  local done = false;
  while not done do
    lsPrint(5, 5, 5, 0.7, 0.7, 0xffffffff, "How many passes?");
    done, passCount = lsEditBox("pass_count", 5, 35, 0, 100, 30, 0.7, 0.7, 0x000000ff, passCount);
    if lsButtonText(5, 110, 0, 50, 0xffffffff, "OK") then
      done = true;
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
BarWoodAddValue = 16;
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
    result[OsInitial] = false;
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
    result[i][OsInitial] = false;
    ignore, result[i] = updateOvenState(ovens[i], result[i]);
    result[i][OsInitial] = true;
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

BarHeatMin = BarStateRange * 0.44;
BarHeatFinishMin = BarStateRange * 0.55;
BarHeatLow = BarStateRange * 0.73;
BarHeatMax = BarStateRange * 0.84;
BarOxygenMin = BarStateRange * 0.03;
BarWoodSimmerMin = BarStateRange * 0.25;
BarWoodBuildMin = BarStateRange * 0.35;
BarWoodBuildMax = BarStateRange * 0.43;
BarWoodHeatGrow = BarStateRange * 0.53;
BarWaterFinishMin = BarStateRange * 0.15;
BarWaterFinishMax = BarStateRange * 0.25;
BarDangerWary = BarStateRange * 0.82;
BarDangerMax = BarStateRange * 0.92;
BarProgressAlmostDone = BarStateRange * 0.85;

BarOxygenToWoodRatioToOpenVent = 0.48;
BarOxygenEventClosedVentSignal = 0.15;
BarOxygenMinGrowthWhileOpen = 0.10;

function manageOxygen(oven, newState, ovenState)
  if newState[OsOxygen] < BarOxygenMin then
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
  elseif newState[OsVent] == OsVentNormal and ovenState[OsOxygen] - newState[OsOxygen] >= BarOxygenEventClosedVentSignal * newState[OsWood] then
    -- Oxygen might be dropping due to an event that half closes the vent, which can reduce oxygen a lot.
    newState[OsVent] = OsVentOpen;
    clickButton(oven, ButtonOpenVent);
  elseif newState[OsVent] == OsVentOpen and newState[OsOxygen] - ovenState[OsOxygen] < BarOxygenMinGrowthWhileOpen * newState[OsWood] then
    -- Oxygen might have been dropping due to an event that half closes the vent, which can reduce oxygen a lot.
    -- Do nothing because the opened vent didn't do as much as we expected.
  elseif newState[OsOxygen] >= BarOxygenToWoodRatioToOpenVent * newState[OsWood] then -- More than half as much oxygen as wood.
    if newState[OsHeat] < BarHeatMax then
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
    if newState[OsProgress] >= BarStateRange + BarStateRangeFinishedBonus then
      -- The oven is done and just needs to cool down.
      if newState[OsWater] < BarWaterFinishMin then
        while newState[OsWater] < BarWaterFinishMax do -- Add water to dump that heat.
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
    else
      -- Oven is still running. Check danger first.
      if newState[OsDanger] > BarDangerMax then
        if newState[OsDanger] >= ovenState[OsDanger] then
          -- Danger is very high and didn't change or got worse since last tick. Take action!
          clickButton(oven, ButtonWater, 1);
          newState[OsWater] = newState[OsWater] + BarWaterAddValue;
          newState[OsExpectWaterChange] = true;
        end

        -- Definitely not dealing with wood, but need to manage oxygen.
        manageOxygen(oven, newState, ovenState);
      elseif newState[OsDanger] > BarDangerWary then
        -- Danger is a bit high. Definitely don't add wood, but manage the oxygen.
        manageOxygen(oven, newState, ovenState);
      elseif newState[OsProgress] > BarProgressAlmostDone then
        -- Nearly done. Can avoid adding wood if the heat stays decent.
        if newState[OsHeat] > BarHeatLow then
          -- Heat is looking good. Just manage oxygen.
          manageOxygen(oven, newState, ovenState);
        elseif newState[OsHeat] > BarHeatFinishMin then
          if (newState[OsHeat] - BarHeatFinishMin) > (BarStateRange - newState[OsProgress]) then
            -- Heat might be good if it doesn't drop too fast.
            manageOxygen(oven, newState, ovenState);
          elseif newState[OsHeat] >= ovenState[OsHeat] then
            -- Heat isn't dropping, so might also be good.
            manageOxygen(oven, newState, ovenState);
          else
            -- Heat is dropping and pretty low compared to how much progress to go. Make sure to add some wood, maybe more than once.
            clickButton(oven, ButtonWood, 1);
            newState[OsWood] = newState[OsWood] + BarWoodAddValue;
            newState[OsExpectWoodChange] = true;
            while newState[OsWood] < BarWoodBuildMin do
              clickButton(oven, ButtonWood, 1);
              newState[OsWood] = newState[OsWood] + BarWoodAddValue;
            end

            manageOxygen(oven, newState, ovenState);
          end
        end
      else
        -- Normal stuff. Try to keep that heat in the good range.
        if newState[OsHeat] > BarHeatMax then
          -- Heat is high, just manage the oxygen.
          manageOxygen(oven, newState, ovenState);
        elseif newState[OsHeat] < BarHeatMin then
          -- Heat is very low and we need to take extreme measures to raise it.
          while newState[OsWood] < BarWoodHeatGrow do
            clickButton(oven, ButtonWood, 1);
            newState[OsWood] = newState[OsWood] + BarWoodAddValue;
            newState[OsExpectWoodChange] = true;
          end

          if newState[OsOxygen] < newState[OsWood] then
            -- Need to build oxygen for a big burst.
            clickButton(oven, ButtonOpenVent);
            newState[OsVent] = OsVentOpen;
          else
            manageOxygen(oven, newState, ovenState);
          end
        elseif newState[OsHeat] < BarHeatLow then
          -- Heat is a bit low, but not too bad.
          while newState[OsWood] < BarWoodBuildMax do
            clickButton(oven, ButtonWood, 1);
            newState[OsWood] = newState[OsWood] + BarWoodAddValue;
            newState[OsExpectWoodChange] = true;
          end

          manageOxygen(oven, newState, ovenState);
        elseif newState[OsHeat] >= ovenState[OsHeat] then
          -- Heat is going up, so just manage oxygen.
          manageOxygen(oven, newState, ovenState);
        else
          -- Heat is going down, maybe bump it up again.
          if newState[OsOxygen] < BarOxygenToWoodRatioToOpenVent * newState[OsWood] then
            -- Only add wood if the vent wouldn't be closed this tick.
            if newState[OsWood] < BarWoodSimmerMin then
              clickButton(oven, ButtonWood, 1);
              clickButton(oven, ButtonWood, 1);
              newState[OsWood] = newState[OsWood] + BarWoodAddValue + BarWoodAddValue;
              newState[OsExpectWoodChange] = true;
            end
          end

          manageOxygen(oven, newState, ovenState);
        end
      end
    end
  end

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

function clickAll(image_name)
  -- Find buttons and click them!
  srReadScreen();
  xyWindowSize = srGetWindowSize();
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
