dofile("common.inc");
dofile("Fishing_Func.inc");
dofile("settings.inc");

----------------------------------------
--          Global Variables          --
----------------------------------------
CurrentLure = ""; --Don't Edit
gui_log_fish = {}; --Don't Edit, holds log display
gui_log_fish2 = {}; --Don't Edit, holds log display
lostlure_log = {}; --Don't Edit, holds log display
CurrentLureIndex = 1; -- 1 = First Lure Player Owns in alphabetical order
QCurrentLureIndex = 1;
PlayersLures={}; --Don't Edit, Holds Current Player Lures

castcount = 0;
GrandTotalCaught = 0;
GrandTotalCasts = 0;
GrandTotaldb = 0;
GrandTotalStrange = 0;
GrandTotalOdd = 0;
GrandTotalUnusual = 0;
GrandTotalLuresUsed = 0;
GrandTotalLostLures = 0;
GrandTotalFailed = 0;
lastLostLure = "";
LostLure = 0;
LureType = "";
lastLostLureType = "";
skipLure = false;
lastCastWait = 0;
castWait = 0;

SNum = 0;
Sfish = "";
muteSoundEffects = false;
TotalCasts = 5;
SkipCommon = false; --Skips to next lure if fish caught is a common (Choose True or False).
displayCommon = false; --Does not display common fish in the last 10 caught list
LogFails = false;  	-- Do you want to add Failed Catches to log file? 'Failed to catch anything' or 'No fish bit'.
LogStrangeUnusual = false; 	-- Do you want to add Strange and Unusual fish to the log file?
LogOdd = false; 	-- Do you want to add Odd fish to the log file? Note the log will still add an entry if you lost lure.
AutoFillet = true; -- Do you want to auto-fillet fish if menu is pinned?
----------------------------------------

function setOptions()
  local is_done = false;
  local count = 1;
    while not is_done do
      lsDoFrame();
      checkBreak();
      local y = 10;

      lsPrint(5, y, 0, 0.7, 0.7, 0xffffffff, "# Casts until lure switches");
      TotalCasts = readSetting("TotalCasts",TotalCasts);
      is_done, TotalCasts = lsEditBox("totalcasts", 180, y, 0, 40, 0, 0.8, 0.8, 0x000000ff, TotalCasts);
      TotalCasts = tonumber(TotalCasts);
        if not TotalCasts then
          is_done = false;
          lsPrint(160, y, 10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
        end
      writeSetting("TotalCasts",TotalCasts);
      y = y + 15;
      lsPrintWrapped(10, y, 0, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
      "---------------------------------------------------------------");
      y = y + 15;
      lsPrint(10, y+1, 0, 0.6, 0.6, 0xc0c0ffff, "Main chat MUST be wide enough so no lines wrap!");
      y = y + 15;
      lsPrintWrapped(10, y, 0, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
      "---------------------------------------------------------------");
      y = y + 20;
      muteSoundEffects = readSetting("muteSoundEffects",muteSoundEffects);
      muteSoundEffects = CheckBox(10, y, 10, 0xFFFFFFff, " Mute Sound Effects", muteSoundEffects, 0.7, 0.7);
      writeSetting("muteSoundEffects",muteSoundEffects);
      y = y + 20;
      SkipCommon = readSetting("SkipCommon",SkipCommon);
      SkipCommon = CheckBox(10, y, 10, 0xFFFFFFff, " Skip Common Fish", SkipCommon, 0.7, 0.7);
      writeSetting("SkipCommon",SkipCommon);
      y = y + 20;
        if SkipCommon then
          lsPrintWrapped(10, y, 0, lsScreenX, 0.6, 0.6, 0xffff80ff,
          "If a Common Fish is caught, then switch to next lure.\n"
          .. "(Abdju, Chromis, Catfish, Carp, Oxyrynchus, Perch, Phagrus, Tilapia)");
          y = y + 44
          lsPrintWrapped(10, y, 0, lsScreenX, 0.6, 0.6, 0x80ff80ff,
          "Log entries are recorded to FishLog.txt in Automato/games/ATITD folder.");
          y = y + 35;
        end
      displayCommon = readSetting("displayCommon",displayCommon);
      displayCommon = CheckBox(10, y, 10, 0xFFFFFFff, " Display Common Fish Caught", displayCommon, 0.7, 0.7);
      writeSetting("displayCommon",displayCommon);
      y = y + 20;
      AutoFillet = readSetting("AutoFillet",AutoFillet);
      AutoFillet = CheckBox(10, y, 10, 0xFFFFFFff, " Automatically Fillet Fish", AutoFillet, 0.7, 0.7);
      writeSetting("AutoFillet",AutoFillet);
      y = y + 20;
      lsPrintWrapped(10, y, 0, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
      "---------------------------------------------------------------");
      y = y + 20;
      LogFails = readSetting("LogFails",LogFails);
      LogFails = CheckBox(10, y, 10, 0xFFFFFFff, " Log Failed Catches (Log Everything)", LogFails, 0.7, 0.7);
      writeSetting("LogFails",LogFails);

        if LogFails then
          LogStrangeUnusual = false;
          LogOdd = false;
        else
      y = y + 20;
      LogStrangeUnusual = readSetting("LogStrangeUnusual",LogStrangeUnusual);
      LogStrangeUnusual = CheckBox(10, y, 10, 0xFFFFFFff,
      " Log Strange & Unusual Fish Seen ...", LogStrangeUnusual, 0.7, 0.7);
      writeSetting("LogStrangeUnusual",LogStrangeUnusual);
      y = y + 20;
      LogOdd = readSetting("LogOdd",LogOdd);
      LogOdd = CheckBox(10, y, 10, 0xFFFFFFff, " Log Odd Fish Seen ...", LogOdd, 0.7, 0.7);
      writeSetting("LogOdd",LogOdd);
      end

        if setResume then
          buttonName = "Set/Resume";
        else
          buttonName = "Start";
        end
        if TotalCasts ~= nil then
          if lsButtonText(10, lsScreenY - 30, 0, 100, 0x00ff00ff, buttonName) then
            is_done = 1;
            setResume = false;
          end
        end
        if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFF0000ff,
          "End script") then
            error(quit_message);
        end
      lsSleep(10);
    end
  return count;
end

function SetupLureGroup()
  TLures = {};
  LastLure = "";

    if LastLure ~= nil then
      lureCounter = 0;
        for i = 1, #Lures,1 do
          lureList = findText(Lures[i]);
            if lureList then
              --Add Lure
              lureCounter = lureCounter + 1;
              statusScreen("Indexing Lures [" .. lureCounter .. "]\n" .. Lures[i],nil, 0.7);
              lsSleep(50);
              table.insert(TLures,Lures[i]);
            end
        end
    end
  lsSleep(100);
  return TLures;
end


function getLureList()
  for i = 1, #Lures, 1 do -- start from first line
    Lure = findText(Lures[i]);
      if Lure then
        return Lures[i]
      end
  end
end

function UseLure()
  checkBreak();
    if #TLures == 0 then
      if not muteSoundEffects then
        lsPlaySound("fail.wav");
      end
      error 'Can\'t find any lures on the pinned window. Did you run out of lures?'
    end

  CurrentLure = PlayersLures[CurrentLureIndex];

  if #TLures == 1 then
    QCurrentLure = CurrentLure;
    QCurrentLureIndex = CurrentLureIndex;
  elseif LostLure == 1 and not lastCast then
  --Do Nothing, continue...
  else
      QCurrentLure = PlayersLures[QCurrentLureIndex];
  end

  -- Uses lure according to CurrentLureIndex, which is used in PlayersLures which contains each lure the player has.
  lsDoFrame(); -- Blank the screen so next statusScreen messages isn't mixed/obscured with previous gui_refresh info on screen
  lsSleep(10);
  if LostLure == 1 and not lastCast then
    statusScreen("Lost Lure! | " .. lastLostLure .. "\nUsing same lure again!", nil, 0.7);
    table.insert(lostlure_log, lastLostLure .. " (" .. lastLostLureType .. ")");
    lsSleep(1000);
  elseif LostLure == 1 then
    statusScreen("Lost Lure! | " .. lastLostLure .. "\nSwitching Lures | " .. QCurrentLure, nil, 0.7);
    table.insert(lostlure_log, lastLostLure .. " (" .. lastLostLureType .. ")");
    lsSleep(1000);
  else
    statusScreen("Switching Lures | " .. QCurrentLure, nil, 0.7);
    lsSleep(750);
  end

  srReadScreen();
  --Refresh the fishing menu and re-index the new lure order
  fishingWindow = findText("Fishing Lure");
  safeClick(fishingWindow[0],fishingWindow[1])

  lsDoFrame();
  statusScreen("Indexing Lures ...",nil, 0.7);
  checkBreak()
  srReadScreen();
  getLureList();

  if QCurrentLureIndex > 30 then
    srClickMouseNoMove(down[0]+5,down[1]+5);
    lsSleep(200);
  elseif #PlayersLures > 30 then
    if up then
     srClickMouseNoMove(up[0]+5,up[1]+5);
    end
    lsSleep(200);
  end

  srReadScreen();

  if LostLure == 1 and not lastCast then
    lure = findText(PlayersLures[CurrentLureIndex]);
  else
    lure = findText(PlayersLures[QCurrentLureIndex]);
  end

  LostLure = 0;

  if lure then
    srClickMouseNoMove(lure[0]+12,lure[1]+5);
    lsSleep(200);
    srReadScreen();
    clickText(waitForText("Select as preferred Fishing Lure", 500));
    lsSleep(200);
  end
end

function checkIfMain(chatText)
    for j = 1, #chatText do
        if string.find(chatText[j][2], "^%*%*", 0) then
            return true;
        end
        for k, v in pairs(Chat_Types) do
            if string.find(chatText[j][2], k, 0, true) then
                return true;
            end
        end
    end
    return false;
end

function ChatReadFish(value)
    --Find the last line of chat
    local chatText = getChatText();
    if value ~= nil then
      numCaught, fishType = string.match(lastLine, "(%d+) deben ([^.]+)%."); -- Read next to last line of main chat
    else
      fishType = string.match(lastLine, "Caught [%w ']+ ([^.]+)%."); -- Read last line of main chat
    end
    if fishType then
      Sfish = string.gsub(fishType, "%W", "");
      if value ~= nil then
        SNum = numCaught
        GrandTotaldb = GrandTotaldb + SNum
      end
    end
    if value ~= nil then
      logMessage = ("[" .. CurrentLure .. " (" .. LureType .. ")] "  .. Sfish .. " (" .. SNum .. "db)");
      logType = "seasonal"
    else
      logMessage = ("[" .. CurrentLure .. " (" .. LureType .. ")] "  .. Sfish);
      logType = "common"
    end
    return logMessage, logType;
end

function findchat()
    --Find the last line of chat
    checkBreak();
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
        sleepWithStatus(500, "Looking for Main chat screen...\n\nMake sure main chat tab is showing and that the window is sized, wide enough, so that no lines wrap to next line..", nil, 0.7);
    end

    while #chatText < 2 do
        checkBreak();
        srReadScreen();
        chatText = getChatText();
        sleepWithStatus(500, "Error: We must be able to read at least the last 2 lines of chat!\n\nCurrently we only see " .. #chatText .. " lines ...\n\nYou can also type something in main chat or manually fish, once or twice, to bypass this error!", nil, 0.7);
    end



    --Read last line in chat
    lastLine = chatText[#chatText][2];
    lastLineParse = string.sub(lastLine,string.find(lastLine,"m]")+3,string.len(lastLine));

    --Read next to last line in chat
    lastLine2 = chatText[#chatText-1][2];
    lastLineParse2 = string.sub(lastLine2,string.find(lastLine2,"m]")+3,string.len(lastLine2));

    gui_refresh();
end

function findClockInfo()
  srReadScreen();
  coordinates = findCoords()
  if coordinates then
    coordX = coordinates[0];
    coordY = coordinates[1];
    Coordinates = coordX .. ", " .. coordY
  end
  fetchTime = getTime(1);
  theDateTime = string.sub(fetchTime,string.find(fetchTime,",") + 0); -- I know it's weird to have +0, but don't remove it or will error, shrug
  stripYear = string.sub(theDateTime,string.find(theDateTime,",") + 2);
  Time = string.sub(stripYear,string.find(stripYear,",") + 2);
  stripYear = "," .. stripYear
  Date = string.sub(stripYear,string.find(stripYear,",") + 1, string.len(stripYear) - string.len(Time) - 2);
  stripYear = string.sub(theDateTime,string.find(theDateTime,",") + 2);
end

function gui_refresh()
    checkBreak();

    if GrandTotalCasts == 0 or GrandTotalCasts == 1 then
      DateBegin = Date;
      TimeBegin = Time;
    end

    if GrandTotalCaught < 10 then
      last10 = GrandTotalCaught .. "/10";
    elseif GrandTotalCaught > 10 then
      last10 = "10/" .. GrandTotalCaught
    else
      last10 = 10;
    end

    --Stats (On Screen Display)
    --CurrentLureIndex  out of  PlayersLures
    winsize = lsGetWindowSize();

    if #PlayersLures == 0 then
        if not muteSoundEffects then
            lsPlaySound("fail.wav");
        end
        error 'Can\'t find any lures on the pinned window. Did you run out of lures?';
    elseif #PlayersLures == 1 then
        CurrentLureIndex = 1;
        QCurrentLureIndex = 1;

    elseif CurrentLureIndex > #PlayersLures then
        CurrentLureIndex = #PlayersLures;
        QCurrentLureIndex = 1;
    end

    local y = 2;
    CurrentLure = PlayersLures[CurrentLureIndex];
    QCurrentLure = PlayersLures[QCurrentLureIndex];
    lsPrintWrapped(10, y, 0, lsScreenX - 20, 0.5, 0.5, 0xc0c0ffff, Date .. " | " .. Time .. " | " .. Coordinates);
    nextLureChange = TotalCasts + 1 - castcount
    nextLureChangeMessageColor = 0xc0ffffff;

    if nextLureChange-1 <= 0 and LockLure then
        nextLureChangeMessageColor = 0xffff40ff;
        nextLureChangeMessage = "< LURE LOCKED! >  Unlock when ready to change Lure!";
    elseif nextLureChange-1 <= 0 and not LockLure then
        nextLureChangeMessageColor = 0xffff40ff;
        nextLureChangeMessage = "0 casts remaining ... Lure will change after this cast!";
    elseif LockLure then
        nextLureChangeMessageColor = 0xffff40ff;
        nextLureChangeMessage = "< LURE LOCKED! >  " .. nextLureChange-1 .. " casts remaining ...";
    else
        nextLureChangeMessage = nextLureChange-1 .. " casts remaining until Next Lure change!";
    end

    y = y + 12;
    lsPrintWrapped(10, y, 0, lsScreenX - 20, 0.5, 0.5, 0xc0ffc0ff, "Current Lure: " .. CurrentLureIndex .. " of " .. #PlayersLures .. "   " .. CurrentLure .. " (" .. LureType .. ")");
    y = y + 12;
    lsPrintWrapped(10, y, 0, lsScreenX - 20, 0.5, 0.5, nextLureChangeMessageColor, nextLureChangeMessage);
    y = y + 14;
    lsPrintWrapped(10, y, 0, lsScreenX - 20, 0.5, 0.5, 0xfcad86ff, "Cast Timer: " .. round(castWait/1000, 1) .. " s");
    y = y + 12;
    lsPrintWrapped(10, y, 0, lsScreenX - 20, 0.5, 0.5, 0xfbc3abff, "Last Timer: " .. round(lastCastWait/1000, 1) .. " s");
    lsSetCamera(0,0,lsScreenX*1.6,lsScreenY*1.6);

    if lsButtonText(160, y+20, 0, 20, 0xffffffff,
        "-"	) then
        QCurrentLureIndex = QCurrentLureIndex - 1;
        if QCurrentLureIndex < 1 then
            QCurrentLureIndex = #PlayersLures;
        end
    end

    if lsButtonText(187, y+20, 0, 20, 0xffffffff,
        "+"	) then
        QCurrentLureIndex = QCurrentLureIndex + 1
        if QCurrentLureIndex > #PlayersLures then
            QCurrentLureIndex = 1;
        end
    end

    lsSetCamera(0,0,lsScreenX*1.0,lsScreenY*1.0);

    lsPrintWrapped(137, y-5, 0, lsScreenX - 20, 0.5, 0.5, 0xfFFFFFff, "Next Lure (" .. QCurrentLureIndex .. "):");

    if skipLure or ((TotalCasts + 1 - castcount) <= 1 and not LockLure) then
        lsPrintWrapped(209, y-5, 0, lsScreenX - 20, 0.5, 0.5, 0xffffc0ff, QCurrentLure);
    else
        lsPrintWrapped(209, y-5, 0, lsScreenX - 20, 0.5, 0.5, 0xc0ffffff, QCurrentLure);
    end
    y = y + 13;
    lsPrintWrapped(10, y, 0, lsScreenX - 20, 0.5, 0.5, 0xffffc0ff, "Last " .. last10 .. " Fish Caught:\n");

    --Reset this string before showing last10 or allcaught fish below. Else the entries will multiply exponetially with entries from previous loops/call to this function
    last10caught = "";
    allcaught = "";
    lostlures = "";

    if #gui_log_fish > 10 then
        table.remove(gui_log_fish,11);
    end
    for i = 1, #gui_log_fish,1 do
        lsPrintWrapped(10, y + (14*i), 0, lsScreenX - 18, 0.5, 0.5, 0xffffdfff, gui_log_fish[i]);
    end

    for i = 1, #gui_log_fish2,1 do
        allcaught = allcaught .. gui_log_fish2[i] .. "\n";
    end

    for i = 1, #lostlure_log,1 do
        lostlures = lostlures .. lostlure_log[i] .. "\n";
    end


    lsPrintWrapped(115, winsize[1]-46, 0, lsScreenX - 20, 0.5, 0.5, 0xffffffff, "Odd Fish Seen: " .. GrandTotalOdd);
    lsPrintWrapped(115, winsize[1]-34, 0, lsScreenX - 20, 0.5, 0.5, 0xffffffff, "Unusual Fish Seen: " .. GrandTotalUnusual);
    lsPrintWrapped(115, winsize[1]-22, 0, lsScreenX - 20, 0.5, 0.5, 0xffffffff, "Strange Fish Seen: " .. GrandTotalStrange);
    lsPrintWrapped(10, winsize[1]-94, 0, lsScreenX - 20, 0.5, 0.5, 0xffff40ff, "- - - - - - - - - - - - - - - - - - - -");
    lsPrintWrapped(10, winsize[1]-82, 0, lsScreenX - 20, 0.5, 0.5, 0xc0ffc0ff, "Lures Switched: " .. GrandTotalLuresUsed-1);
    if lastLostLure ~= "" then
        lsPrintWrapped(10, winsize[1]-70, 0, lsScreenX - 20, 0.5, 0.5, 0xff8080ff, "Lures Lost: " .. GrandTotalLostLures .. "   -  Last: " .. lastLostLure .. " (" .. lastLostLureType .. ")");
    else
        lsPrintWrapped(10, winsize[1]-70, 0, lsScreenX - 20, 0.5, 0.5, 0xff8080ff, "Lures Lost: " .. GrandTotalLostLures);
    end
    lsPrintWrapped(10, winsize[1]-58, 0, lsScreenX - 20, 0.5, 0.5, 0xffff40ff, "- - - - - - - - - - - - - - - - - - - -");
    lsPrintWrapped(10, winsize[1]-46, 0, lsScreenX - 20, 0.5, 0.5, 0xc0ffffff, "Completed Casts: " .. GrandTotalCasts);
    lsPrintWrapped(10, winsize[1]-34, 0, lsScreenX - 20, 0.5, 0.5, 0xff8080ff, "Failed Catches: " .. GrandTotalFailed);
    lsPrintWrapped(10, winsize[1]-22, 0, lsScreenX - 20, 0.5, 0.5, 0xffffc0ff, "Fish Caught: " .. GrandTotalCaught .. " (" .. math.floor(GrandTotaldb) .. "db)");
    lsSetCamera(0,0,lsScreenX*1.6,lsScreenY*1.6);

    if lsButtonText(lsScreenX + 50, lsScreenY + 20, 0, 120, 0x6666FFff,
      "Options") then
      lsDoFrame();
      setResume = true;
      setOptions();
    end

    if lsButtonText(lsScreenX + 50, lsScreenY + 50, 0, 120, 0xFF0000ff,
      "End Script") then
      error(quit_message);
    end

    if skipLure or ((TotalCasts + 1 - castcount) <= 1 and not LockLure) then
        skipLureText = "Next Lure";
        skipLureTextColor = 0xffff40ff;
    else
        lastCast = false;
        skipLureText = "Next Lure";
        skipLureTextColor = 0xFFFFFFff;
    end

    if skipLure or ((TotalCasts + 1 - castcount) <= 0 and not LockLure) then
        lastCast = true;
    else
        lastCast = false;
    end

    if not finishUp then
        if lsButtonText(lsScreenX + 50, lsScreenY + 120, 0, 120, 0xffbb80ff,
            "Finish Up") then
            finishUp = true;
        end
    else
        if lsButtonText(lsScreenX + 50, lsScreenY + 120, 0, 120, 0xff8080ff,
            "Cancel ...") then
            finishUp = false;
        end
    end

    if lsButtonText(lsScreenX + 50, lsScreenY + 150, 0, 120, skipLureTextColor,
        skipLureText	) then
        if skipLure then
            skipLure = false;
        else
            skipLure = true;
            LockLure = false;
        end
    end


    if LockLure then
        LockLureColor =  0xffff40ff;
        LockLureText =  "Cancel Lock!";
    else
        LockLureColor = 0xFFFFFFff;
        LockLureText = "Lock Lure";
    end


    if lsButtonText(lsScreenX + 50, lsScreenY + 180, 0, 120, LockLureColor,
        LockLureText ) then

        if LockLure then
            LockLure =  false;
        else
            LockLure = true;
            skipLure = false;
        end
    end

    if #lostlure_log == 0 then
        lostlures = "*** No lures lost! ***";
    end

    if #gui_log_fish2 == 0 then
        allcaught = "*** No fish caught! ***";
    end

    WriteFishStats("Note this report is overwritten every time the macro runs. The stats are for last fishing session only!\nYou can safely delete this file, but it will be created the next time macro runs!\n\n\nStart Time: " .. DateBegin .. " @ " .. TimeBegin .. "\nEnd Time: " .. Date .. " @ " .. Time .. "\nLast Coordinates: " .. Coordinates .. "\n----------------------------------\nOdd Fish Seen: " .. GrandTotalOdd .. "\nUnusual Fish Seen: " .. GrandTotalUnusual .. "\nStrange Fish Seen: " .. GrandTotalStrange .. "\n----------------------------------\nLures Clicked: " .. GrandTotalLuresUsed .. "\nLures Lost: " .. GrandTotalLostLures .. " \n----------------------------------\nCasts: " .. GrandTotalCasts .. "\nFailed Catches: " .. GrandTotalFailed .. "\nFish Caught: " .. GrandTotalCaught .. " (" .. math.floor(GrandTotaldb) .. "db)\n----------------------------------\n\nAll lures lost this Session:\n\n" .. lostlures .. "\n\n\nAll fish caught this Session:\n\n".. allcaught);
    lsDoFrame();
    lsSleep(10);
end



function doit()

    askForWindow("MAIN chat tab MUST be showing and wide enough so that each line doesn't wrap.\n\n"
    .. "Right click the 'Fishing Lure' menu in your inventory and pin this window.\n\n"
    .. "History will be recorded in FishLog.txt and stats in FishStats.txt.");

    setOptions();
    PlayersLures = SetupLureGroup();  -- Fetch the list of lures from pinned lures window
    lsSleep(1000); -- Just a delay to let the sound effect finishing playing, not needed...

    findClockInfo();
    while not coordinates do
      checkBreak();
      findClockInfo();
      sleepWithStatus(1000, "Can not find Clock!\n\nMove your clock slightly.\n\nMacro will resume once found ...\n\nIf you do not see a clock, type /clockloc in chat bar.");
    end

    while 1 do

        checkBreak();
        srReadScreen();
        cast = srFindImage("fishing/fishicon.png", 100);
        OK = srFindImage("OK.png");
        if ignoreOK then
          OK = nil;  -- We got a popup box while examining isis ship pieces recently, prevent potential reindexing lures (No lure found, refreshing.. Below)
        end
        lsSleep(100)

        if not cast then
            if not muteSoundEffects then
                lsPlaySound("timer.wav");
            end
        end

        while not cast do
            checkBreak();
            srReadScreen();
            cast = srFindImage("fishing/fishicon.png", 100);
            sleepWithStatus(500, "Can\'t find Fishing icon ...");
        end


        if castcount == 0 or OK or skipLure then
            castcount = 1;
            skipLure = false;

            if #PlayersLures > 1 then
                LockLure = false;
            else
                LockLure = true;
            end


            if #PlayersLures > 1 and not OK then
                UseLure(); --Switch Lures
                GrandTotalLuresUsed = GrandTotalLuresUsed + 1;
            end


            if OK then
                srClickMouseNoMove(OK[0]+5,OK[1]+3);  -- Close the popup OK button
                sleepWithStatus(1500,"No " .. QCurrentLure .. " lure found!\nRefreshing lure list ...", nil, 0.7)
                PlayersLures = SetupLureGroup();
                if QCurrentLureIndex  > #PlayersLures or QCurrentLureIndex == 1 then
                    QCurrentLureIndex = 2;
                    CurrentLureIndex = 1;

                end
                UseLure(); --Switch Lures
            else
                CurrentLureIndex = QCurrentLureIndex;
                QCurrentLureIndex = QCurrentLureIndex + 1;
            end


            if QCurrentLureIndex  > #PlayersLures and not OK then
                --Last Lure, Prepare to go to first lure in list ...
                QCurrentLureIndex = 1;
                CurrentLureIndex = #PlayersLures;
            end

            --update log
            gui_refresh();


        elseif LostLure == 1 then
            UseLure(); -- Equip Same Lure again


        elseif castcount  > TotalCasts and not LockLure then
            --Reset
            castcount=0;

        else

            --Cast
            checkBreak();
            castWait = 0;
            findchat();
            lastLineFound = lastLineParse; -- Record last line before casting
            lastLineFound2 = lastLineParse2; -- Record next to last line before casting
              if AutoFillet then
                filletFish();  -- Search for "All Fish" pinned up. If so, fillet.
              end
            safeClick(cast[0]+3,cast[1]+3);
            lsSleep(200);
            srReadScreen();
            local cancel = srFindImage("cancel.png")
            if cancel then
              castcount=0;
              safeClick(cancel[0],cancel[1])
              lsSleep(1500); -- Wait for the fishing animation to finish
              UseLure(); -- The lure broke, switch to the next one
            end

            startTime = lsGetTimer();
            ignoreOK = nil;


            while 1 do
                findchat();
                OK = srFindImage("OK.png");
                writeLastTwoLines = nil;
                noWriteLog = nil;
                overweight = nil;
                skipOkOnce = nil; -- Helps prevent premature break, from OK box while checking Isis ship debris
                lsSleep(100);
                checkBreak();
                castWait = (lsGetTimer() - startTime);
                gui_refresh();

                if not muteSoundEffects and castWait/1000 > 2.5 and castWait/1000 < 2.7 then
                    lsPlaySound("fishingreel.wav");
                end

                for k, v in pairs(Isis_List) do
                  if string.find(lastLine, k, 0, true) then
                        -- If we get a message in chat from examining test of isis ship pieces, then ignore message and ignore popup box
                        -- This causes a short OK popup "Examining Relic", but then closes by itself. We don't want to confuse this for a popup from missing lure; ignore
                        lastLineFound = lastLineParse; -- Re-Record last line (with new message)
                        lastLineFound2 = lastLineParse2; -- Re-Record next to last line (with new message)
                        ignoreOK = 1;
                        noWriteLog = 1;
                  end
                end

                if OK then
                  skipOkOnce = 1; -- Prevents a premature break below from OK box while Examining Isis ship pieces, until next loop. Give a chance for ignoreOK to get recognized
                end

                for k, v in pairs(Ignore_List) do
                  if string.find(lastLine, k, 0, true) or not string.find(lastLine, "^%*%*", 0) then
                        -- If we get a message defined in Ignore_List (already fishing, item is from a forge, or no ** (player is speaking in main chat), then ignore
                        lastLineFound = lastLineParse; -- Re-Record last line (with new message)
                        lastLineFound2 = lastLineParse2; -- Re-Record next to last line (with new message)
                        noWriteLog = 1;
                  end
                end


                if (lastLineFound2 ~= lastLineParse2 or lastLineFound ~= lastLineParse) or (OK and not ignoreOK and not skipOkOnce) or ( (lsGetTimer() - startTime) > 20000 ) then
                    lastCastWait = castWait;
                    break;
                end
            end -- end while 1 do

            castcount = castcount + 1;
            GrandTotalCasts = GrandTotalCasts + 1;

            --Parse Chat
            CurrentLure = PlayersLures[CurrentLureIndex];
            caughtFish = false;
            oddFound = false;
            strangeUnusualFound = false;



            for k, v in pairs(Chat_Types) do
                if string.find(lastLine, k, 0, true) then
                    if v == "overweight" then
                        if string.match(lastLine2, "(%d+) deben ([^.]+)%.") then
                          caughtFish = true;  -- This will force it to parse the next to last line, instead of last line for any caught fish
                        end
                    end

                    if v == "achievement" then
                        -- If last message was 'You have achieved: Caught a blah blah', then caughtFish = true, parse the next to last line for fish caught
                        --  Also set bool to record both lines in log
                        writeLastTwoLines = 1;
                        caughtFish = true;  -- This will force it to parse the next to last line, instead of last line for any caught fish
                    end

                    if v == "alreadyfishing" or (OK and not ignoreOK) then
                        castcount = castcount - 1;
                        GrandTotalCasts = GrandTotalCasts - 1;
                    end

                    if v == "lostlure" then
                        if not muteSoundEffects then
                            lsPlaySound("boing.wav");
                        end
                        lastLostLure = CurrentLure;
                        lastLostLureType = LureType;
                        GrandTotalLostLures = GrandTotalLostLures + 1;
                        LostLure = 1;
                    --Reset, skip to next lure
                    --castcount=0;
                    end

                    if v == "odd" then
                        GrandTotalOdd = GrandTotalOdd + 1;
                        if LogOdd then
                            oddFound = true;
                        end
                    end

                    if v == "strange" then
                        GrandTotalStrange = GrandTotalStrange + 1;
                        if LogStrangeUnusual then
                            strangeUnusualFound = true;
                        end
                    end

                    if v == "unusual" then
                        GrandTotalUnusual = GrandTotalUnusual + 1;
                        if LogStrangeUnusual then
                            strangeUnusualFound = true;
                        end
                    end

                    if v == "caught" or caughtFish then
                        if v == "caught" and string.match(lastLine, "Caught a (%d+) deben ([^.]+)%.") then
                          caughtFish = true;
                          Fish = ChatReadFish(1); -- Parse last line of main chat
                        elseif v == "caught" and string.match(lastLine, "Caught [%w ']+ ([^.]+)%.") then
                          caughtFish = true;
                          Fish = ChatReadFish(); -- Parse next to last line of main chat

                            if not fishType then
                              caughtFish = nil;
                            else
                              overweight=1;
                            end
                        end

                        if caughtFish then
                        --Last 10 fish caught that displays on GUI
                          if logType == "common" and displayCommon then
                            GrandTotalCaught = GrandTotalCaught + 1
                            addlog = Sfish .. " | " .. CurrentLure
                            table.insert(gui_log_fish, 1, addlog);
                          elseif logType == "seasonal" then
                            GrandTotalCaught = GrandTotalCaught + 1
                            addlog = Sfish .. " (" .. SNum .. "db) | " .. CurrentLure
                            table.insert(gui_log_fish, 1, addlog);
                          end
                        -- All fish caught that displays in fishstats.txt
                        table.insert(gui_log_fish2, addlog);
                        FishType = Sfish;
                        if SkipCommon == true and LockLure == false then
                          if FishType == "Abdju" or FishType == "Chromis" or FishType == "Catfish" or FishType == "Carp" or FishType == "Oxyrynchus" or FishType == "Perch" or FishType == "Phagrus" or FishType == "Tilapia" then
                            castcount=0;
                          end
                        end
                        end
                    end
                    --Add more if v == "something" then statements here if needed
                end
                gui_refresh();
            end

            if not caughtFish then
              GrandTotalFailed = GrandTotalFailed + 1;
            end

            if v == "lure" or v == "alreadyfishing" or noWriteLog or not string.find(lastLine, "^%*%*", 0) then
            -- Do nothing
            elseif overweight then
              WriteFishLog("[" .. Date .. ", " .. Time .. "] [" .. Coordinates .. "] [" .. CurrentLure .. " (" .. LureType .. ")] " .. lastLineParse2 .. "\n");
            elseif writeLastTwoLines then
              WriteFishLog("[" .. Date .. ", " .. Time .. "] [" .. Coordinates .. "] [" .. CurrentLure .. " (" .. LureType .. ")] " .. lastLineParse2 .. "\n");
              WriteFishLog("[" .. Date .. ", " .. Time .. "] [" .. Coordinates .. "] [" .. CurrentLure .. " (" .. LureType .. ")] " .. lastLineParse .. "\n");
            elseif LogFails or caughtFish or oddFound or strangeUnusualFound then
              WriteFishLog("[" .. Date .. ", " .. Time .. "] [" .. Coordinates .. "] [" .. CurrentLure .. " (" .. LureType .. ")] " .. lastLineParse .. "\n");
            end

            gui_refresh();
        end
        if finishUp then
            lsPlaySound("Complete.wav");
            error("Finished up, per your request!");
        end
        gui_refresh();
    end
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function filletFish()
  srReadScreen();
  fillet = findText("All Fish");
    if fillet then
      clickAllText("All Fish");
    else
      clickAllImages("WindowEmpty.png", 5, 5, nil, nil);
    end
end
