dofile("common.inc");
dofile("settings.inc");

moveImages = {
  "Asianinfluence.png",
  "Broadjump.png",
  "Cartwheels.png",
  "Catstretch.png",
  "Clappingpushups.png",
  "Crunches.png",
  "Fronttuck.png",
  "Handplant.png",
  "Handstand.png",
  "Invertedpushups.png",
  "Jumpsplit.png",
  "Jumpingjacks.png",
  "Kickup.png",
  "Legstretch.png",
  "Lunge.png",
  "Pinwheel.png",
  "Pushups.png",
  "Rearsquat.png",
  "Roundoff.png",
  "Runinplace.png",
  "Sidebends.png",
  "Somersault.png",
  "Spinflip.png",
  "Squats.png",
  "Squatthrust.png",
  "Toetouches.png",
  "Widesquat.png",
  "Windmill.png",
};

moveNames = {
  "Asian Influence",
  "Broad Jump",
  "Cartwheels",
  "Cat Stretch",
  "Clapping Push-Ups",
  "Crunches",
  "Front Tuck",
  "Handplant",
  "Handstand",
  "Inverted Pushups",
  "Jump Split",
  "Jumping Jacks",
  "Kick-Up",
  "Leg Stretch",
  "Lunge",
  "Pinwheel",
  "Push-Ups",
  "Rear Squat",
  "Roundoff",
  "Run in Place",
  "Side Bends",
  "Somersault",
  "Spin Flip",
  "Squats",
  "Squat Thrust",
  "Toe Touches",
  "Wide Squat",
  "Windmill",
};

moveShortNames = {
  "AI",
  "BJ",
  "CW",
  "CS",
  "CPU",
  "CR",
  "FT",
  "HP",
  "HS",
  "IPU",
  "JS",
  "JJ",
  "KU",
  "LS",
  "LU",
  "PW",
  "PU",
  "RS",
  "RO",
  "RIP",
  "SB",
  "SS",
  "SF",
  "SQ",
  "ST",
  "TT",
  "WS",
  "WM",
};

local timerPositions = {
  0,
  20,
  -20,
  40,
  -40,
  60,
  -60,
  80,
  -80,
  100,
  -100,
  120,
  -120,
  140,
  -140,
};

local bernike = {
  {2836, -988 },
  {2836, -972 },
  {2836, -956 },
  {2836, -940 },
  {2836, -924 },
  {2836, -908 },
  {2836, -892 },
  {2820, -892 },
  {2820, -908 },
  {2820, -924 },
  {2820, -940 },
  {2820, -956 },
  {2820, -972 },
  {2820, -988 },
  {2804, -988 },
  {2804, -972 },
  {2804, -956 },
  {2804, -940 },
  {2804, -924 },
  {2804, -908 },
  {2804, -892 },
  {2788, -892 },
  {2788, -908 },
  {2788, -924 },
  {2788, -940 },
  {2788, -956 },
  {2788, -972 },
  {2788, -988 },
  {2772, -988 },
  {2772, -972 },
  {2772, -956 },
  {2772, -940 },
  {2772, -924 },
  {2772, -908 },
  {2772, -892 },
  {2756, -892 },
  {2756, -908 },
  {2756, -924 },
  {2756, -940 },
  {2756, -956 },
  {2756, -972 },
  {2756, -988 },
};

local hello = "";
local bye = "";
local notification = 3;
local switch = false;
local auto = false;
local move = false;
local greeted = false;

local activated = false;

function doit()
  askForWindow([[
  Acro requests will be automatically accepted

  Start will begin performing 1 move at a time
  indefinitely and chat the Start Msg (if set)

  End will close the window and chat End Msg

  Press Shift over ATITD window to continue.
]]);
  refresh();
  displayMoves();
end

function findMoves()
  greeted = false;

  lsDoFrame();
  statusScreen("Scanning Acro Buttons ...", nil, 0.7);
  foundMovesName = {};
  foundMovesImage = {};
  foundMovesShortName = {};
  local message = "";

  srReadScreen();
  local defaultSize = srFindImage("acro/default_size.png", 500);
  if defaultSize then
    local resize = srFindImage("acro/resize.png", 500);
    safeDrag(resize[0], resize[1], resize[0], resize[1] + 240);
  end

  srReadScreen();
  --See if the acro bar (middle border on Acro window) is found.  If not, then just set Y to screenHeight
  --Moves above the acro bar are moves that your partner does not know yet. Moves below are moves your partner already knows.  Attempt to exclude those.
  barFound = srFindImage("acro/acro_bar.png", 500);
  if barFound then
    acroY = barFound[1];   -- set Y position of the middle border
    message = message .. "\n\nDIVIDER BAR FOUND!\n\nIgnoring moves below the border...";
  else
    atitdY = srGetWindowSize();
    acroY = atitdY[1];   -- No middle border found, so just use ATITD screen height
  end

  local acrobatics = srFindImage("acro/acrobatics.png", 500);
  if not acrobatics then
    return;
  end
  safeDrag(acrobatics[0], acrobatics[1], 300, acrobatics[1]);

  for i=1,#moveNames do
    checkBreak();
    srReadScreen();
    local found = srFindImage("acro/" .. moveImages[i]);
    if found then
      moveY = found[1];
    end
    if found and (moveY > acroY) then  --Button found, but below middle border, skip it (this means your partner already knows the move, too.
      statusScreen("Scanning acro buttons...\n\nSkipping: " .. moveNames[i] .. message, nil, 0.7);
    end

    if found and (moveY < acroY) then
      foundMovesName[#foundMovesName + 1] = moveNames[i];
      foundMovesImage[#foundMovesImage + 1] = moveImages[i];
      foundMovesShortName[#foundMovesShortName + 1] = moveShortNames[i];
      statusScreen("Scanning acro buttons...\n\nFound: " .. moveNames[i] .. message, nil, 0.7);
      lsSleep(10);
    end
  end
end

function openChat(active, white, red)
  if not srFindImage(active) then
    local chat = srFindImage(white);
    if not chat then
      chat = srFindImage(red);
    end

    if not chat then
      lsPrintln("Chat tab not found");
      return false;
    end

    safeClick(chat[0], chat[1]);
    lsSleep(100);
  end

  if not waitForImage(active, 2000) then
    lsPrintln("Chat tab failed to open");
    return false;
  end

  local min = srFindImage("chat/chat_min.png");
  if min then
    srKeyDown(VK_RETURN);
    lsSleep(10);
    srKeyUp(VK_RETURN);
    lsSleep(10);
  end

  if waitForNoImage("chat/chat_min.png", 2000) then
    lsPrintln("Chat failed to start");
    return false;
  end

  return true;
end

function say(msg)
  if not openChat("chat/main_chat.png", "ocr/mainChatWhite.png", "ocr/mainChatRed.png") then
    return;
  end

  srKeyEvent(msg);
  lsSleep(100);
  srKeyDown(VK_RETURN);
  lsSleep(10);
  srKeyUp(VK_RETURN);
end

function saySwitch()
  if not openChat("chat/acro_active.png", "chat/acro_white.png", "chat/acro_red.png") then
    return;
  end

  srKeyDown(VK_DIVIDE);
  lsSleep(10);
  srKeyUp(VK_DIVIDE);
  lsSleep(10);
  srKeyEvent("me switch");
  lsSleep(100);
  srKeyDown(VK_RETURN);
  lsSleep(10);
  srKeyUp(VK_RETURN);
end

function follows()
  if not srFindImage("chat/main_chat.png") then
    return false;
  end

  local parses = getChatText();
  if #parses == 0 then
    return false;
  end

  return string.find(parses[#parses][2], "student follows");
end

function uncheck(i)
  if #foundMovesShortName < 2 then
    --Don't uncheck the last move, keep going so that acro stays active for learning
    return;
  end

  sleepWithStatus(7000, "Unchecking " .. foundMovesName[i] .. " from Move List.\n\nMove was followed or learnt", nil, 0.7);
  foundMovesShortName[i] = false;

  countChecked();
end

function activateTimer()
  if activated then
    return false;
  end

  activated = true;
  local windowSize = srGetWindowSize();
  local activateStart = lsGetTimer();
  while lsGetTimer() - activateStart < 3000 do
    for i = 1, #timerPositions do
      srSetMousePos(windowSize[0] / 2 + timerPositions[i], 125);
      srReadScreen();
      local timer = findImage("acro/timer.png", iconRange);
      if timer then
        safeClick(timer[0], timer[1]);
        srSetMousePos(windowSize[0] / 2, windowSize[1] / 2);

        if waitForImage("acro/timer.png", 1000, nil, iconRange, 500) then
          return true;
        end
      end
    end
  end

  return false;
end

function wait(message)
  checkBreak();

  if lsButtonText(10, lsScreenY - 30, z, 90, 0xFF9999ff, "End") then
    finish();
    displayMoves();
  end

  if lsButtonText(lsScreenX / 2 - 45, lsScreenY - 30, z, 80, 0xffff80ff, "Menu") then
    displayMoves();
  end

  statusScreen(message);
  lsSleep(100);
end

function getSessionTime(sessionStart)
  local seconds = math.floor((lsGetTimer() - sessionStart) / 1000);
  local minutes = math.floor(seconds / 60);
  seconds = math.floor(seconds % 60);

  return minutes, seconds;
end

function doMoves()
  local sessionStart = lsGetTimer();
  local timerPlayed = false;
  local lastClick = 0;
  local windowSize = srGetWindowSize();
  local iconRange = {x = windowSize[0] / 2 - 200, y = 80, width = 400, height = 50};

  lsDoFrame();

  while checkedBoxes > 0 do
    local i = 1;
    local count = 1;
    while i <= #foundMovesName do
      checkBreak();
      if foundMovesShortName[i] then
        local minutes, seconds = getSessionTime(sessionStart);

        while findImage("acro/timer.png", iconRange, 4000) do
          activated = true;
          minutes, seconds = getSessionTime(sessionStart);

          wait("Session time: " .. minutes .. "m " .. seconds .. "s\n\n" .. string.upper(foundMovesName[i]) .. "\n[" .. count .. "/" .. checkedBoxes .. "] Moves.\n\n");
          srReadScreen();
        end

        if (notification and not timerPlayed and minutes >= notification) then
          lsPlaySound("trolley.wav");
          timerPlayed = true;

          if switch then
            saySwitch();
          end
        end

        clickMove = srFindImage("acro/" .. foundMovesImage[i]);
        if clickMove and barFound and clickMove[1] > acroY then
          -- Check if the button is below a found divider Bar.
          -- This suggests your partner has learned a new move while acroing and the button has moved below the bar. Skip and uncheck the box.
          uncheck(i);
        elseif clickMove then
          lastClick = lsGetTimer();
          if debugClickMoves then
            srSetMousePos(clickMove[0]+3, clickMove[1]+2);
          end
          srClickMouseNoMove(clickMove[0]+3, clickMove[1]+2);

          if not waitForImage("acro/timer.png", 2500, nil, iconRange, 500) then
            if not activateTimer() then
              local delayStart = lsGetTimer();
              while (lsGetTimer() - delayStart) < 4000 do
                minutes, seconds = getSessionTime(sessionStart);

                wait("Session time: " .. minutes .. "m " .. seconds .. "s\n\n" .. string.upper(foundMovesName[i]) .. "\n[" .. count .. "/" .. checkedBoxes .. "] Moves.\n\n" .. [[
Unable to find acro timer.

Please click it, so that it is solid
and the seconds are displayed

Falling back to 7 second delay

]]);
              end
            end
          end

          if follows() then
            uncheck(i);
          else
            i = i + 1;
            count = count + 1;
          end
        else
          -- This suggests your partner has learned a new move while acroing and the button has moved below the bar (but out of sight, furthur down in menu).
          uncheck(i);
        end
      else
        i = i + 1;
      end
    end
  end
end

function checkAllBoxes()
  for i=1,#foundMovesName do
    foundMovesShortName[i] = true;
  end
end


function uncheckAllBoxes()
  for i=1,#foundMovesName do
    foundMovesShortName[i] = false;
  end
end

function start()
  if hello ~= "" and not greeted then
    greeted = true;
    say(hello);
  end

  countChecked();

  if checkedBoxes > 0 then
    doMoves();
  end
end

function getNextLocation()
  local coords = findCoords();
  if coords and coords[0] > 2748 and coords[0] < 2844 and coords[1] > -996 and coords[1] < -884 then
    for i = 1, #bernike do
      if math.abs(coords[0] - bernike[i][1]) < 8 and math.abs(coords[1] - bernike[i][2]) < 8 then
        if i == #bernike then
          sleepWithStatus(2000, "Can not move because you are at the last station. Congrats!");
          return nil;
        end

        return {[0] = bernike[i + 1][1], [1] = bernike[i + 1][2]};
      end
    end
  else
    sleepWithStatus(2000, "Can not move because you are not at Bernike Acro Court on a station.");
    return nil;
  end
end

function finish()
  local close = srFindImage("acro/close.png", 500);
  if close then
    safeClick(close[0], close[1]);
  end

  if bye ~= "" then
    say(bye);
  end

  if move then
    local nextLocation = getNextLocation();
    if (nextLocation) then
      setCameraView(CARTOGRAPHER2CAM);
      walkTo(nextLocation);
    end
  end
end

function countChecked()
  checkedBoxes = 0;
  for i = 1, #foundMovesName do
    if foundMovesShortName[i] then
      checkedBoxes = checkedBoxes + 1;
    end
  end
end

function refresh()
  findMoves();
  checkAllBoxes();
  if auto then
    sleepWithStatus(3000, "Waiting a few seconds before starting moves...");
    start();
  end
end

function displayMoves()
  lsDoFrame();
  local foo;
  local totalCheckedMoves = 0

  while 1 do
    checkBreak()
    local y = 10;

    lsSetCamera(0,0,lsScreenX*1.5,lsScreenY*1.5);

    local windowSize = lsGetWindowSize();

    hello = readSetting("hello", hello);
    lsPrint(5, y, 0, 1, 1, 0xFFFFFFff, "Start Msg:");
    foo, hello = lsEditBox("hello", 105, y, z, windowSize[0] - 120, 0, 1, 1, 0x000000ff, hello);
    writeSetting("hello", hello);
    y = y + 30;

    bye = readSetting("bye", bye);
    lsPrint(5, y, 0, 1, 1, 0xFFFFFFff, "End Msg:");
    foo, bye = lsEditBox("bye", 105, y, z, windowSize[0] - 120, 0, 1, 1, 0x000000ff, bye);
    writeSetting("bye", bye);
    y = y + 30;

    auto = readSetting("auto", auto);
    lsPrint(5, y, 0, 1, 1, 0xFFFFFFff, "Auto Start:");
    auto = lsCheckBox(105, y, z, 0xFFFFFFff, "", auto);
    writeSetting("auto", auto);
    y = y + 30;

    lsPrint(5, y, 0, 1, 1, 0xFFFFFFff, "Move:");
    move = lsCheckBox(105, y, z, 0xFFFFFFff, "", move);
    lsPrint(135, y, 0, 1, 1, 0xFFFFFFff, "Only works @ Bernike Acro Court");
    y = y + 30;

    lsPrint(5, y, 0, 1, 1, 0xFFFFFFff, "Timer:");
    foo, notification = lsEditBox("notification", 105, y, z, 20, 0, 1, 1, 0x000000ff, notification);
    lsPrint(135, y, 0, 1, 1, 0xFFFFFFff, "Minutes (Plays Sound)");
    notification = tonumber(notification);
    y = y + 30;

    if notification and notification > 0 then
      switch = lsCheckBox(105, y, z, 0xFFFFFFff, "", switch);
      lsPrint(135, y, 0, 1, 1, 0xFFFFFFff, "Call Switch (Only in Acro Courts)");
    end
    y = y + 30;

    if #foundMovesName > 0 then
      lsPrint(5, y, 0,1, 1, 0x40ff40ff, "Check moves you want to perform:");
    else
      lsPrint(5, y, 0, 1, 1, 0xff8080ff, "No acro window found!");
    end
    y = y + 30;
    local moveY = y * 0.67;

    totalCheckedMoves = 0;
    for i=1,#foundMovesName do
      local color = 0xB0B0B0ff;
      if foundMovesShortName[i] then
        color = 0xffffffff;
        totalCheckedMoves = totalCheckedMoves + 1;
      end
      foundMovesShortName[i] = lsCheckBox(20, y, z, color, " " .. foundMovesName[i], foundMovesShortName[i]);
      y = y + 20;
    end

    if lsKeyHeld(112) then
      askAcro();
    end

    srReadScreen();
    local yes = srFindImage("yes.png");
    if yes then
      safeClick(yes[0], yes[1]);
      lsSleep(1000);
    end
    if srFindImage("acro/default_size.png", 500) then
      refresh();
    end

    lsPrint(5, lsScreenY * 1.5 - 75, 0, 0.9, 0.9, 0xffff00ff, "Hover Mouse over Partner and Tap F1 to Ask Acro!");

    local screenX = lsScreenX * 1;
    local screenY = lsScreenY * 1;
    lsSetCamera(0,0, screenX, screenY);

    if lsButtonText(screenX - 105, moveY, z, 100, 0xFFFFFFff, "Refresh") then
      refresh();
    end

    if #foundMovesName > 0 then
      if lsButtonText(screenX - 105, moveY + 30, z, 100, 0xFFFFFFff, "Check") then
        checkAllBoxes();
      end

      if lsButtonText(screenX - 105, moveY + 60, z, 100, 0xFFFFFFff, "Uncheck") then
        uncheckAllBoxes();
      end

      if lsButtonText(5, screenY - 30, z, 90, 0x99FF99ff, "Start") then
        start();
      end
    end

    if lsButtonText(100, lsScreenY - 30, z, 90, 0xFF9999ff, "End") then
      finish();
    end

    if lsButtonText(screenX - 105, screenY -30, z, 100, 0xFFFFFFff, "Exit") then
      error "Clicked Exit button";
    end

    lsSetCamera(0,0, lsScreenX,lsScreenY);
    lsDoFrame();
    lsSleep(10);
  end
end


function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end


function askAcro()
  local escape = "\27"

  lsDoFrame();
  statusScreen("Asking to Acro...", nil, 0.7);
  local pos = getMousePos();
  srClickMouseNoMove(pos[0], pos[1], 1); -- Right click where mouse is hovering (partner). Use right click in case we misclick and don't start running.
  clickText(waitForText("Tests", 500));
  lsSleep(100); -- Needed so that next menu doesn't fall behind Tests menu.
  clickText(waitForText("The Human Body", 500));
  clickText(waitForText("Test of the Acrobat", 500));
  clickText(waitForText("Ask to Acro", 500));
  lsSleep(100);
  srKeyEvent(escape) -- Hit ESC to close any unpinned windows.
end
