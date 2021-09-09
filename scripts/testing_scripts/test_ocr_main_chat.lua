dofile("common.inc");

local lastChat;
local chatText;

function doit()
  askForWindow("Test reading main chat. Hover ATITD window and Press Shift to continue.");

  while 1 do
    checkBreak();
    chatRead();

    local y = 5;
    if chatText then
      for i = #chatText - 4, #chatText do
        if chatText[i] then
          lsPrint(5, y, 1, 0.7, 0.7, 0xFFFFFFFF, chatText[i][2]);
          y = y + 15;
        end
      end
    end
    local creg = findChatRegionReplacement();
    srMakeImage("current-region", creg[0], creg[1], creg[2], creg[3], true);
    srShowImageDebug("current-region", 5, y + 10, 1, 2);

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff, "End script") then
      error "Clicked End Script button";
    end

    lsDoFrame();
    lsSleep(50);
  end
end

function checkIfMain()
  if not srFindImage("chat/main_chat.png", 7000) then
    return false;
  end

  return true;
end

function chatRead()
  srReadScreen();
  chatText = getChatText();
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
    sleepWithStatus(100, "Looking for Main chat screen", nil, 0.7, "Error Parsing Main Chat");
  end

  -- Verify chat window is showing minimum 2 lines
  while #chatText < 2 do
    checkBreak();
    srReadScreen();
    chatText = getChatText();
    sleepWithStatus(500, "Error: We must be able to read at least the last 2 lines of main chat!\n\nCurrently we only see " .. #chatText .. " lines ...\n\nYou can overcome this error by typing ANYTHING in main chat.", nil, 0.7, "Error Parsing Main Chat");
  end

  if chatText[1][2] ~= lastChat then
    lastChat = chatText[1][2];
    for i = 1, #chatText do
      lsPrintln(chatText[i][2]);
    end
  end
end
