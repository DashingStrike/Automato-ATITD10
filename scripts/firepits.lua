--require("math");
dofile("common.inc");
dofile("settings.inc");

askWinText = "Firepits Stoker v1.0 by Ashen --\n\nRecommended to run in F8F8 mode zoomed all the way in with screen locked.\n\n" .. chat_minimized .. "The script will run indefinitely until told to quit.\n\nPress Shift over ATITD window.";

stokedelay = 100;
pitcount = readSetting("firepits_count", 4);
pitstoked = {};
pitlocs = {};
pitstokecnt = {};
pitchangecnt = {};
PIT_THRESH_UNSTOKE = 20;
PIT_THRESH_STOKE = 6;
PIT_TEST_POINTS = 15;

function doit()
  --math.randomseed(lsGetTimer());
  askForWindow(askWinText);
  askForPitCounts();
  askForPitLocs();
  runStokeMonitor();
end


-------------------------------------------------------------------------------
-- pixelBufMatch(anchor, offset, color, tolerance)
--
-- Checks to see whether the screen pixel at anchor+offset matches a
-- given color.
--
-- anchor -- Base location to check
-- offset -- Offset from base location
-- color -- Color to check against
-- tolerance -- 0 means exact match, >= 255 means any color (default 0)
--
-- Returns true if the colors match within tolerance.
-------------------------------------------------------------------------------

function pixelMatchBuf(anchor, offset, color, tolerance)
  if not anchor or not offset or not color then
    error("Incorrect number of arguments for pixelMatch()");
  end
  return pixelMatchBufList(anchor, offset, {color}, tolerance);
end

-------------------------------------------------------------------------------
-- pixelMatchBufList(anchor, offset, colors, tolerance)
--
-- Checks to see whether the screen pixel at anchor+offset matches a
-- given color.
--
-- anchor -- Base location to check
-- offset -- Offset from base location
-- colors -- Colors to check against, returns true if any of them are matched.
-- tolerance -- 0 means exact match, >= 255 means any color (default 0)
--
-- Returns true if the colors match within tolerance.
-------------------------------------------------------------------------------

function pixelMatchBufList(anchor, offset, colors, tolerance)
  if not anchor or not offset or not colors then
    error("Incorrect number of arguments for pixelMatchList()");
  end
  if not tolerance then
    tolerance = 0;
  end
  local result = false;
  local screenColor = srReadPixelFromBuffer(anchor[0] + offset[0],
    anchor[1] + offset[1]);
  for i=1,#colors do
    local currentMatch = true;
    local diffs = calculatePixelDiffs(colors[i], math.floor(screenColor/256));
    for j=1,#diffs do
      if diffs[j] > tolerance then
        currentMatch = false;
        break;
      end
    end
    if currentMatch then
      result = true;
      break;
    end
  end
  return result;
end

function askForPitCounts()
  local is_done = false;
  local is_count = true;

  while not (is_done and is_count) do
    checkBreak();

    is_done = false;
    lsPrint(10, 10, 0, 1.0, 1.0, 0xffffffff, "How many firepits?");

    is_done, pc = lsEditBox("pitcount", 10, 40, 0, 50, 30, 1.0, 1.0, 0x000000ff, pitcount);
    pc = tonumber(pc);

    if ((not pc) or (pc < 1)) then
      is_count = false;
      lsPrint(10, 80, 0, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
    else
      is_count = true;
    end

    if (lsButtonText(10, lsScreenY - 30, 0, 100, 0xFFFFFFff, "Continue")) then
      is_done = true;
    end

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff, "End script") then
      error "Clicked End Script button";
    end

    lsDoFrame();
    lsSleep(10);
  end

  pitcount = pc;

  for i=0,pitcount-1 do
    pitstoked[i] = false;
    pitstokecnt[i] = 0;
    pitchangecnt[i] = 0;
    pitlocs[i] = {0,0};
  end

  writeSetting("firepits_count", pitcount);
end

function printPitLocs(gotpits)
  local x = 5;
  local y = 5;

  lsPrint(x, y, 0, 0.7, 0.7, 0xffffffff, "Press CTRL over each firepit near");
  y = y + 20;
  lsPrint(x, y, 0, 0.7, 0.7, 0xffffffff, "the center. The script will sample");
  y = y + 20;
  lsPrint(x, y, 0, 0.7, 0.7, 0xffffffff, "pixels within +/- 20 x/y of point.");
  y = y + 40;

  for ii=0,gotpits-1 do
    lsPrint(x, y, 0, 0.7, 0.7, 0xffffffff, "Pit #" .. ii+1 .. ": (" .. pitlocs[ii][0] .. ", " .. pitlocs[ii][1] .. ")");
    y = y + 20;
  end

  if (gotpits==pitcount) then
    for pitnum=0,pitcount-1 do
      srSetMousePos(pitlocs[pitnum][0], pitlocs[pitnum][1]);
      lsSleep(100);
    end
    y = y + 20;
    lsPrint(x, y, 0, 0.7, 0.7, 0xffffffff, "Done. Start your firepits when ready!");
  end

  lsDoFrame();
end

function askForPitLocs()
  local gotpits = 0;

  for i=0,pitcount-1 do
    printPitLocs(gotpits);

    while lsControlHeld() do
      printPitLocs(gotpits);
      checkBreak();
      lsSleep(50);
    end

    while not lsControlHeld() do
      printPitLocs(gotpits);
      checkBreak();
      lsSleep(50);
    end

    pitlocs[i][0],pitlocs[i][1] = srMousePos();
    gotpits = gotpits + 1;
  end

  printPitLocs(gotpits);
  lsSleep(3000);
end

function isStokable(pitnum)
  stokepts = 0;

  ofs = makePoint(0, 0);

  x = pitlocs[pitnum][0];
  y = pitlocs[pitnum][1];

  for i=-20,20 do
    checkBreak();

    if (pixelMatchBuf(makePoint(x + i, y), ofs, 0xFFFFFF, 0)) then
      stokepts = stokepts + 1;
    end
    if (pixelMatchBuf(makePoint(x, y + i), ofs, 0xFFFFFF, 0)) then
      stokepts = stokepts + 1;
    end

    if (stokepts >= PIT_TEST_POINTS) then
      return true;
    end
  end

  return false;
end

function doStoke(pitnum)
  while (lsShiftHeld() or lsControlHeld()) do
    checkBreak();
    lsSleep(50);
  end
  x,y = srMousePos();
  srSetMousePos(pitlocs[pitnum][0], pitlocs[pitnum][1]);
  lsSleep(200);
  srKeyEvent('S');
  lsSleep(100);
  srSetMousePos(x, y);
end

function updateStatus()
  x = 5;
  y = 5;

  lsPrint(x, y, 0, 0.7, 0.7, 0xffffffff, "Monitoring firepits...");
  y = y + 40;

  for i=0,pitcount-1 do
    if (pitstoked[i]) then
      state = "Stoked";
      color = 0xff0000ff;
    else
      state = "Waiting";
      color = 0xffffffff;
    end

    lsPrint(x, y, 0, 0.7, 0.7, color, "Pit #" .. i+1 .. ": " .. state .. " (" .. pitstokecnt[i] .. " stokes) [" .. pitchangecnt[i] .. "]");
    y = y + 20;
  end

  y = y + 20;

  if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff, "End script") then
    error "Clicked End Script button";
  end

  lsDoFrame();
end

function runStokeMonitor()
  while true do
    checkBreak();
    srReadScreen();

    for i=0,pitcount-1 do
      if (isStokable(i)) then
        if (pitstoked[i] == false) then
          pitchangecnt[i] = pitchangecnt[i] + 1;

          if (pitchangecnt[i] >= PIT_THRESH_STOKE) then
            doStoke(i);
            pitstoked[i] = true;
            pitstokecnt[i] = pitstokecnt[i] + 1;
            pitchangecnt[i] = PIT_THRESH_UNSTOKE;
          end
        else
          if (pitchangecnt[i] < PIT_THRESH_UNSTOKE) then
            pitchangecnt[i] = pitchangecnt[i] + 1;
          end
        end
      else
        pitchangecnt[i] = pitchangecnt[i] - 1;

        if (pitchangecnt[i] < 0) then
          pitchangecnt[i] = 0;
        end

        if (pitstoked[i] == true) then
          if (pitchangecnt[i] <= 0) then
            pitstoked[i] = false;
          end
        end
      end
    end

    updateStatus();
    lsSleep(100);
  end
end
