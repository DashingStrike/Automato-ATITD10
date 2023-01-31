dofile("screen_reader_common.inc");
dofile("ui_utils.inc");
dofile("settings.inc");
dofile("common.inc");

click_delay = 150;
per_click_delay = click_delay;

local recipes = {};

local keys = {
  {
    code = 49,
    step = 1
  },
  {
    code = 50,
    step = 2
  },
  {
    code = 51,
    step = 3
  },
  {
    code = 52,
    step = 4
  },
  {
    code = 53,
    step = 5
  },
  {
    code = 54,
    step = 6
  },
  {
    code = 55,
    step = 7
  },
  {
    code = 56,
    step = 8
  },
  {
    code = 57,
    step = 9
  },
  {
    code = 66,
    step = "Ball Peen"
  },
  {
    code = 67,
    step = "Wide Chisel"
  },
  {
    code = 82,
    step = "Round"
  },
  {
    code = 83,
    step = "Shaping Mallet"
  },
};

local metals = {
  "Copper",
  "Iron",
  "Brass",
  "Bronze",
  "Steel",
  "Sun Steel",
  "Moon Steel",
  "Thoth's Metal",
  "Water Metal",
  "Metal Blue",
  "Octec's Alloy"
};

local products = {
  "Shovel",
  "Archaeologist's Shovel",
  "Carpentry Blade",
  "Hatchet",
  "Resin Wedge",
  "Sharp Edged Blade",
  "Jagged Blade",
  "Twice Folded Blade",
  "Spring",
  "Horse Shoe",
};

local anvilOffset = {};
local pauseTake = true;
local howMany = 1;
local metalIndex = 1;
local productIndex = 1;
local recipeIndex = nil;
local troubleshoot = nil;

function doit()
  askForWindow("Note that anvils need to have been rotated 180 degrees from the default rotation when built, so the sharp edge of the carp blade is to the left.\n\nHover ATITD window and press Shift to continue.");

  loadRecipes();

  lsSleep(300);
  checkAnvil();
  findAnvil();

  while true do
    checkBreak();
    options();
    main();
  end
end

function loadRecipes()
  recipes = readSetting("recipes");

  if not recipes then
    local success, default = deserialize("default_blacksmithing.txt");
    if success then
      recipes = default["recipes"];
      writeSetting("recipes", recipes);
    end
  end

  local horseShoeMigrated = readSetting("horse_shoe_migrated", false);
  if not horseShoeMigrated then
    local success, default = deserialize("default_blacksmithing.txt");
    if success then
      table.insert(recipes, default["recipes"][5]);
      writeSetting("recipes", recipes);
      writeSetting("horse_shoe_migrated", true);
    end
  end
end

function saveRecipe(recipe)
  table.insert(recipes, recipe);
  writeSetting("recipes", recipes);
end

function deleteRecipe()
  table.remove(recipes, recipeIndex);
  writeSetting("recipes", recipes);
end

function main()
  local x = 10;
  local y = 10;
  local z = 0;
  local scale = 0.7;

  for numMade = 1, howMany do
    if pauseTake then
      itemAccepted = nil;
    else
      itemAccepted = 1;
    end
    message = "";
    message = "[" .. numMade .. "/" .. howMany .. "] Making items(s)";

    if (numMade == howMany) then
      message = message .. "\n\nYay, last one !";
    else
      message = message .. "\n\n" .. (howMany - numMade) .. " item(s) remaining";
    end

    if pauseTake and not (numMade == howMany) then
      message = message .. "\n\n" .. "Pause ON -- will pause after this item";
    end

    checkBreak();
    loadAnvil(metals[metalIndex], recipes[recipeIndex].product);
    statusScreen(message, nil, scale, scale);
    makeRecipe();
    checkItem();

    if not pauseTake then
      takeProduct()
    end

    while not itemAccepted do
      checkBreak();
      lsPrintWrapped(x, y, 0, lsScreenX - 20, scale, scale, 0xFFFFFFff, "Check main chat for quality, is it OK?\n\n\nClick 'Take' to complete the project and continue\n\nYou can turn off the pause by unchecking box below; Remaining items will finish uninterupted, after you 'Take'.");

      pauseTake = CheckBox(x, y+150, z, 0xffffffff, " Pause after each piece to verify quality", pauseTake, 0.65, 0.65);

      if lsButtonText(x, lsScreenY - 30, z, 100, 0x80ff80ff, "Take") then
        itemAccepted = 1;
        takeProduct();
        break;
      end

      if lsButtonText(lsScreenX - 110, lsScreenY - 60, z, 100, 0x80ffffff, "Extend") then
        recordRecipe(recipes[recipeIndex]);
      end

      if lsButtonText(x, lsScreenY - 60, z, 100, 0xff8080ff, "Scrap") then
        scrap = 1;
        scrapProduct();
        break;
      end

      if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff, "End script") then
        error "Clicked End script button";
      end

      lsDoFrame();
      lsSleep(10);
    end

    if scrap or finish_up then
      if scrap then
        sleepWithStatus(1000, "Project scrapped, resetting macro ...", nil, scale, scale);
      else
        sleepWithStatus(1000, "Finishing up, resetting macro ...", nil, scale, scale);
      end
      scrap = nil;
      finish_up = nil;
      break;
    end

    lsDoFrame();
    lsSleep(10);
  end

  lsPlaySound("beepping.wav");
end

function options()
  local x = 5;
  local y = 5;

  while true do
    lsPrint(x, y, z, 1.0, 1.0, 0xffffffff, "Amount:");
    _, howMany = lsEditBox("howMany", x + 80, y, 0, 50, 30, 1.0, 1.0, 0x000000ff, howMany);
    howMany = tonumber(howMany);
    if not howMany then
      lsPrint(x + 135, y + 2, 10, 0.8, 0.8, 0xFF2020ff, "Must be a number");
      howMany = 1;
    end

    lsPrint(x, y + 30, z, 1.0, 1.0, 0xffffffff, "Metal:");
    metalIndex = lsDropdown("metal", x + 80, y + 30, 0, 180, metalIndex, metals);

    if #recipes > 0 then
      local recipeOptions = {};
      for i = 1, #recipes do
        table.insert(recipeOptions, recipes[i].name);
      end
      lsPrint(x, y + 60, z, 1.0, 1.0, 0xffffffff, "Recipe:");
      recipeIndex = lsDropdown("recipe", x + 80, y + 60, 0, 180, recipeIndex, recipeOptions);

      pauseTake = CheckBox(x, y + 90, z, 0xffffffff, " Pause after each product to verify quality", pauseTake, 0.65, 0.65);
      troubleshoot = CheckBox(x, y+110, z, 0xffffffff, " Troubleshooting Mode", troubleshoot, 0.65, 0.65);

      lsPrint(x + 180, y + 150, z, 1.0, 1.0, 0xffffffff, "Steps: " .. getClickCount(recipes[recipeIndex].steps));

      if recipes[recipeIndex].product == "Horse Shoe" then
        metalIndex = 2; --Horse Shoes can only be made in iron
      end

      if lsButtonText(x, lsScreenY - 30, z, 100, 0x80ff80ff, "Start") then
        break;
      end
    end

    if lsButtonText(lsScreenX - 105, lsScreenY - 60, z, 100, 0xff8080ff, "Delete") then
      deleteRecipe();
    end

    if lsButtonText(lsScreenX - 105, lsScreenY - 90, z, 100, 0x80ffffff, "New") then
      recordRecipe();
    end

    if lsButtonText(x, lsScreenY - 60, z, 100, 0xffff80ff, "Calibrate") then
      findAnvil();
    end

    if lsButtonText(lsScreenX - 105, lsScreenY - 30, z, 100, 0xffffffff, "End script") then
      error "Clicked End script button";
    end

    checkBreak();
    lsDoFrame();
    lsSleep(10);
  end
end

function getClickCount(steps)
  count = 0;
  for _, step in pairs(steps) do
    if #step == 2 then
      count = count + 1;
    end
  end

  return count;
end

function checkAnvil()
  waitAndClickText("This is [a-z]+ Anvil", nil, REGEX);

  local complete = waitForNoText("Complete Project", 60000, "Please discard or complete the existing project");
  if complete then
    error("Incomplete project on the anvil.");
  end
end

function findHandle(startX, endX, startY, endY, step)
  local foundX;
  local foundY;
  for y = startY, endY, -step do
    for x = startX, endX, step do
      checkBreak();

      local pixel = parseColor(srReadPixel(x,y));
      if pixel[0] > 140 and pixel[0] < 220 and pixel[0] - pixel[1] > 24 and pixel[0] - pixel[1] < 55 and pixel[0] - pixel[2] > 47 and pixel[0] - pixel[2] < 130 then
        foundX = x;
        foundY = y;
      elseif foundX then
        return {[0] = foundX, [1] = foundY};
      end
    end
  end
end

function findAnvil()
  waitAndClickText("This is [a-z]+ Anvil", nil, REGEX);

  setCameraView(CARTOGRAPHER2CAM);
  lsSleep(100);
  srReadScreen();

  local windowSize = srGetWindowSize();
  local centerX = math.floor(windowSize[0] / 2);
  local centerY = math.floor(windowSize[1] / 2);

  while true do
    checkBreak();
    srReadScreen();

    statusScreen("Searching for anvil...");

    local roughHandle = findHandle(centerX + 50, centerX + 125, centerY, centerY - 50, 4);
    if roughHandle then
      local exactHandle = findHandle(roughHandle[0], roughHandle[0] + 10, roughHandle[1] + 5, roughHandle[1] - 5, 1);
      if exactHandle then
        anvilOffset[0] = exactHandle[0] + 214;
        anvilOffset[1] = exactHandle[1] - 161;

        lsPrintln(exactHandle[0] .. "," .. exactHandle[1]);
        return;
      end
    end

    while true do
      checkBreak();

      srReadScreen();
      srMakeImage("anvil_search", centerX + 50, centerY - 50, 75, 50);
      srShowImageDebug("anvil_search", 5, 5, 1, 2);

      lsPrintWrapped(10, 110, 0, lsScreenX - 20, 0.7, 0.7, 0xFFFF80ff, "Looking for the top yellow part of the anvil handle in the above region");

      if lsButtonText(10, lsScreenY - 30, 0, 100, 0xFFFFFFff, "OK") then
        lsDoFrame();
        break;
      end

      if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFFFFFFff, "Cancel") then
        error("Unable to find anvil");
      end

      lsDoFrame();
      lsSleep(10);
    end
  end
end

function loadAnvil(metal, product)
  waitAndClickText("Load Anvil...");
  waitAndClickText(metal .. "...");
  waitAndClickText("^" .. product, nil, REGEX);
  waitAndClickText("This is [a-z]+ Anvil", nil, REGEX);
  lsSleep(2000);
end

function setTool(tool)
  waitAndClickText("Tools...");
  waitAndClickText(tool);
end

function setForce(force)
  waitAndClickText("Tools...");
  waitAndClickText("Force Level");
  waitAndClickText("[" .. force .. "]");
end

function checkKey(recipe, status, code, step)
  local key = nil;
  while lsKeyHeld(code) do
    if not key then
      table.insert(recipe.steps, {step});
      table.insert(status, 1, step);
      if #status > 20 then
        table.remove(status);
      end
      key = true;
    end
  end
end

function recordRecipe(existingRecipe)
  local recipe = {
    name = "New " .. products[productIndex],
    product = 1,
    steps = {}
  };
  if existingRecipe then
    recipe.name    = existingRecipe.name .. " Extended";
    recipe.product = existingRecipe.product;
    for i = 1, #existingRecipe.steps do
      table.insert(recipe.steps, existingRecipe.steps[i]);
    end
  else
    while true do
      lsPrint(5, 5, 0, 1.0, 1.0, 0xffffffff, "Item:");
      productIndex = lsDropdown("product", 85, 5, 0, 180, productIndex, products);

      if lsButtonText(5, lsScreenY - 30, z, 80, 0xffffffff, "Start") then
        recipe.product = products[productIndex];
        setCameraView(CARTOGRAPHER2CAM);
        break;
      end

      checkBreak();
      lsDoFrame();
      lsSleep(10);
    end

    if products[productIndex] == "Horse Shoe" then
      metalIndex = 2; --Horse Shoes can only be made in iron
    end

    loadAnvil(metals[metalIndex], recipe.product);
  end

  while lsMouseIsDown() do
    checkBreak();
  end

  local status = {};
  while true do
    local clicked = nil;
    while lsMouseIsDown() do
      if not clicked then
        clicked = true;
        local clickedX, clickedY = srMousePos();
        clickedX = clickedX - anvilOffset[0];
        clickedY = clickedY - anvilOffset[1];
        if clickedX > -350 and clickedX < 150 and
          clickedY > -50 and clickedY < 450
        then
          table.insert(recipe.steps, {clickedX, clickedY});
          table.insert(status, 1, "Clicked " .. clickedX .. ", " .. clickedY);
          if #status > 20 then
            table.remove(status);
          end
        end
      end
    end

    for _, key in pairs(keys) do
      checkKey(recipe, status, key.code, key.step);
    end

    lsPrintWrapped(5, 5, 0, 290, 0.7, 0.7, 0xffffffff, table.concat(status, "\n"));

    if lsButtonText(5, lsScreenY - 30, z, 80, 0xffffffff, "Done") then
      break;
    end

    checkBreak();
    lsDoFrame();
    lsSleep(10);
  end

  while true do
    lsPrint(5, 5, 0, 1.0, 1.0, 0xffffffff, "Name:");
    _, recipe.name = lsEditBox("name", 85, 5, 0, 200, 30, 1.0, 1.0, 0x000000ff, recipe.name);

    if lsButtonText(5, lsScreenY - 30, z, 80, 0x80ff80ff, "Save") then
      saveRecipe(recipe);
      break;
    end

    if lsButtonText(lsScreenX - 85, lsScreenY - 30, z, 80, 0xff8080ff, "Discard") then
      scrapProduct();
      break;
    end

    checkBreak();
    lsDoFrame();
    lsSleep(10);
  end
end

function makeRecipe()
  checkBreak();
  srReadScreen();
  click_delay = 200;

  for i = 1, #recipes[recipeIndex].steps do
    local step = recipes[recipeIndex].steps[i];
    if #step == 2 then
      clickXY(step[1], step[2]);
    elseif string.len(step[1]) == 1 then
      setForce(step[1]);
    else
      setTool(step[1]);
    end
    lsSleep(100);
  end
end

function checkItem()
  waitAndClickText("Tools...");
  waitAndClickText("Quality Check");
end

function takeProduct()
  waitAndClickText("This is [a-z]+ Anvil", nil, REGEX);
  waitAndClickText("Complete Project");

  if not waitForImage("Yes.png", 60000, "Waiting for 'Ready to Unload' popup.") then
    error("Unable to find 'Ready to Unload' popup");
  end

  waitAndClickImage("Yes.png");
  sleepWithStatus(1500,"Short pause to wait for possible popup")
  closePopUp(); -- Close 'Artistic Touch' popup that occurs after passing art tests
  waitAndClickText("This is [a-z]+ Anvil", nil, REGEX);
end

function scrapProduct()
  srReadScreen();
  waitAndClickText("This is [a-z]+ Anvil", nil, REGEX);
  waitAndClickText("Discard Project");
  srReadScreen();

  local yes = waitForImage(
    "Yes.png",
    60000,
    "Waiting for 'Yes' text on the screen."
  );
  if not yes then
    error("Unable to find 'Yes' on the screen");
  end

  waitAndClickImage("Yes.png");
  waitAndClickText("This is [a-z]+ Anvil", nil, REGEX);
end


function clickXY(x, y)
  clickX = math.ceil(anvilOffset[0] + x);
  clickY = math.ceil(anvilOffset[1] + y);
  if troubleshoot then
    srSetMousePos(clickX, clickY);
    safeClick(clickX, clickY);
    while not lsControlHeld() do
      checkBreak();
      lsPrint(5, 5, 0, 0.7, 0.7, 0xffffffff, "Clicked: " .. x .. ", " .. y);
      lsPrint(5, 25, 0, 0.7, 0.7, 0xffffffff, "Press Ctrl to advance");
      if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff, "End script") then
        error "Clicked End script button";
      end

      lsDoFrame();
      lsSleep(10);
    end
    while lsControlHeld() do
      checkBreak();
      lsSleep(10);
    end
  else
    safeClick(clickX, clickY);
  end
end

function closePopUp()
  while 1 do
    srReadScreen()
    local ok = srFindImage("OK.png")
	    if ok then
	      statusScreen("Found and Closing Popups ...", nil, 0.7);
	      srClickMouseNoMove(ok[0]+5,ok[1]);
	      lsSleep(100);
	    else
	      break;
	    end
  end
end
