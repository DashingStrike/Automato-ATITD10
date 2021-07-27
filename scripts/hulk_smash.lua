dofile("common.inc");
dofile("settings.inc");

local stoneCoords = {
  {0, -20},
  {15, -20},
  {-15, -20},
  {0, -35},
  {30, -20},
  {-30, -20},
  {45, -20},
  {-45, -20},
  {15, -35},
  {-15, -35},
  {0, -50},
  {30, -35},
  {-30, -35},
  {45, -35},
  {-45, -35},
  {15, -50},
  {-15, -50},
  {30, -50},
  {-30, -50},
  {45, -50},
  {-45, -50},
};

function isStoneAtPixel(x, y)
  local rgb = pixelRGB(x, y);

  return math.abs(rgb[1] - rgb[2]) < 4 and math.abs(rgb[1] - rgb[3]) < 4;
end

function faceNorth()
  local xyWindowSize = srGetWindowSize();
  safeClick(xyWindowSize[0] / 2 - 10, xyWindowSize[1] / 2 + 170);
  lsSleep(500);
  safeClick(xyWindowSize[0] / 2 - 10, xyWindowSize[1] / 2 - 100);
  lsSleep(500);
end

function drop()
  srReadScreen();
  clickAllImages("veg_janitor/dead.png");

  srReadScreen();
  clickAllText("Stone (");

  srReadScreen();
  local windows = findAllText("Stone (", nil, REGION);
  while not windows do
    if not lsPrompOkay("Please pin up the windows for all the stones you want to smash, or pickup some more stones to smash if they are all empty.") then
      error "Macro Cancelled";
    end

    srReadScreen();
    clickAllImages("veg_janitor/dead.png");

    srReadScreen();
    windows = findAllText("Stone (", nil, REGION);
  end

  for windowIndex = 1, #windows do
    local title = findText("Stone (", windows[windowIndex]);
    if not title then
      error "Couldn't read title";
    end

    local count = tonumber(string.match(title[2], "(%d+)"));
    if not count then
      error "Couldn't read stone count";
    end

    for _ = 1, count do
      local drop = findText("Drop", windows[windowIndex]);
      if drop then
        clickText(drop);

        local ok = waitForImage("ok2.png", 250, "Waiting for OK button");
        if ok then
          srKeyEvent("1");
          lsSleep(100);
          safeClick(ok[0], ok[1]);
          waitForNoImage("ok2.png", 250, "Waiting for OK button to hide");
        end
      end
    end
  end

  return #windows > 0
end

function findStones()
  local xyWindowSize = srGetWindowSize();
  local centerX = xyWindowSize[0] / 2;
  local centerY = xyWindowSize[1] / 2 - 35;

  srReadScreen();
  for i = 1, #stoneCoords do
    local x = centerX + stoneCoords[i][1];
    local y = centerY + stoneCoords[i][2];
    if isStoneAtPixel(x, y) then
      return x, y;
    end
  end

  return nil;
end

function smash()
  local stoneX, stoneY = findStones();
  while stoneX ~= nil do
    checkBreak();
    srSetMousePos(stoneX, stoneY);
    lsSleep(10);
    srKeyEvent("s");
    sleepWithStatus(4000, "Waiting for animation");

    stoneX, stoneY = findStones();
  end
end

function doit()
  askForWindow([[
Hulk Smash!

PICK UP YOUR CATS! They play with dropped stones.

This macro will drop all stones you have pinned
one at a time, then smash them all!

Gravel left behind under the stone pile will
also be scooped up, but nothing that moved.

Try gather.lua to pickup the resulting mess
if you don't have big hands.

Hover over the ATITD window and press shift.
]]);

  setCameraView(CARTOGRAPHER2CAM);
  lsSleep(1000);
  faceNorth();

  while true do
    if not drop() then
      return;
    end
    smash();
  end
end
