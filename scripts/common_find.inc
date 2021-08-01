-- common_find.inc
--
-- Utility functions for searching for information on screen.
--
-- DO NOT INCLUDE THIS FILE! Include common.inc instead
--

-- List of colors which mark the edge of a window.
-- T8: WINDOW_COLORS = {0x72502EFF, 0x714f2eff, 0x6f4e2dff, 0x785431ff};

--This version includes changes to how OCR works
lsRequireVersion(2,59);

-- The colors used by srFindFirst/NextTextRegion and srGetWindowBorders to determine
-- the innermost border pixels, for thin border windows
minThinWindowBorderColorRange = 0x806144;
maxThinWindowBorderColorRange = 0x886952;
srSetWindowBorderColorRange(minThinWindowBorderColorRange, maxThinWindowBorderColorRange);

-- The colors used by srFindFirst/NextTextRegion and srGetWindowBorders to determine
-- the innermost border pixels, for thick border windows
minThickWindowBorderColorRange = 0x644026;
maxThickWindowBorderColorRange = 0x6D472A;

-- The colors used by srFindFirst/NextTextRegion and srGetWindowBorders to determine
-- the innermost border pixels, for utility menus
minUtilityWindowBorderColorRange = 0x3A3A3C;
maxUtilityWindowBorderColorRange = 0x3F3F46;

-- The colors that srStripRegion/Screen() looks for to decide it should invert (and
-- treat as background when stripping)
minSetWindowInvertColorRange = 0x1E2E31;
maxSetWindowInvertColorRange = 0x929DA0;
srSetWindowInvertColorRange(minSetWindowInvertColorRange, maxSetWindowInvertColorRange);

-- The color range that is treated as window background and stripped in srStripRegion()
minWindowBackgroundColorRange = 0x283C42;
maxWindowBackgroundColorRange = 0xFFFFFA;
srSetWindowBackgroundColorRange(minWindowBackgroundColorRange,maxWindowBackgroundColorRange);

-------------------------------------------------------------------------------
-- findAllImages(image_name, range, tol)
--
-- Returns an array of all positions matching the image.
--
-- image_name -- path and filename used to fetch the image
-- range (optional) -- box to search in (defaults to screen)
-- tol (optional) -- tolerance value used for comparison
-------------------------------------------------------------------------------

function findAllImages(image_name, range, tol)
  if not image_name then
    error("Incorrect number of arguments for findAllImages()");
  end
  if not range then
    local size = srGetWindowSize();
    range = makeBox(0, 0, size[0], size[1]);
  end
  return findAllImagesInRange(image_name, range.x, range.y,
            range.width, range.height, tol);
end

function findImage(image_name, range, tol)
  if not range then
    local size = srGetWindowSize();
    range = makeBox(0, 0, size[0], size[1]);
  end
  if not tol then
    tol = 5000;
  end
  return srFindImageInRange(image_name, range.x, range.y,
                            range.width, range.height, tol);
end

-------------------------------------------------------------------------------
-- findAllImagesInRange(image_name, startX, startY, width, height, tol)
--
-- Returns an array of all positions matching the image.
--
-- image_name -- path and filename used to fetch the image
-- startX, startY -- origin of search region
-- width, height -- size of search region
-- tol (optional) -- tolerance value used for comparison
-------------------------------------------------------------------------------

function findAllImagesInRange(image_name, startX, startY, width, height, tol)
  if not image_name or not startX or not startY or not width or not height then
    error("Incorrect number of arguments for findAllImages()");
  end
  if not tol then
    tol = 5000;
  end
  local endX = startX + width;
  local endY = startY + height;
  local xyImageSize = srImageSize(image_name);
  local y = startY;
  local buttons = {};
  while 1 do
    local pos = srFindImageInRange(image_name, startX, y, width, endY-y, tol);
    if not pos then
      break;
    end
    buttons[#buttons+1] = pos;
    local newy = pos[1] + 1;
    y = pos[1];
    -- Look for other ones on the exact same line
    while 1 do
      local x = pos[0]+1;
      pos = srFindImageInRange(image_name, x, y,
                               endX - x, math.min(xyImageSize[1], endY - y),
                               tol);
      if not pos then
        break;
      end
      buttons[#buttons+1] = pos;
    end
    y = newy;
    end
  return buttons;
end

-------------------------------------------------------------------------------
-- findImageInWindow(image_name, x, y, tol)
--
-- Returns a position matching an image bounded by an atitd window or
-- nil if there is no match.
--
-- image_name -- path and filename used to fetch image
-- x, y -- any location within the window
-- tol (optional) -- tolerance value used for comparison
-------------------------------------------------------------------------------

function findImageInWindow(image_name, x, y, tol)
  if not image_name or not x or not y then
    error("Incorrect number of arguments for findImageInWindow()");
  end
  if not tol then
    tol = 5000;
  end
  local result = nil;
  local range = getWindowBorders(x, y);
  if range then
    result = srFindImageInRange(image_name, range.x, range.y,
                                range.width, range.height, tol);
  end
  return result;
end

-- If set, only a line of text matching the text exactly will
-- suffice. If unset, any line containing the text will be returned.
EXACT = 1;
-- If set, this window does not contain a pin in the corner.
-- If set, returns the window containing the text rather than the parse.
REGION = 4;
-- If set ignores all but the first instance in each window.
EXACT_REGION = 5;
REGEX = 8;

function findText(text, window, flag, sizemod)
  local parses = findAllText(text, window, flag, sizemod);
  local result = nil;
  if #parses >= 1 then
    result = parses[1];
  end
  return result;
end

-- Set of window sizes for sizemod field. Values listed are added to x, y,
-- width, height of each window, respectively
NOPIN = {0, 0, 0, 0};
PINNED = {0, 0, -20, 0};
INFO_POPUP = {10, 10, -40, -62};
CPLX_ITEM_CHOOSE = {9, 69, -40, -103};
SLIGHT_INSET = {10, 0, -20, 0};
BROWSE_INVENTORY = {3, 40, -379, -11};
BROWSE_CHEST = {354, 40, -379, -11};

function findAllText(text, window, flag, sizemod)
  if flag == NOPIN then
    sizemod = NOPIN
    flag = nil;
  end
  if sizemod == nil then
    sizemod = PINNED;
  end
  if #sizemod ~= 4 then
    error("Incorrect sizemod argument to text function");
  end
  local exact = flag and (flag % 2 == 1);
  local region = flag and (math.floor(flag/4) % 2 == 1);
  local regex = flag and (math.floor(flag/8) % 2 == 1);

  if regex and exact then
    error("Cannot use both REGEX and EXACT flags");
  end

  local results = {};
  local windowList = {window};
  if not window then
    windowList = findAllWindows();
  end

  for i=1,#windowList do
    local current = makeBox(windowList[i].x + 7, windowList[i].y + 4,
          windowList[i].width - 12, windowList[i].height - 7); -- Basic magic # window resizing
    current = makeBox(current.x + sizemod[1], current.y + sizemod[2], current.width + sizemod[3],
                      current.height + sizemod[4]); -- Add in custom window resizing
    local parses = parseWindow(current);
    for j=1,#parses do
      if not text or (exact and parses[j][2] == text)
                  or (not exact and string.find(parses[j][2], text, 1, true))
                  or (regex and string.find(parses[j][2], text, 1)) then
        if region then
          table.insert(results, windowList[i]);
          break;
        else
          table.insert(results, parses[j]);
        end
      end
    end
  end
  return results;
end

function findAllWindows()
  local windows = {};
  local current = srFindFirstTextRegion();
  while current do
  local mainChatRed = srFindImageInRange("ocr/mainChatRed.png", current[0], current[1]-20, current[2], current[3]);
  local mainChatWhite = srFindImageInRange("ocr/mainChatWhite.png", current[0], current[1]-20, current[2], current[3]);
  local friends = srFindImageInRange("ocr/friends.png", current[0], current[1], current[2], current[3]);
  local inventory = srFindImageInRange("ocr/inventory.png", current[0], current[1], current[2], current[3]);

    if not mainChatRed and not mainChatWhite and not friends and not inventory then
      breakupRegion(regionToBox(current), windows);
    end
      current = srFindNextTextRegion(current[0] + 1, current[1]);
  end
  return windows;
end

function breakupRegion(region, windows)
  local current = getWindowBorders(region.x + 5, region.y + 5);
  table.insert(windows, current);
  if region.width - current.width > 10 then
    breakupRegion(makeBox(region.x + current.width + 8, region.y,
        region.width - current.width - 8, region.height),
        windows);
  end
  if region.height - current.height > 4 then
    breakupRegion(makeBox(region.x, region.y + current.height + 2,
        current.width + 8, region.height - current.height - 2),
        windows);
  end
end

-------------------------------------------------------------------------------
-- parseWindow(window)
--
-- Strips a window, then returns an array of all the parses in that window.
--
-- window -- box demarking the in-game window to parse
-------------------------------------------------------------------------------

function parseWindow(window)
  local text = parseText(window.x, window.y, window.width, window.height);
  if text == nil then
    text = {};
  end
  return text;
end

-------------------------------------------------------------------------------
-- pixelMatch(anchor, offset, color, tolerance)
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

function pixelMatch(anchor, offset, color, tolerance)
  if not anchor or not offset or not color then
    error("Incorrect number of arguments for pixelMatch()");
  end
  return pixelMatchList(anchor, offset, {color}, tolerance);
end

-------------------------------------------------------------------------------
-- pixelMatchFromBuffer(anchor, offset, color, tolerance)
--
-- Checks to see whether the buffered screen pixel at anchor+offset matches a
-- given color.
--
-- anchor -- Base location to check
-- offset -- Offset from base location
-- color -- Color to check against
-- tolerance -- 0 means exact match, >= 255 means any color (default 0)
--
-- Returns true if the colors match within tolerance.
-------------------------------------------------------------------------------

function pixelMatchFromBuffer(anchor, offset, color, tolerance)
  if not anchor or not offset or not color then
    error("Incorrect number of arguments for pixelMatchFromBuffer()");
  end
  return pixelMatchListFromBuffer(anchor, offset, {color}, tolerance);
end

-------------------------------------------------------------------------------
-- pixelMatchList(anchor, offset, colors, tolerance)
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

function pixelMatchList(anchor, offset, colors, tolerance)
  if not anchor or not offset or not colors then
    error("Incorrect number of arguments for pixelMatchList()");
  end
  if not tolerance then
    tolerance = 0;
  end
  local result = false;
  local screenColor = srReadPixel(anchor[0] + offset[0],
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

function pixelDiffs(x, y, color)
  local screenColor = srReadPixelFromBuffer(x, y);
  return calculatePixelDiffs(color, math.floor(screenColor/256));
end

function calculatePixelDiffs(left, right)
  local result = {};
  for i=1,3 do
    result[4-i] = math.abs((left % 256) - (right % 256));
    left = math.floor(left / 256);
    right = math.floor(right / 256);
  end
  return result;
end

-------------------------------------------------------------------------------
-- pixelMatchListFromBuffer(anchor, offset, colors, tolerance)
--
-- Checks to see whether the buffered screen pixel at anchor+offset matches a
-- given color.
--
-- anchor -- Base location to check
-- offset -- Offset from base location
-- colors -- Colors to check against, returns true if any of them are matched.
-- tolerance -- 0 means exact match, >= 255 means any color (default 0)
--
-- Returns true if the colors match within tolerance.
-------------------------------------------------------------------------------

function pixelMatchListFromBuffer(anchor, offset, colors, tolerance)
  if not anchor or not offset or not colors then
    error("Incorrect number of arguments for pixelMatchListFromBuffer()");
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

-------------------------------------------------------------------------------
-- pixelRGB(x, y)
--
-- Read the pixel at x, y and return RGB
--
-- Return rgb hash where 1 = red, 2 = green, 3 = blue
-------------------------------------------------------------------------------
function pixelRGB(x, y)
  local color = srReadPixelFromBuffer(x, y);
  return {
    math.floor(color/256/256/256) % 256,
    math.floor(color/256/256) % 256,
    math.floor(color/256) % 256,
  };
end

-------------------------------------------------------------------------------
-- ocrNumber(startX, startY, characterSet)
--
-- Looks for a string of digits of a given character set and returns
-- them as a number.
--
-- startX, startY -- position to start looking
-- characterSet (optional) -- constant defining images and sizes:
--                            NORMAL_SET (default), BOLD_SET, SMALL_SET
-------------------------------------------------------------------------------

NORMAL_SET = 0;
BOLD_SET = 1;
SMALL_SET = 2;

function ocrNumber(startX, startY, characterSet)
  if not startX or not startY then
    error("Incorrect number of arguments for ocrNumber()");
  end
  local prefix, sizeX, sizeY = getCharacterSet(characterSet);

  -- find first digit
  local x = startX;
  local y = startY;
  local digit=nil;
  decimal = false;
  local offset=0;
  while (not digit) and (offset < 10) do
    digit = findDigit(x, y, sizeX, sizeY, prefix);
    if not digit then
      x = x+1;
      offset = offset + 1;
    end
  end
  -- find remaining digits
  local result = 0;
  while digit do
    if decimal == false then
      result = result * 10 + digit;
      x = x + sizeX;
    else
      result = result + digit/10^ afterDecimal;
      afterDecimal = afterDecimal + 1;
      x = x + sizeX;
    end
    digit = findDigit(x, y, sizeX, sizeY, prefix);
    if digit == "." then
      decimal = true;
      afterDecimal = 1;
      x = x + 4;
      digit = findDigit(x, y, sizeX, sizeY, prefix);
    end
  end
  return result;
end

function findDigit(x, y, sizeX, sizeY, prefix)
  for i=0, 9 do
    if srFindImageInRange(prefix .. i .. ".png", x, y, sizeX, sizeY, 5000) then
      return i;
    end
  end

  if prefix == "ocr/" then
    if srFindImageInRange("ocr/decimals.png", x, y, sizeX, sizeY, 5000) then
      return ".";
    end
  end
end

function getCharacterSet(characterSet)
  if characterSet == BOLD_SET then
    return "ocr/bold/", 7, 9;
  elseif characterSet == SMALL_SET then
    return "ocr/small/", 6, 8;
  else
    return "ocr/default/", 6, 9;
  end
end

-- replacement for srFindChatRegion() for ATITD T9
function findChatRegionReplacement()
  local pos = findChatRegionSub();
  if not pos then
    return;
  end

  srSetWindowBorderColorRange(minThickWindowBorderColorRange, maxThickWindowBorderColorRange);

  local borders = srGetWindowBorders(pos[0], pos[1]+20);
  -- Offset past blue background into text area
  borders[0] = borders[0] + 5;
  borders[1] = borders[1] + 5;
  borders[2] = borders[2] - 22; -- in past scroll bar
  borders[3] = borders[3] - 29; -- above text entry
  borders[2] = borders[2] - borders[0]; -- return "width", not "right"
  borders[3] = borders[3] - borders[1]; -- return "height", not "bottom"

  srSetWindowBorderColorRange(minThinWindowBorderColorRange, maxThinWindowBorderColorRange);
  return borders;
end

function findChatRegionSub()
  local pos;
  local mainChatRed;
  local mainChatWhite;
  mainChatRed = srFindImage("ocr/mainChatRed.png");
  mainChatWhite = srFindImage("ocr/mainChatWhite.png");
  if mainChatRed then
    pos = mainChatRed;
  elseif mainChatWhite then
    pos = mainChatWhite;
  else
    pos = nil;
  end
  return pos;
end

function findClockRegion()
  local factionTolerance = 1000;
  local clockUpperLeftX;
  local clockUpperLeftY;
  local neutral = srFindImage("faction/faction_neutral.png", factionTolerance);
  local hyksos = srFindImage("faction/faction_hyksos.png", factionTolerance);
  local kush = srFindImage("faction/faction_kush.png", factionTolerance);
  local meshwesh = srFindImage("faction/faction_meshwesh.png", factionTolerance);

  if neutral then
    faction = "Neutral";
    srSetWindowInvertColorRange(0x804D22, 0xCFA37B);
    clockUpperLeftX = neutral[0];
    clockUpperLeftY = neutral[1];

  elseif hyksos then
    faction = "Hyksos";
    srSetWindowInvertColorRange(0x68640E, 0xC0B162);
    clockUpperLeftX = hyksos[0];
    clockUpperLeftY = hyksos[1];

  elseif kush then
    faction = "Kush";
    srSetWindowInvertColorRange(0x0F2B13, 0x68906F);
    clockUpperLeftX = kush[0];
    clockUpperLeftY = kush[1];

  elseif meshwesh then
    faction = "Meshwesh";
    srSetWindowInvertColorRange(0x002E2E, 0x59A1A2);
    clockUpperLeftX = meshwesh[0];
    clockUpperLeftY = meshwesh[1];

  else
    --error("Clock could not be detected in findClockRegion()");
    faction = "Clock not detected";
  end

  if faction ~= "Clock not detected" then
    clockUpperLeftX = clockUpperLeftX - 4;
    local clockWidth = 275;
    local clockHeight = 65;
    clockRegion = makeBox(clockUpperLeftX, clockUpperLeftY, clockWidth, clockHeight);
  end
  return clockRegion;
end

function CheckHoverTray()
-- Check if the Mouse is hovering over the Tray Bar (Grass, Sand, Mud, etc icon tray)
-- If a macro is looking for grass, slate, limestone, etc icon, then we might need to check if mouse is currently hovering the tray.
-- When mouse is hovering a tray, the icon highlights with an orange color and adds a tooltip. This can potentially cause errors.
-- Example usage: if hoverTray() then sleepWithStatus(100,"I'm hovering the Tray") else sleepWithStatus(100,"I'm NOT hovering Tray")
-- Returns true if mouse is hovering the tray; returns false if it is NOT hovering the tray.
-- You could do something like moveMouse to another position when true.

  srReadScreen();
  local tray = srFindImage("icon_tray_opened.png")
  local mousePos = getMousePos()
    if tray and (mousePos[0] > tray[0]+30 and mousePos[0] < tray[0]+570) and (mousePos[1] > tray[1]-50 and mousePos[1] <  tray[1]+50) then
      return true;
    else
      return false;
    end
end
