dofile("common.inc");
dofile("settings.inc");


askText = "Additional Author Credits in Comments!\n\nMake sure chat is MINIMIZED and Main chat tab is visible!\n\nPress Shift over ATITD window to start.\n\nOptional: Pin the mine's Take... Gems... menu (\"All Gems\" will appear in pinned window).\n\nThis optionally pinned window will be refreshed every time the mine is worked.\n\nAlso, if Huge Gem appears in this window, it will alert you with an applause sound.";

bonusRegion = false;
noMouseMove = false;
minPopSleepDelay = 150;  -- The minimum delay time used during findClosePopUp() function
clickDelay = 150;
muteSoundEffects = false;
autoWorkMine = true;
smallGemMode = false;
colorBlind = false;
dropdown_values = {"Shift Key", "Ctrl Key", "Alt Key", "Mouse Wheel Click"};
dropdown_cur_value = 1;
dropdown_pattern_values = {"6 color (1 Pair) (*)", "5 color (2 Pair) (*)", "4 color (3 Pair) (*)", "5 color (Triple) (5)", "4 color (Triple+Pair) (4)", "4 color (Quadruple) (6)", "3 Color (Quad+Pair) (1)", "3 color (Quintuple) (5)", "7 Color (All Different) (*)"};

gui = {
  [1] = "6 color (1 Pair) (*)",
  [2] = "5 color (2 Pair) (*)",
  [3] = "4 color (3 Pair) (*)",
  [4] = "5 color (Triple) (5)",
  [5] = "4 color (Triple+Pair) (4)",
  [6] = "4 color (Quadruple) (6)",
  [7] = "3 Color (Quad+Pair) (1)",
  [8] = "3 color (Quintuple) (5)",
  [9] = "7 Color (All Different) (*)"
};

dropdown_pattern_cur_value = 1;
lastLineFound = "";
lastLineFound2 = "";

allSets = {

  {  --6 color (1 Pair)
    {1,3,4},
    {1,5,6,7},
    {1,3,5},
    {1,4,6,7},
    {1,3,6},
    {1,4,5,7},
    {1,3,7},
    {2,4,5,6},
    {2,3,4},
    {2,4,5},
    {2,5,6},
    {2,6,7},
    {2,3,7},
    {2,3,4,5,6,7}
  },

  {  --5 color (2 Pair)
    {5,6,7},
    {5,1,3},
    {5,1,4},
    {5,2,3},
    {5,2,4},
    {6,1,3},
    {6,1,4},
    {6,2,3},
    {6,2,4},
    {7,1,3},
    {7,1,4},
    {7,2,3},
    {7,2,4},
    {1,3,5,6,7},
    {2,4,5,6,7}
  },

  {  --4 color (3 Pair)
    {1,3,5},
    {2,4,6,7},
    {1,3,6},
    {2,4,5,7},
    {1,4,5},
    {2,3,6,7},
    {1,4,6},
    {2,3,5,7},
    {2,3,5},
    {1,4,6,7},
    {2,3,6},
    {1,4,5,7},
    {2,4,5},
    {1,3,6,7},
  },

  {  --5 color (Triple)
    {1,4,5},
    {1,4,6},
    {1,4,7},
    {1,5,6},
    {1,5,7},
    {1,6,7},
    {2,4,5},
    {2,4,6},
    {2,4,7},
    {2,5,6},
    {2,5,7},
    {2,6,7},
    {1,2,3},
    {3,4,5,6,7}
  },

  {  --4 color (Triple + Pair)
    {1,2,3},
    {1,4,6},
    {1,4,7},
    {1,5,6},
    {1,5,7},
    {1,6,7},
    {2,4,6},
    {2,4,7},
    {3,4,6},
    {3,4,7},
    {2,6,7},
    {1,4,6,7}
  },

  {  --4 color (Quadruple)
    {1,5,6},
    {1,5,7},
    {1,6,7},
    {2,5,6},
    {2,5,7},
    {2,6,7},
    {3,5,6},
    {3,5,7},
    {3,6,7},
    {4,5,6,7},
    {1,2,3},
    {1,2,4},
    {1,3,4},
    {2,3,4},
    {1,2,3,4}
  },

  {  --3 color (Quad + Pair)
    {1,5,7},
    {1,6,7},
    {2,5,7},
    {2,6,7},
    {3,5,7},
    {3,6,7},
    {4,5,7}
  },

  {  --3 color (Quintuple)
    {1,2,3},
    {1,2,4},
    {1,2,5},
    {1,3,4},
    {1,3,5},
    {1,4,5},
    {2,3,4},
    {2,3,5},
    {2,4,5},
    {3,4,5},
    {1,2,3,4,5}
  },

  {  -- 7 color (All different)
    {1,2,3,4,5,6},
    {1,2,3,4,5,7},
    {1,2,3,4,6,7},
    {1,2,3,5,6,7},
    {1,2,4,5,6,7},
    {1,3,4,5,6,7},
    {2,3,4,5,6,7},
    {1,2,3,4,5,6,7}
  }

};

allSetsSmall = {

  {  --6 color (1 Pair)
    {2,3,4,5,6,7},
    {2,4,5,6},
    {1,5,6,7},
    {1,4,6,7},
    {1,4,5,7},
    {1,3,4},
    {1,3,5},
    {1,3,6},
    {1,3,7},
    {2,3,4},
    {2,4,5},
    {2,5,6},
    {2,6,7},
    {2,3,7}
  },

  {  --5 color (2 Pair)
    {2,4,5,6,7},
    {1,3,5,6,7},
    {5,6,7},
    {5,1,3},
    {5,1,4},
    {5,2,3},
    {5,2,4},
    {6,1,3},
    {6,1,4},
    {6,2,3},
    {6,2,4},
    {7,1,3},
    {7,1,4},
    {7,2,3},
    {7,2,4}
  },

  {  --4 color (3 Pair)
    {2,4,6,7},
    {2,4,5,7},
    {2,3,6,7},
    {2,3,5,7},
    {1,4,6,7},
    {1,4,5,7},
    {1,3,6,7},
    {1,3,5},
    {1,3,6},
    {1,4,5},
    {1,4,6},
    {2,3,5},
    {2,3,6},
    {2,4,5},
  },

  {  --5 color (Triple)
    {3,4,5,6,7},
    {1,4,5},
    {1,4,6},
    {1,4,7},
    {1,5,6},
    {1,5,7},
    {1,6,7},
    {2,4,5},
    {2,4,6},
    {2,4,7},
    {2,5,6},
    {2,5,7},
    {2,6,7},
    {1,2,3}
  },

  {  --4 color (Triple + Pair)
    {1,4,6,7},
    {1,2,3},
    {1,4,6},
    {1,4,7},
    {1,5,6},
    {1,5,7},
    {1,6,7},
    {2,4,6},
    {2,4,7},
    {3,4,6},
    {3,4,7},
    {2,6,7}
  },

  {  --4 color (Quadruple)
    {4,5,6,7},
    {1,2,3,4},
    {1,5,6},
    {1,5,7},
    {1,6,7},
    {2,5,6},
    {2,5,7},
    {2,6,7},
    {3,5,6},
    {3,5,7},
    {3,6,7},
    {1,2,3},
    {1,2,4},
    {1,3,4},
    {2,3,4}
  },

  {  --3 color (Quad + Pair)
    {1,5,7},
    {1,6,7},
    {2,5,7},
    {2,6,7},
    {3,5,7},
    {3,6,7},
    {4,5,7}
  },

  {  --3 color (Quintuple)
    {1,2,3,4,5},
    {1,2,3},
    {1,2,4},
    {1,2,5},
    {1,3,4},
    {1,3,5},
    {1,4,5},
    {2,3,4},
    {2,3,5},
    {2,4,5},
    {3,4,5}
  },

  {  -- 7 color (All different)
    {1,2,3,4,5,6},
    {1,2,3,4,5,7},
    {1,2,3,4,6,7},
    {1,2,3,5,6,7},
    {1,2,4,5,6,7},
    {1,3,4,5,6,7},
    {2,3,4,5,6,7},
    {1,2,3,4,5,6,7}
  }
};


function doit()
  askForWindow(askText);
  promptDelays();
  getMineLoc();
  getPoints();
  clickSequence();
end

function getMineLoc()
  mineList = {};
  local was_shifted = lsShiftHeld();
  if (dropdown_cur_value == 1) then
    was_shifted = lsShiftHeld();
    key = "tap Shift";
  elseif (dropdown_cur_value == 2) then
    was_shifted = lsControlHeld();
    key = "tap Ctrl";
  elseif (dropdown_cur_value == 3) then
    was_shifted = lsAltHeld();
    key = "tap Alt";
  elseif (dropdown_cur_value == 4) then
    was_shifted = lsMouseIsDown(2); --Button 3, which is middle mouse or mouse wheel
    key = "click MWheel ";
  end
  local is_done = false;
  mx = 0;
  my = 0;
  z = 0;
  while not is_done do
    mx, my = srMousePos();
    local is_shifted = lsShiftHeld();
    if (dropdown_cur_value == 1) then
      is_shifted = lsShiftHeld();
    elseif (dropdown_cur_value == 2) then
      is_shifted = lsControlHeld();
    elseif (dropdown_cur_value == 3) then
      is_shifted = lsAltHeld();
    elseif (dropdown_cur_value == 4) then
      is_shifted = lsMouseIsDown(2); --Button 3, which is middle mouse or mouse wheel
    end

    if is_shifted and not was_shifted then
      mineList[#mineList + 1] = {mx, my};
    end
    was_shifted = is_shifted;
    checkBreak();
    lsPrint(10, 10, z, 1.0, 1.0, 0x80ff80ff,
      "Set Mine Location");
    local y = 50;
    lsPrint(5, y, z, 0.7, 0.7, 0xf0f0f0ff, "Lock ATITD screen (Alt+L) .");
    y = y + 20;
    lsPrint(5, y, z, 0.7, 0.7, 0xf0f0f0ff, "Suggest F5 view, zoomed about 75% out.");
    y = y + 40;
    lsPrint(5, y, z, 0.7, 0.7, 0x80ff80ff, "Hover and " .. key .. " over the MINE.");
    y = y + 40;
    lsPrint(5, y, 0, 0.6, 0.6, 0xffff80ff, "TIP (Optional):");
    y = y + 20;
    lsPrint(5, y, 0, 0.6, 0.6, 0xffffffff, "For Maximum Performance (least lag) Uncheck:");
    y = y + 16;
    lsPrint(5, y, 0, 0.6, 0.6, 0xffffffff, "Options, Interface, Other: 'Use Flyaway Messages'");
    local start = math.max(1, #mineList - 20);
    local index = 0;
    for i=start,#mineList do
      mineX = mineList[i][1];
      mineY = mineList[i][2];
    end

    if #mineList >= 1 then
      is_done = 1;
    end

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff,
      "End script") then
      error "Clicked End script button";
    end
    lsDoFrame();
    lsSleep(10);
  end
end

function getPoints()
  clickList = {};
  local was_shifted = lsShiftHeld();
  if (dropdown_cur_value == 1) then
    was_shifted = lsShiftHeld();
    key = "tap Shift";
  elseif (dropdown_cur_value == 2) then
    was_shifted = lsControlHeld();
    key = "tap Ctrl";
  elseif (dropdown_cur_value == 3) then
    was_shifted = lsAltHeld();
    key = "tap Alt";
  elseif (dropdown_cur_value == 4) then
    was_shifted = lsMouseIsDown(2); --Button 3, which is middle mouse or mouse wheel
    key = "click MWheel ";
  end

  local is_done = false;
  local nx = 0;
  local ny = 0;
  local z = 0;
  while not is_done do
    nx, ny = srMousePos();
    local is_shifted = lsShiftHeld();
    if (dropdown_cur_value == 1) then
      is_shifted = lsShiftHeld();
    elseif (dropdown_cur_value == 2) then
      is_shifted = lsControlHeld();
    elseif (dropdown_cur_value == 3) then
      is_shifted = lsAltHeld();
    elseif (dropdown_cur_value == 4) then
      is_shifted = lsMouseIsDown(2);
    end

    if is_shifted and not was_shifted and #clickList < 7 then
      clickList[#clickList + 1] = {nx, ny};
    end
    was_shifted = is_shifted;
    checkBreak();
    local y = 10;
    lsPrint(5, y, 0, 0.8, 0.8, 0xffffffff,
      "Choose Pattern:");
    y = y + 35;
    lsSetCamera(0,0,lsScreenX*1.3,lsScreenY*1.3);
    dropdown_pattern_cur_value = lsDropdown("ArrangerDropDown2", 5, y, 0, 300, dropdown_pattern_cur_value, dropdown_pattern_values);
    lsSetCamera(0,0,lsScreenX*1.0,lsScreenY*1.0);
    y = y + 20;
    lsPrint(5, y, z, 0.8, 0.8, 0xFFFFFFff,
      "Set Node Locations (" .. #clickList .. "/7)");
    y = y + 75;
    lsSetCamera(0,0,lsScreenX*1.5,lsScreenY*1.5);
    if autoWorkMine then
      autoWorkMineColor = 0xFFFFFFff
    else
      autoWorkMineColor = 0xc0c0c0ff
    end
    if colorBlind then
      colorBlindColor = 0xFFFFFFff
    else
      colorBlindColor = 0xc0c0c0ff
    end
    if noMouseMove then
      noMouseMoveColor = 0xFFFFFFff
    else
      noMouseMoveColor = 0xc0c0c0ff
    end
    if muteSoundEffects then
      muteSoundEffectsColor = 0xFFFFFFff
    else
      muteSoundEffectsColor = 0xc0c0c0ff
    end
    if smallGemMode then
      smallGemModeColor = 0xff8080ff
    else
      smallGemModeColor = 0xc0c0c0ff
    end
    autoWorkMine = readSetting("autoWorkMine",autoWorkMine);
    autoWorkMine = lsCheckBox(15, y, z, autoWorkMineColor, " Auto 'Work Mine'", autoWorkMine);
    writeSetting("autoWorkMine",autoWorkMine);
    y = y + 25;
    colorBlind = readSetting("colorBlind",colorBlind);
    colorBlind = lsCheckBox(15, y, z, colorBlindColor, " 'Color Blind' Mode", colorBlind);
    writeSetting("colorBlind",colorBlind);
    y = y + 25;
    noMouseMove = readSetting("noMouseMove",noMouseMove);
    noMouseMove = lsCheckBox(15, y, z, noMouseMoveColor, " Dual Monitor (NoMouseMove) Mode", noMouseMove);
    writeSetting("noMouseMove",noMouseMove);
    y = y + 25;
    muteSoundEffects = readSetting("muteSoundEffects",muteSoundEffects);
    muteSoundEffects = lsCheckBox(15, y, z, muteSoundEffectsColor, " Mute Sound Effects", muteSoundEffects);
    writeSetting("muteSoundEffects",muteSoundEffects);
    y = y + 25;
    smallGemMode = readSetting("smallGemMode",smallGemMode);
    smallGemMode = lsCheckBox(15, y, z, smallGemModeColor, " Small Gem Mode", smallGemMode);
    writeSetting("smallGemMode",smallGemMode);
    lsSetCamera(0,0,lsScreenX*1.0,lsScreenY*1.0);
    y = y - 50
    lsPrint(5, y, z, 0.6, 0.6, 0xffa9abff, "Small Gem Mode will try to get more Small Gems,");
    y = y + 15;
    lsPrint(5, y, z, 0.6, 0.6, 0xffa9abff, "in exchange for less Huge and Large Gems.");
    y = y + 25;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Hover and " .. key .. " each node, in this order:");
    y = y + 15;
    lsPrint(5, y, z, 0.5, 0.5, 0xf0f0f0ff, "Quintuples (5 same color), Quadruples (4 same color)");
    y = y + 15;
    lsPrint(5, y, z, 0.5, 0.5, 0xf0f0f0ff, "Triples (3 same color), Pairs (2 same color)");
    y = y + 15;
    lsPrint(5, y, z, 0.5, 0.5, 0xf0f0f0ff, "Single colored nodes (1 color)");
    y = y + 20;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Ingame Popup? Suggests you chose wrong pattern.");
    y = y + 15;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Or you need to adjust the delays (previous menu).");
    y = y + 15;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "(*) Denotes ALL stones should be broken!");
    y = y + 15;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "(#) Denotes # of stones NOT broken!");
    y = y + 25;

    local start = math.max(1, #clickList - 20);
    local index = 0;

    for i=start,#clickList do
      local xOff = (index % 4) * 70;
      local yOff = (index - index%4)/2 * 7;
      lsPrint(5 + xOff, y + yOff, z, 0.5, 0.5, 0xffffffff,
        i .. ": (" .. clickList[i][1] .. ", " .. clickList[i][2] .. ")");
      index = index + 1;
    end

    if #clickList >= 7 then
      is_done = 1;
    end

    if #clickList == 0 then
      if lsButtonText(10, lsScreenY - 30, z, 110, 0xffff80ff, "Work Mine") then
        while lsMouseIsDown() do
          sleepWithStatus(16, "Release Mouse !", nil, 0.7, "Preparing to Work Mine");
        end
        workMine(1);
        srSetMousePos(mineX, mineY);
      end
    end

    if #clickList > 0 then
      if lsButtonText(100, lsScreenY - 30, z, 75, 0xff8080ff, "Reset") then
        lsDoFrame();
        reset();
      end
    end

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff,
      "End script") then
      error "Clicked End script button";
    end
    lsDoFrame();
    lsSleep(10);
  end
end

function reset()
  getPoints();
  clickSequence();
end

function checkAbort()
  if lsControlHeld() and lsAltHeld() then
    while lsControlHeld() and lsAltHeld() do
      sleepWithStatus(16, "Release Keys...");
    end
    sleepWithStatus(750, "Aborting ...");
    reset();
  end
end

function workMine(skipSettle)
  if not skipSettle then
    sleepWithStatus(2000, "Waiting for mine to settle ...", nil, 0.7, "Please Wait");
  end
  findClosePopUp(1);
  workMineButtonLoc = getMousePos();
  workMineButtonLocSet = true;
  if noMouseMove then
    srClickMouseNoMove(mineX, mineY);
    lsSleep(clickDelay);
    clickAllText("Work this Mine", 20, 2, 1); -- offsetX, offsetY, rightClick (1 = true)
  else
    srSetMousePos(mineX, mineY);
    lsSleep(clickDelay);
    if colorBlind then
      --Send 'C' key over Mine to Work it in Color Blind mode (Get new nodes)
      srKeyEvent('C');
    else
      --Send 'W' key over Mine to Work it (Get new nodes)
      srKeyEvent('W');
    end
  end
  sleepWithStatus(1000, "Working mine (Fetching new nodes)", nil, 0.7, "Please Wait");
  findClosePopUp(1);
end

function TakeGemWindowRefresh()
  srReadScreen();
  ---- New Feature, Refresh Gem Take menu
  -- First, check to see if we have an empty window (you previously Took All Gems); Refresh
  findEmptyWindow = srFindImage("WindowEmpty.png")
  if findEmptyWindow then
    safeClick(findEmptyWindow[0]+10,findEmptyWindow[1]+10);
    lsSleep(100);
    srReadScreen();
  end
  -- Next check to see if All Gems (From mine's Take menu) is pinned up, if so refresh it.
  findAllGems = findText("All Gems");
  if findAllGems then
    if not autoWorkMine then
      sleepWithStatus(1000, "Refreshing pinned Gem menu ...", nil, 0.7); -- Let pinned window catchup. If autowork mine, there is already a 1000 delay on workMine()
    end
    safeClick(findAllGems[0]-10,findAllGems[1]);
  end
  -- Now check to see if there is a Huge Gem and give a special alert.
  lsSleep(500);
  srReadScreen();
  findHugeGems = findText("Huge");
  if findHugeGems then
    if not muteSoundEffects then
      lsPlaySound("applause.wav");
    end
    sleepWithStatus(15000, "You found a Huge Gem!\n\nYou should take it now!", 0x80ff80ff, 0.7, "Congratulations");
  end
end


function checkIfMain(chatText)
  for j = 1, #chatText do
    if string.find(chatText[j][2], "^%*%*", 0) then
      return true;
    end
  end
  return false;
end


function chatRead()
  srReadScreen();
  local chatText = getChatText();
  local onMain = checkIfMain(chatText);

  if not onMain then
    if not muteSoundEffects then
      lsPlaySound("timer.wav");
    end
  end

  -- Wait for Main chat screen and alert user if its not showing
  while not onMain do
    checkBreak();
    srReadScreen();
    chatText = getChatText();
    onMain = checkIfMain(chatText);
    sleepWithStatus(100, "Looking for Main chat screen ...\n\nIf main chat is showing, then try clicking Work Mine to clear this screen", nil, 0.7, "Error Parsing Screen");
  end

  -- Verify chat window is showing minimum 2 lines
  while #chatText < 2  do
    checkBreak();
    srReadScreen();
    chatText = getChatText();
    sleepWithStatus(500, "Error: We must be able to read at least the last 2 lines of main chat!\n\nCurrently we only see " .. #chatText .. " lines ...\n\nYou can overcome this error by typing ANYTHING in main chat.", nil, 0.7, "Error Parsing Screen");
  end

  --Read last line of chat and strip the timer ie [01m]+space from it.
  lastLine = chatText[#chatText][2];
  lastLineParse = string.sub(lastLine,string.find(lastLine,"m]")+3,string.len(lastLine));
  --Read next to last line of chat and strip the timer ie [01m]+space from it.
  lastLine2 = chatText[#chatText-1][2];
  lastLineParse2 = string.sub(lastLine2,string.find(lastLine2,"m]")+3,string.len(lastLine2));

  if string.sub(lastLineParse, 1, 21) == "Local support boosted" or string.sub(lastLineParse2, 1, 21) == "Local support boosted" then
    bonusRegion = true;
  end

  if string.sub(lastLineParse, 1, 21) == "Local support boosted" then
    localSupportFound = true;
  else
    localSupportFound = false;
  end
end

function findClosePopUp(noRead)

  local skipRead = false;
  if noRead then
    skipRead = true;
  end

  chatRead();
  lastLineFound = lastLineParse;
  lastLineFound2 = lastLineParse2;
  startTime = lsGetTimer();

  while 1 do
    checkBreak();
    chatRead();
    OK = srFindImage("OK.png");

    if clickDelay < minPopSleepDelay then
      popSleepDelay = minPopSleepDelay;
    else
      popSleepDelay = clickDelay
    end

    if OK then
      srClickMouseNoMove(OK[0]+2,OK[1]+2);
      lsSleep(popSleepDelay);
      break;
    end

    if (lastLineFound2 ~= lastLineParse2 and not bonusRegion) or (lastLineFound ~= lastLineParse and not localSupportFound) or (skipRead == true) or ( (lsGetTimer() - startTime) > 6000 ) or (worked-1 == #sets)  then
      break;
    end

  end
end


function clickSequence()
  --  chatRead();
  if noMouseMove then
    sleepWithStatus(3000, "Starting... Now is your chance to move your mouse to second monitor!", nil, 0.7, "Are you ready?");
  else
    sleepWithStatus(150, "Starting... Don\'t move mouse!", nil, 0.8, "Hands Off Da\' Mouse");
  end

  local startMiningTime = lsGetTimer();
  worked = 1;
  if smallGemMode then
    sets = allSetsSmall[dropdown_pattern_cur_value];
  else
    sets = allSets[dropdown_pattern_cur_value];
  end
  local pattern = "Unknown";

  for k, v in pairs(gui) do
    if k == dropdown_pattern_cur_value then
      pattern = v;
      break;
    end
  end


  for i = 1, #sets do
    local currentSet = sets[i];
    for j = 1, #currentSet do
      local currentIndex = currentSet[j];
      checkBreak();
      checkAbort();

      if noMouseMove then -- Check for dual monitor option - don't move mouse cursor over each node and send keyEvents. Instead do rightClick popup menus
        --srSetMousePos(0,180); -- Move mouse to near top right corner (below icons), once, to hopefully make node popup menus appear there.
        --lsSleep(100);

        if j == #currentSet then
          srClickMouseNoMove(clickList[currentIndex][1], clickList[currentIndex][2]);
          lsSleep(clickDelay);
          chatRead();
          lastLineFound = lastLineParse;
          lastLineFound2 = lastLineParse2;
          clickAllText("[S]", 20, 2, 1); -- offsetX, offsetY, rightClick (1 = true)
        else
          srClickMouseNoMove(clickList[currentIndex][1], clickList[currentIndex][2]);
          lsSleep(clickDelay);
          clickAllText("[A]", 20, 2, 1); -- offsetX, offsetY, rightClick (1 = true)
        end

      else -- noMouseMove

        srSetMousePos(clickList[currentIndex][1], clickList[currentIndex][2]);
        lsSleep(clickDelay);
        if j == #currentSet then
          chatRead();
          lastLineFound = lastLineParse;
          lastLineFound2 = lastLineParse2;
          srKeyEvent('S');
        else
          srKeyEvent('A');
        end

      end -- noMouseMove
    end

    local y = 10;
    lsPrint(10, y, 0, 0.7, 0.7, 0xB0B0B0ff, "Hold Ctrl+Shift to end this script.");
    y = y +50
    lsPrint(5, y, 0, 0.7, 0.7, 0xffffffff, "[" .. worked .. "/" .. #sets .. "]  " .. #currentSet .. " Nodes Worked: " .. table.concat(currentSet, ", "));
    y = y + 40;
    lsPrint(5, y, 0, 0.7, 0.7, 0xffffffff, "Pattern: " .. pattern);
    y = y + 40;
    lsPrint(5, y, 0, 0.7, 0.7, 0xffffffff, "Click Delay: " .. clickDelay .. " ms");
    y = y + 40;
    lsPrint(5, y, 0, 0.7, 0.7, 0xffffffff, "Hold Ctrl + Alt to Abort and Return to Menu.");
    y = y + 40;
    lsPrint(5, y, 0, 0.7, 0.7, 0xffffffff, "Don't touch mouse until finished!");
    if bonusRegion then
      y = y + 40;
      lsPrint(5, y, 0, 0.7, 0.7, 0x40ff40ff, "Bonus Region detected.");
      y = y + 16;
      lsPrint(5, y, 0, 0.7, 0.7, 0xff4040ff, "Read last line only. Ignore 2nd to last line.");
    end

    y = y + 40

    progressBar(y)

    lsDoFrame();
    worked = worked + 1

    findClosePopUp();
  end
  if not muteSoundEffects then
    lsPlaySound("beepping.wav");
  end
  if autoWorkMine then
    workMine();
  elseif workMineButtonLocSet then
    srSetMousePos(workMineButtonLoc[0], workMineButtonLoc[1]);
  end
  TakeGemWindowRefresh();
  reset();
end

function promptDelays()
  local is_done = false;
  local count = 1;
  while not is_done do
    checkBreak();
    local y = 10;
    lsPrint(12, y, 0, 0.8, 0.8, 0xffffffff,
      "Key or Mouse to Select Nodes:");
    y = y + 35;
    lsSetCamera(0,0,lsScreenX*1.3,lsScreenY*1.3);
    dropdown_cur_value = readSetting("dropdown_cur_value",dropdown_cur_value);
    dropdown_cur_value = lsDropdown("ArrangerDropDown", 15, y, 0, 320, dropdown_cur_value, dropdown_values);
    writeSetting("dropdown_cur_value",dropdown_cur_value);
    lsSetCamera(0,0,lsScreenX*1.0,lsScreenY*1.0);
    y = y + 35;
    lsPrint(15, y, 0, 0.8, 0.8, 0xffffffff, "Click Delay (ms):");

    clickDelay = readSetting("clickDelay",clickDelay);
    is_done, clickDelay = lsEditBox("delay", 145, y-3, 0, 60, 30, 1.0, 1.0,
      0x000000ff, clickDelay);
    clickDelay = tonumber(clickDelay);
    if not clickDelay then
      is_done = false;
      lsPrint(10, y+22, 10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
      clickDelay = 150;
    end
    writeSetting("clickDelay",clickDelay);
    y = y + 50;
    lsPrint(5, y, 0, 0.6, 0.6, 0xffffffff, "Click Delay: Delay between most actions.");
    y = y + 16;
    lsPrint(5, y, 0, 0.6, 0.6, 0xffffffff, "Decrease value to run faster (try increments of 50)");
    y = y + 30;
    lsPrint(5, y, 0, 0.6, 0.6, 0xffff80ff, "Minimized chat-channels MUST be ON!");
    y = y + 16;
    lsPrint(5, y, 0, 0.6, 0.6, 0xffff80ff, "See: Options, Chat-Related, 'Minimize' section.");
    y = y + 28;
    lsPrint(5, y, 0, 0.6, 0.6, 0xffff80ff, "Main chat tab MUST be showing and wide enough");
    y = y + 16;
    lsPrint(5, y, 0, 0.6, 0.6, 0xffff80ff, "so that word wrapping does NOT occur.");
    y = y + 28;
    lsPrint(5, y, 0, 0.6, 0.6, 0xffff80ff, "Chat window MUST be minimized!");
    y = y + 16;
    lsPrint(5, y, 0, 0.6, 0.6, 0xffff80ff, "Main chat tab MUST be showing!");

    if lsButtonText(10, lsScreenY - 30, 0, 100, 0xFFFFFFff, "Next") then
      is_done = 1;
    end
    if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFFFFFFff,
      "End script") then
      error(quitMessage);
    end
    lsDoFrame();
    lsSleep(10);
  end
  return count;
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function progressBar(y)
  barWidth = 220;
  barTextX = (barWidth - 22) / 2
  barX = 10;
  percent = round(worked / #sets * 100,2)
  progress = (barWidth / #sets) * worked
  if progress < barX+6 then
    progress = barX+6
  end

  if math.floor(percent) <= 25 then
    progressBarColor = 0x669c35FF
  elseif math.floor(percent) <= 50 then
    progressBarColor = 0x77bb41FF
  elseif math.floor(percent) <= 65 then
    progressBarColor = 0x96d35fFF
  elseif math.floor(percent) <= 72 then
    progressBarColor = 0xdced41FF
  elseif math.floor(percent) <= 79 then
    progressBarColor = 0xe9ea18FF
  elseif math.floor(percent) <= 83 then
    progressBarColor = 0xf8be0cFF
  elseif math.floor(percent) <= 92 then
    progressBarColor = 0xff7567FF
  elseif math.floor(percent) <= 99 then
    progressBarColor = 0xff301bFF
  else
    progressBarColor = 0xe3c6faFF
  end

  lsPrint(barTextX, y+3.5, 15, 0.60, 0.60, 0x000000ff, percent .. " %");
  lsDrawRect(barX, y, barWidth, y+20, 5,  0x3a88feFF); -- blue shadow
  lsDrawRect(barX+2, y+2, barWidth-2, y+18, 10,  0xf6f6f6FF); -- white bar background
  lsDrawRect(barX+4, y+4, progress, y+16, 15,  progressBarColor); -- colored progress bar
end
