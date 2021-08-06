dofile("common.inc");
dofile("paint_common.inc");

local paintData = {
  {
    name = "Cabbage Juice",
    ppName = "Cabbage",
    color = {128, 64, 144},
    enabled = true,
    reactions = {
    --[reaction index] (position in paintData) = reaction target (0 = white, 1 = red, 2 = green, 3 = blue)
    --so [6] = 2 means that this (Cabbage Juice) interacts with 6 (Falcon's Bait) and affects 2 (Green)
      [2] = 3,
      [8] = 1,
      [13] = 1,
      [14] = 1,
      [15] = 2,
    }
  },
  {
    name = "Carrots",
    ppName = "Carrot",
    color = {224, 112, 32},
    enabled = true,
    reactions = {
      [1] = 3,
      [3] = 2,
      [4] = 2,
      [5] = 1,
      [6] = 0,
      [7] = 2,
      [12] = 3,
      [14] = 3,
    }
  },
  {
    name = "Clay",
    ppName = "Clay",
    color = {128, 96, 32},
    enabled = true,
    reactions = {
      [2] = 2,
      [6] = 3,
      [11] = 2,
      [12] = 3,
      [14] = 1,
      [15] = 3,
    }
  },
  {
    name = "Dead Tongue Mushrooms",
    ppName = "DeadTongue",
    color = {112, 64, 64},
    enabled = false,
    reactions = {
      [2] = 2,
      [5] = 3,
      [6] = 0,
      [7] = 0,
      [8] = 2,
      [10] = 2,
      [11] = 3,
    }
  },
  {
    name = "Toad Skin Mushrooms",
    ppName = "ToadSkin",
    color = {48, 96, 48},
    enabled = false,
    reactions = {
      [2] = 1,
      [4] = 3,
      [11] = 1,
      [12] = 1,
    }
  },
  {
    name = "Falcon's Bait Mushrooms",
    ppName = "FalconBait",
    color = {128, 240, 224},
    enabled = false,
    reactions = {
      [2] = 0,
      [3] = 3,
      [4] = 0,
      [7] = 3,
      [8] = 1,
      [10] = 2,
      [11] = 1,
      [13] = 0,
      [14] = 1,
    }
  },
  {
    name = "Red Sand",
    ppName = "RedSand",
    color = {144, 16, 24},
    enabled = true,
    reactions = {
      [2] = 2,
      [4] = 0,
      [6] = 3,
      [8] = 1,
      [10] = 0,
      [12] = 3,
      [13] = 0,
      [14] = 3,
      [15] = 3,
    }
  },
  {
    name = "Lead",
    ppName = "Lead",
    color = {80, 80, 96},
    enabled = true,
    reactions = {
      [1] = 1,
      [4] = 2,
      [6] = 1,
      [7] = 1,
      [10] = 1,
      [11] = 3,
      [12] = 0,
    }
  },
  {
    name = "Silver Powder",
    ppName = "Silver",
    color = {16, 16, 32},
    enabled = true,
    reactions = {

    }
  },
  {
    name = "Iron",
    ppName = "Iron",
    color = {96, 48, 32},
    enabled = true,
    reactions = {
      [4] = 2,
      [6] = 2,
      [7] = 0,
      [8] = 1,
      [11] = 3,
      [12] = 0,
      [13] = 3,
    }
  },
  {
    name = "Copper",
    ppName = "Copper",
    color = {64, 192, 192},
    enabled = true,
    reactions = {
      [3] = 2,
      [4] = 3,
      [5] = 1,
      [6] = 1,
      [8] = 3,
      [10] = 3,
      [12] = 0,
    }
  },
  {
    name = "Sulfur",
    ppName = "Sulfur",
    color = nil,
    enabled = true,
    reactions = {
      [2] = 3,
      [3] = 3,
      [5] = 1,
      [7] = 3,
      [8] = 0,
      [10] = 0,
      [11] = 0,
      [13] = 3,
      [15] = 3,
    }
  },
  {
    name = "Potash",
    ppName = "Potash",
    color = nil,
    enabled = true,
    reactions = {
      [1] = 1,
      [6] = 0,
      [7] = 0,
      [10] = 3,
      [12] = 3,
      [15] = 1,
    }
  },
  {
    name = "Lime",
    ppName = "Lime",
    color = nil,
    enabled = true,
    reactions = {
      [1] = 1,
      [2] = 3,
      [3] = 1,
      [6] = 1,
      [7] = 3,
      [15] = 0,
    }
  },
  {
    name = "Saltpeter",
    ppName = "Saltpeter",
    color = nil,
    enabled = true,
    reactions = {
      [1] = 2,
      [3] = 3,
      [7] = 3,
      [12] = 3,
      [13] = 1,
      [14] = 0,
    }
  }
};

local reactionChars = {
  [0] = "W",
  "R",
  "G",
  "B"
};

local playerReactions = {};

function readRGB(x, y)
  local color = srReadPixelFromBuffer(x, y);
  return {
    math.floor(color/256/256/256) % 256,
    math.floor(color/256/256) % 256,
    math.floor(color/256) % 256,
  };
end

function round(value)
  return math.floor(value + 0.5);
end

function getColor(building)
  local last = findImage("paint/last_ingredient.png", building);

  local x = last[0] - 2;
  local y = last[1] - 35;

  local rgb = {0, 0, 0};
  for index, value in pairs(rgb) do
    for i = 1, 306 do
      local color = readRGB(x + i, y);
      local total = color[1] + color[2] + color[3];
      if color[index] < total / 2 then
        break;
      end
      rgb[index] = round(i / 306 * 255);
    end
    y = y + 10;
  end

  return rgb;
end

function addColors(color1, color2)
  return {
    color1[1] + color2[1],
    color1[2] + color2[2],
    color1[3] + color2[3],
  };
end

function getAverageColor(colors)
  local count = 0;
  local totalColor = {0, 0, 0};
  for i = 1, #colors do
    local colorIndex = colors[i];
    if colorIndex ~= nil and paintData[colorIndex].color ~= nil then
      totalColor = addColors(totalColor, paintData[colorIndex].color);
      count = count + 1;
    end
  end

  if count == 0 then
    return {0, 0, 0};
  end

  return {
    math.floor(totalColor[1] / count),
    math.floor(totalColor[2] / count),
    math.floor(totalColor[3] / count)
  };
end

function getReactionValue(target, color, difference)
  local value = nil;
  for i = 1, 3 do
    if target == i or target == 0 then
      if color[i] ~= 0 and color[i] ~= 255 then
        value = difference[i];
      end
    end
  end

  return value;
end

function getReactionColor(index, reactionIndex, fixIndex)
  local reactionColor = {0, 0, 0};
  if not fixIndex then
    return reactionColor;
  end

  local indexTarget = paintData[fixIndex].reactions[index];
  if indexTarget then
    local reactionValue = playerReactions[index][fixIndex];
    if reactionValue == nil then
      return false;
    end

    if indexTarget == 0 then
      reactionColor[1] = reactionColor[1] + reactionValue;
      reactionColor[2] = reactionColor[2] + reactionValue;
      reactionColor[3] = reactionColor[3] + reactionValue;
    else
      reactionColor[indexTarget] = reactionColor[indexTarget] + reactionValue;
    end
  end

  local reactionIndexTarget = paintData[fixIndex].reactions[reactionIndex];
  if reactionIndexTarget then
    local reactionValue = playerReactions[reactionIndex][fixIndex];
    if reactionValue == nil then
      return false;
    end

    if reactionIndexTarget == 0 then
      reactionColor[1] = reactionColor[1] + reactionValue;
      reactionColor[2] = reactionColor[2] + reactionValue;
      reactionColor[3] = reactionColor[3] + reactionValue;
    else
      reactionColor[reactionIndexTarget] = reactionColor[reactionIndexTarget] + reactionValue;
    end
  end

  return reactionColor;
end

function getExpectedColor(index, reactionIndex, fixIndex)
  local averageColor     = getAverageColor({index, reactionIndex, fixIndex});
  local reactionColor    = getReactionColor(index, reactionIndex, fixIndex);
  return addColors(averageColor, reactionColor);
end

function fixBoundsScore(currentColor, index, reactionIndex, fixIndex, target)
  if not paintData[fixIndex].enabled then
    return 0;
  end

  if fixIndex == index or fixIndex == reactionIndex then
    return 0;
  end

  if getReactionColor(index, reactionIndex, fixIndex) == false then
    return 0;
  end

  local expectedColor    = getExpectedColor(index, reactionIndex);
  local fixExpectedColor = getExpectedColor(index, reactionIndex, fixIndex);
  local topScore = 0;
  for i = 1, 3 do
    if target == i or target == 0 then
      if currentColor[i] == 0 then
        local score = fixExpectedColor[i] - expectedColor[i];
        if score <= 255 and score > topScore then
          topScore = score;
        end
      elseif currentColor[i] == 255 then
        local score = expectedColor[i] - fixExpectedColor[i];
        if score <= 255 and score > topScore then
          topScore = score;
        end
      end
    end
  end

  return topScore;
end

function fixBounds(currentColor, index, reactionIndex, target)
  local topScore    = 0;
  local topFixIndex = nil;

  for fixIndex, data in pairs(paintData) do
    local score = fixBoundsScore(currentColor, index, reactionIndex, fixIndex, target);
    if score > topScore then
      topScore    = score;
      topFixIndex = fixIndex;
    end
  end

  if topFixIndex and addIngredient(building, topFixIndex) then
    return topFixIndex;
  end

  return nil;
end

function getBuildingRegion(name)
  local building = findText("This is [a-z]+ " .. name, nil, REGION+REGEX);
  while not building do
    checkBreak();
    srReadScreen();
    building = findText("This is [a-z]+ " .. name, nil, REGION+REGEX);
    sleepWithStatus(250,"Waiting for " .. name, nil, 0.7);
  end

  return building;
end

function addIngredient(building, ingredient)
  srReadScreen();

  while true do
    local plusButtons = findAllImages("plus.png", building);
    while #plusButtons ~= #paintData do
      checkBreak();
      srReadScreen();
      plusButtons = findAllImages("plus.png", building);
      sleepWithStatus(250,"All + buttons must be visible", nil, 0.7);
    end

    clickPoint(plusButtons[ingredient], 2, 2);

    lsSleep(100);
    srReadScreen();

    local ok = srFindImage("ok.png");
    if not ok then
      return true;
    end

    while true do
      lsPrint(5, 5, 5, 0.7, 0.7, 0xffffffff, "Go get some more " .. paintData[ingredient].name)

      if lsButtonText(10, lsScreenY - 30, 0, 80, 0x80ff80ff, "Continue") then
        srReadScreen();
        ok = srFindImage("ok.png");
        if ok then
          safeClick(ok[0] + 5, ok[1] + 5)
          lsSleep(100);
          srReadScreen();
        end
        break;
      end
      if ingredient == 7 then
        if lsButtonText(lsScreenX - 90, lsScreenY - 30, 0, 80, 0xff8080ff, "Abort") then
          error("Macro aborted by user");
        end
      else
        if lsButtonText(lsScreenX - 90, lsScreenY - 30, 0, 80, 0xffff80ff, "Skip") then
          return false;
        end
      end

      checkBreak();
      lsDoFrame();
    end
  end
end

function reset(building)
  srReadScreen();

  local empty = findImage("paint/concentration0.png", building);
  if empty then
    return true;
  end

  for i = 1, 10 do
    local full = findImage("paint/concentration10.png", building);
    if full then
      break;
    end
    addIngredient(building, 7);
  end

  clickText(findText("Take the Paint", building));
  lsSleep(100);

  local ok = srFindImage("ok.png");
  if not ok then
    return true;
  else
    return false;
  end
end

function displayIngredients()
  while true do
    local x = 5;
    local y = 5;
    lsPrint(x, y, 5, 0.7, 0.7, 0xffffffff, "Select the ingredients to test with:");
    y = y + 25;
    for index, data in pairs(paintData) do
      if index == 7 then
        lsPrint(x, y, 5, 0.7, 0.7, 0xffffffff, "Red Sand is required for resets");
      else
      data.enabled = CheckBox(x, y, 5, 0xffffffff, " " .. data.name, data.enabled, 0.7, 0.7);
      end
      y = y + 15;
    end

    if lsButtonText(5, lsScreenY - 30, 0, 80, 0x80ff80ff, "Begin") then
      break;
    end

    checkBreak();
    lsDoFrame();
    lsSleep(20);
  end
end

function setBatchSize()
  srReadScreen();

  local batchSize = findText("Batch Size");
  if not batchSize then
    return;
  end

  clickText(batchSize);
  lsSleep(100);
  srReadScreen();

  local small = findText("Make small batches");
  if not small then
    return;
  end

  clickText(small);
end

function doit()
  askForWindow([[
Paint By Numbers
v1.0 by Kavad

This program will let you run your paint
reactions step by step, or in full auto mode.

Either way it tracks the result and outputs
it to reactions.txt at the end.

You will need to use that reactions.txt file with
Desert Paint Codex to generate recipes.

Hover over the ATITD window and press shift.
]]);

  if file_exists("reactions.txt") then
    if not promptOkay("WARNING: reactions.txt already exists!\nRunning this macro will overwrite the file.") then
      error("User aborted macro!");
    end
  end

  displayIngredients();

  srReadScreen();
  getBuildingRegion("Pigment Laboratory");

  setBatchSize();

  for index, data in pairs(paintData) do
    playerReactions[index] = {};
    for reactionIndex, reactionTarget in pairs(data.reactions) do
      playerReactions[index][reactionIndex] = nil;
    end
  end

  local finish = false;
  local auto = false;
  for i = 1, 2 do
    for index, data in pairs(paintData) do
      for reactionIndex, reactionTarget in pairs(data.reactions) do
        if not finish then
          while not reset() do
            if not promptOkay("Failed to reset lab. Please Try again.") then
              error("Macro aborted by user.")
            end
          end
        end

        local begin = nil;
        local fixBoundsIndex = nil;
        while not finish do
          srReadScreen();

          local building      = getBuildingRegion("Pigment Laboratory");
          local color         = getColor(building);
          local expectedColor = getExpectedColor(index, reactionIndex, fixBoundsIndex);
          local difference    = {
            color[1] - expectedColor[1],
            color[2] - expectedColor[2],
            color[3] - expectedColor[3]
          };

          if i == 1 then
            lsPrint(5, 5, 5, 0.7, 0.7, 0xffffffff, "Testing:");
          else
            lsPrint(5, 5, 5, 0.7, 0.7, 0xffffffff, "Retrying:");
          end
          lsPrint(25, 25, 5, 0.7, 0.7, 0xffffffff, data.name);
          lsPrint(25, 45, 5, 0.7, 0.7, 0xffffffff, paintData[reactionIndex].name);
          lsPrint(5, 65, 5, 0.7, 0.7, 0xffffffff, "Expected Color: " .. expectedColor[1] .. ", " .. expectedColor[2] .. ", " .. expectedColor[3]);
          lsPrint(5, 85, 5, 0.7, 0.7, 0xffffffff, "Current Color: " .. color[1] .. ", " .. color[2] .. ", " .. color[3]);

          if not data.enabled or not paintData[reactionIndex].enabled then
            lsPrint(5, 105, 5, 0.7, 0.7, 0xff8080ff, "Disabled");
            lsDoFrame();
            break;
          end

          --This skips the retry if we've already got a reaction
          if i == 2 and playerReactions[index][reactionIndex] ~= nil then
            lsPrint(5, 105, 5, 0.7, 0.7, 0xffffffff, "Reaction: " .. playerReactions[index][reactionIndex] .. " " .. reactionChars[reactionTarget]);
            lsDoFrame();
            break;
          end

          if begin then
            lsPrint(5, 105, 5, 0.7, 0.7, 0xffffffff, "Difference: " .. difference[1] .. ", " .. difference[2] .. ", " .. difference[3]);
            local reaction = getReactionValue(reactionTarget, color, difference);
            if reaction ~= nil and (reaction > 64 or reaction < -64) then
              promptOkay("Measured Invalid Reaction. Please Try again.", nil, nil, nil, true);

              reaction = nil;
              begin = false;
              auto = false;
              while not reset() do
                if not promptOkay("Failed to reset lab. Please Try again.") then
                  error("Macro aborted by user.")
                end
              end
            end
            playerReactions[index][reactionIndex] = reaction;
            if reaction ~= nil then
              lsPrint(5, 125, 5, 0.7, 0.7, 0xffffffff, "Reaction: " .. reaction .. " " .. reactionChars[reactionTarget]);
            else
              if not fixBoundsIndex then
                fixBoundsIndex = fixBounds(color, index, reactionIndex, reactionTarget);
                lsSleep(100);
              end

              lsPrint(5, 125, 5, 0.7, 0.7, 0xff8080ff, "Out of bounds. Unable to correct.");
              if i == 1 then
                lsPrint(5, 145, 5, 0.7, 0.7, 0xff8080ff, "We'll try again after gathering other reactions.");
              else
                lsPrint(5, 145, 5, 0.7, 0.7, 0xff8080ff, "You'll have to enable more ingredients");
                lsPrint(5, 165, 5, 0.7, 0.7, 0xff8080ff, "or test this one manually.");
              end
            end
          end

          checkBreak();
          lsDoFrame();
          lsSleep(20);

          if begin then
            if auto and playerReactions[index][reactionIndex] ~= nil then
              break;
            end

            if lsButtonText(5, lsScreenY - 30, 0, 75, 0x80ff80ff, "Next") then
              break;
            end
          else
            if auto then
              begin = true;
            else
              auto  = lsButtonText(5, lsScreenY - 60, 0, 75, 0x80ff80ff, "Auto");
              begin = lsButtonText(5, lsScreenY - 30, 0, 75, 0x80ff80ff, "Test");
            end

            if begin then
              addIngredient(building, index);
              addIngredient(building, reactionIndex);
              lsSleep(100);
            end

            if not auto and lsButtonText(110, lsScreenY - 30, 0, 80, 0xffff80ff, "Skip") then
              break;
            end
          end

          if not auto and not begin and lsButtonText(220, lsScreenY - 30, 0, 75, 0xff8080ff, "Finish") then
            finish = true;
            lsPrint(5, 5, 5, 0.7, 0.7, 0xffffffff, "Wrapping Up...");
            lsDoFrame();
            break;
          end
        end
      end
    end
  end

  reset();

  logfile = io.open("reactions.txt","w+");
  logfile:write("\n//Reactions//\n");
  for index, data in pairs(paintData) do
    local line = nil;
    for reactionIndex, reactionTarget in pairs(data.reactions) do
      if index < reactionIndex then
        local reactionValue = playerReactions[index][reactionIndex];
        if reactionValue == nil then
          reactionValue = "";
        end

        local switchedValue = playerReactions[reactionIndex][index];
        if switchedValue == nil then
          switchedValue = "";
        end

        line = string.format("%-11s| %-11s | %s | %3s | %3s\n",
          data.ppName,
          paintData[reactionIndex].ppName,
          reactionChars[paintData[index].reactions[reactionIndex]],
          reactionValue,
          switchedValue
        );
        logfile:write(line);
      end
    end

    if line then
      logfile:write("\n");
    end
  end
  logfile:write("\n\n");
  logfile:close();

  while true do
    lsPrint(5, 105, 5, 0.7, 0.7, 0xffffffff, "Reactions saved to reactions.txt");
    if lsButtonText(5, lsScreenY - 30, 0, 75, 0xffffffff, "Done") then
      break;
    end

    checkBreak();
    lsDoFrame();
    lsSleep(20);
  end
end

function file_exists(name)
  local f=io.open(name,"r");
  if f ~= nil then

    io.close(f);
    return true;
  else
    return false;
  end
end
