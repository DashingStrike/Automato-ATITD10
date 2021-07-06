-- common_find.inc
--
-- Utility functions for managing game options
--
-- DO NOT INCLUDE THIS FILE! Include common.inc instead
--

TERRAIN = 1;
OBJECTS = 2;
GRASS = 3;
SHADOW = 4;
TIME_OF_DAY = 5;
LIGHT_INTENSITY = 6;
FOUNTAIN = 7;

FAST_GATHER = 1;
AUTO_TAKE = 2;
TAB_MOUSE = 3;
PLANT_STAND = 4;
FLAX_HOTKEYS = 5;
BRICK_HOTKEYS = 6;
GUILD_BOREHOLES = 7;
DROP_ONE = 8;

MOVE_KEYS = 22;

local videoOptionKeys = {
  "Terrain Horizon",
  "Number of Objects",
  "Tufts of Grass",
  "Shadow Quality",
  "Time-of-Day Lighting",
  "Light Intensity",
  "Fountain Detail",
};

local oneClickOptionKeys = {
  "Fast gather wood from trees",
  "Auto-take up to 50 items",
  "Make TAB work like mouse btn",
  "Plant all crops where you stand",
  "Enable hotkeys on flax",
  "Enable hotkeys on brickracks",
  "Automatically Guild Boreholes",
  "When dropping items, don't ...",
};

local interfaceOptionKeys = {
  [MOVE_KEYS] = "Movement",
}

local movements = {
  "Use WASD keys",
  "Use arrow keys",
  "Don't use either",
}

function getOneClickOptions()
  if not openOption("One-Click and Related") then
    return {};
  end

  local oneClickOptionsRange = getOptionsRange("options/one_click_options.png", "Waiting for One Click Options...");
  if not oneClickOptionsRange then
    return {};
  end

  local xs = findAllImages("options/x.png", oneClickOptionsRange);

  local options = {false, false, false, false, false, false, false, false};
  for i = 1, #xs do
    local row = math.floor((xs[i][1] - oneClickOptionsRange.y  - 16) / 18 + 0.5);
    options[row] = true;
  end

  return options;
end

function getVideoOptions()
  if not openOption("Video") then
    return {};
  end

  local videoOptionsRange = getOptionsRange("options/video_options.png", "Waiting for Video Options...");
  if not videoOptionsRange then
    return {};
  end

  local xs = findAllImages("options/x.png", videoOptionsRange);
  if #xs ~= #videoOptionKeys then
    return {};
  end

  local options = {};
  for i = 1, #xs do
    --convert pixel position to a 1 to 5 value
    options[i] = math.floor((xs[i][0] - videoOptionsRange.x + 6) / 17 + 0.5);
  end

  return options;
end

--This option menu is quite complex. Will add support for settings as-needed.
function getInterfaceOptions()
  if not openOption("Interface Options") then
    return {};
  end

  local interfaceOptionsRange = getOptionsRange("options/interface_options.png", "Waiting for Interface Options...");
  if not interfaceOptionsRange then
    return {};
  end

  local down = findImage("options/down.png", interfaceOptionsRange);
  if not down then
    return {};
  end

  local options = {};

  for i = 1, 10 do
    safeClick(down[0], down[1]);
    lsSleep(50);
  end
  lsSleep(100);

  srReadScreen();
  local radio = findImage("options/radio.png", interfaceOptionsRange);
  if not radio then
    return {};
  end

  options[MOVE_KEYS] = math.floor((radio[1] - interfaceOptionsRange.y - 342) / 18 + 0.5);

  return options;
end

function setOneClickOptions(options, prompt)
  if prompt ~= false and not promptOkay("This macro needs to configure your ATITD One Click Options.") then
    setOptionsError(oneClickOptionKeys, options, "One Click");
    return;
  end

  local current = getOneClickOptions();
  if #current ~= #oneClickOptionKeys then
    setOptionsError(oneClickOptionKeys, options, "One Click");
    return;
  end

  local oneClickOptionsRange = getOptionsRange("options/one_click_options.png", "Waiting for One Click Options...");
  if not oneClickOptionsRange then
    setOptionsError(oneClickOptionKeys, options, "One Click");
    return;
  end

  for i, value in pairs(options) do
    if value ~= current[i] then
      safeClick(oneClickOptionsRange.x + 11, oneClickOptionsRange.y + 16 + i * 18);
    end
  end

  local close = findImage("options/close.png", oneClickOptionsRange);
  if close then
    safeClick(close[0], close[1]);
  end

  lsSleep(200);
end

function setVideoOptions(options, prompt)
  if prompt ~= false and not promptOkay("This macro needs to configure your ATITD Video Options.") then
    setOptionsError(videoOptionKeys, options, "Video");
    return;
  end

  local current = getVideoOptions();
  if #current ~= #videoOptionKeys then
    setOptionsError(videoOptionKeys, options, "Video");
    return;
  end

  local videoOptionsRange = getOptionsRange("options/video_options.png", "Waiting for Video Options...");
  if not videoOptionsRange then
    setOptionsError(videoOptionKeys, options, "Video");
    return;
  end

  for i, value in pairs(options) do
    if value ~= current[i] then
      safeClick(videoOptionsRange.x - 6 + value * 17, videoOptionsRange.y + 16 + i * 18);
    end
  end

  local close = findImage("options/close.png", videoOptionsRange);
  if close then
    safeClick(close[0], close[1]);
  end

  if options[1] and options[1] ~= current[1] then
    local ok = waitForImage("options/ok.png", 10000, "Waiting for reloading graphics popup...");
    if ok then
      safeClick(ok[0], ok[1]);
    end
  end

  if options[6] and options[6] ~= current[6] then
    promptOkay("You must restart ATITD for the Light Intensity setting to take effect");
    error("Restart ATITD");
  end

  lsSleep(200);
end

function setInterfaceOptions(options, prompt)
  if prompt ~= false and not promptOkay("This macro needs to configure your ATITD Interface Options.") then
    setOptionsError(interfaceOptionKeys, options, "Interface");
    return;
  end

  local current = getInterfaceOptions();
  if #current ~= #interfaceOptionKeys then
    setOptionsError(interfaceOptionKeys, options, "Interface");
    return;
  end

  local interfaceOptionsRange = getOptionsRange("options/interface_options.png", "Waiting for Interface Options...");
  if not interfaceOptionsRange then
    setOptionsError(interfaceOptionKeys, options, "Interface");
    return;
  end

  if options[MOVE_KEYS] then
    safeClick(interfaceOptionsRange.x + 125, interfaceOptionsRange.y + 342 + options[MOVE_KEYS] * 18);
  end

  local close = findImage("options/close.png", interfaceOptionsRange);
  if close then
    safeClick(close[0], close[1]);
  end

  lsSleep(200);
end

function setOptionsError(keys, options, title)
  local msg = "Unable to read/set " .. title .. " Options. Please set them manually:\n";
  for i, value in pairs(options) do
    if value == true then
      value = "on";
    elseif value == false then
      value = "off";
    end

    if keys[i] == interfaceOptionKeys[i] and i == MOVE_KEYS then
      value = movements[value];
    end

    msg = msg .. "\n" .. keys[i] .. " to " .. value;
  end

  if not promptOkay(msg) then
    error(title .. " Options not set");
  end
end

function openOption(text)
  srReadScreen();
  local icon = findImage("options/icon.png");
  if not icon then
    return false;
  end

  local windowSize = srGetWindowSize();
  srSetMousePos(windowSize[0] / 2, 200);
  safeClick(icon[0], icon[1]);
  local option = waitForText(text, 5000, "Waiting for options to open");
  if not option then
    return false;
  end

  safeClick(option[0], option[1]);
  return true;
end

function getOptionsRange(image, message)
  local title = waitForImage(image,5000, message);
  if not title then
    return nil;
  end

  srSetWindowBorderColorRange(minThickWindowBorderColorRange, maxThickWindowBorderColorRange);
  local range = getWindowBorders(title[0], title[1]);
  srSetWindowBorderColorRange(minThinWindowBorderColorRange, maxThinWindowBorderColorRange);

  return range;
end
