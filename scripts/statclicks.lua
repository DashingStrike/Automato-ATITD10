dofile("common.inc");
dofile("settings.inc");
dofile("hackling_rake.lua");

items = {
        --strength
        {"",
        --[[
            "Coconuts",
            ]]--
        },
        --end
        {"",
            "Dig Hole",
            "Flax Comb",
            "Weave Canvas",
            "Weave Linen",
            "Weave Papy Basket",
            "Weave Wool Cloth",
            "Oil (Flax Seed)"
            --[[
            "Churn Butter",
            "Excavate Blocks",
            "Hackling Rake",
            "Pump Aqueduct",
            "Push Pyramid",
            "Stir Cement",
            "Weave Silk",

            "Water Insects",
            ]]--
        },
        --con
        {"",
        --[[
            "Gun Powder",
            "Ink",
            ]]--
        },
        --foc
        {"",
            "Long Sharp Stick",
            "Rawhide Strips",
            "Sharpened Stick",
            "Tinder",
            "Clay Lamp",
            "Barrel Tap",
            "Bottle Stopper",
            "Crudely Carved Handle",
            "Large Crude Handle",
            "Personal Chit",
            "Wooden Peg",
            "Wooden Pestle",
            "Tackle Block",
            "Wooden Cog"
        --[[
            "Search Rotten Wood",
            "Tap Rods",
            ]]--
        },
};

local lagBound = {};
lagBound["Dig Hole"] = true;
lagBound["Survey (Uncover)"] = true;

-- Due to a window refresh bug (T9) rods can be lost when auto retrieve is enabled
-- disabling it and manually refreshing the rod window bypasses this bug.
retrieveRods = true;
--[[
local textLookup = {};
textLookup["Coconuts"] = "Harvest the Coconut Meat";
textLookup["Gun Powder"] = "Gunpowder";
textLookup["Ink"] = "Ink";
textLookup["Pump Aqueduct"] = "Pump the Aqueduct";
]]--
statNames = {"strength", "endurance", "constitution", "focus"};
statTimer = {};
askText = singleLine([[
   Repeatedly performs stat-dependent tasks. Can perform several tasks at once as long as they use different attributes.
   Will also eat food from a kitchen grilled veggies once food is up if a kitchen is pinned.
   Ensure that windows of tasks you are performing are pinned and press shift.
]]

);
function getClickActions()
    local scale = 1.4;
    local z = 0;
    local done = false;
    -- initializeTaskList
    tasks = {};
    for i = 1, 4 do
        tasks[i] = 1;
    end

    while not done do
        checkBreak();
        y = 10;
        lsSetCamera(0, 0, lsScreenX * 1.7, lsScreenY * 1.7);
        lsPrint(5, y, z, 1.2, 1.2, 0xFFFFFFff, "Ensure that all menus are pinned!");
        y = y + 50;
        for i = 1, #statNames do
            lsPrint(5, y, z, 1, 1, 0xFFFFFFff, statNames[i]:gsub("^%l", string.upper) .. ":");
            y = y + 24;
            tasks[i] = lsDropdown(statNames[i], 5, y, 0, 200, tasks[i], items[i]);
            y = y + 32;
            if items[i][tasks[i]] == "Stir Cement" then
                y = y + 35;
                stirMaster = readSetting("stirMaster",stirMaster);
                stirMaster = lsCheckBox(5, y-30, z, 0xFFFFFFff, " Automatically fill the Clinker Vat", stirMaster);
                writeSetting("stirMaster",stirMaster);
            end
            if items[i][tasks[i]] == "Tap Rods" then
                y = y + 35;
                retrieveRods = readSetting("retrieveRods",retrieveRods);
                retrieveRods = lsCheckBox(5, y-30, z, 0xFFFFFFff, " Automatically retrieve rods", retrieveRods);
                writeSetting("retrieveRods",retrieveRods);
            end
        end
        lsDoFrame();
        lsSleep(tick_delay);
        if lsButtonText(150, 58, z, 100, 0xFFFFFFff, "OK") then
            done = true;
        end
    end
end

function weave(clothType)
    if clothType == "Canvas" then
        srcType = "Twine";
        srcQty = "60";
    elseif clothType == "Linen" then
        srcType = "Thread";
        srcQty = "400";
    elseif clothType == "Basket" then
        srcType = "Dried Papyrus";
        srcQty = "200";
    elseif clothType == "Wool" then
        srcType = "Yarn";
        srcQty = "60";
    elseif clothType == "Silk" then
        srcType = "Raw Silk";
        srcQty = "50";
    end

    srReadScreen();
    local consume = srFindImage("consume.png");
    if consume then
        eatOnion();
    end

    if clothType == "Basket" then
        weaveImage = srFindImage("statclicks/weave_papyrus.png");
    else
        weaveImage = srFindImage("statclicks/weave_" .. srcType .. ".png");
    end
    if weaveImage ~= nil then
        safeClick(weaveImage[0],weaveImage[1]);
        lsSleep(100);
        --Close the error window if a student's loom
        srReadScreen();
        studloom = srFindImage("statclicks/student_loom.png")
        if studloom then
            lsSleep(500);
            srReadScreen();
            closePopUp();
        end
        -- reload the loom
        loadImage = srFindImage("statclicks/with_" .. srcType .. ".png");
        if loadImage ~= nil then
            safeClick(loadImage[0],loadImage[1]);
            local t = waitForImage("statclicks/how_much.png", 2000);
            if t ~= nil then
                srCharEvent(srcQty .. "\n");
            end
            closePopUp();
        end
    end

    -- Restring student looms
    srReadScreen();
    if studloom then
        srReadScreen();
        t = srFindImage("statclicks/restring.png");
        if t ~= nil then
            safeClick(t[0],t[1]);
            lsSleep(75);
            srReadScreen();
            closePopUp();
            lsSleep(75);
        end
    end
end

function carve(item)

  srReadScreen();
  carveItem = findText(item);

  if carveItem ~= nil then
      safeClick(carveItem[0]+5,carveItem[1]+3);
      lsSleep(per_tick);
      srReadScreen();
      closePopUp();
      lsSleep(per_tick);
  end
end

function digHole()
  srReadScreen();
  local digdeeper = srFindImage("statclicks/dig_deeper.png");
  local consume = srFindImage("consume.png");
    if digdeeper ~= nil then
      if consume then
          eatOnion();
      end
      safeClick(digdeeper[0], digdeeper[1])
      lsSleep(per_tick);
    end
end
--[[
function searchRottenWood()
    woodForBugs = findText("Wood for Bugs");

    if woodForBugs ~= nil then
        clickText(woodForBugs);
        lsSleep(per_tick);
        srReadScreen();
        closePopUp();
        lsSleep(per_tick);
    end
end
]]--

function flaxOil()
  srReadScreen();
  local seperateoil = srFindImage("statclicks/seperate_oil.png");
    if seperateoil ~= nil then
      safeClick(seperateoil[0], seperateoil[1])
      lsSleep(per_tick);
      closePopUp();
    end
end

function combFlax()
    local comb = srFindImage("statclicks/comb.png", 6000);
    if comb == nil then
        return;
    end
    safeClick(comb[0], comb[1]);
    lsSleep(per_tick);
    srReadScreen();
    local fix = srFindImage("repair.png", 6000);
    if (fix) then
        repairRake();
        lsSleep(75);
        srReadScreen();
        safeClick(comb[0],comb[1]);
        lsSleep(75);
    end

    srReadScreen();
    local consume = srFindImage("consume.png");
    if consume then
        eatOnion();
    end

    local s1 = srFindImage("rake/separate.png", 6000);
    local s23 = srFindImage("rake/process.png", 6000);
    local clean = srFindImage("rake/clean.png", 6000);
    if s1 then
      safeClick(s1[0], s1[1]);
    elseif s23 then
      safeClick(s23[0], s23[1]);
    elseif clean then
      safeClick(clean[0], clean[1]);
    else
        lsPrint(5, 0, 10, 1, 1, "Found Stats");
        lsDoFrame();
        lsSleep(2000);
    end
end

function eatOnion()
  srReadScreen();
  buffed = srFindImage("stats/enduranceBuff.png")
    if not buffed then
      srReadScreen();
      local consumeOnion = srFindImage("consume.png")
      lsSleep(75);
      safeClick(consumeOnion[0],consumeOnion[1]);
        if not buffed then
          sleepWithStatus(1500,"Waiting for the green endurance icon to appear")
        end
    end
end

--[[
function hacklingRake()
    expressionToFind = "This is [a-z]+[ Improved]* Hackling Rake";
    flaxReg = findText(expressionToFind, nil, REGION + REGEX);
    if flaxReg == nil then
        return;
    end
    flaxText = findText(expressionToFind, flaxReg, REGEX);
    clickText(flaxText);
    lsSleep(per_tick);
    srReadScreen();
    local fix = findText("Repair", flaxReg);
    if (fix) then
        repairRake();
    end
    grilledOnion = findText("Grilled Onions");
    if grilledOnion then
        eatOnion();
    end
    s1 = findText("Separate Rotten", flaxReg);
    s23 = findText("Continue processing", flaxReg);
    clean = findText("Clean the");
    if s1 then
        clickText(s1);
    elseif s23 then
        clickText(s23);
    elseif clean then
        if takeAllWhenCombingFlax == true then
            clickText(findText("Take...", flaxReg));
            everythingObj = waitForText("Everything", 1000);
            if everythingObj == nil then
                return;
            end
            clickText(everythingObj);
            lsSleep(150);
        end
        clickText(clean);
    else
        lsPrint(5, 0, 10, 1, 1, "Found Stats");
        lsDoFrame();
        lsSleep(2000);
    end
end

function pyramidPush()
   local curCoords = findCoords();
   local t, u;
   if curCoords[0] > pyramidXCoord + 2 then
      t = findText("Push this block West");
      if t ~= nil then u = t end;
   elseif curCoords[0] < pyramidXCoord - 2 then
      t = findText("Push this block East");
      if t ~= nil then u = t end;
   else
      t = findText("Turn this block to face North-South");
      if t ~= nil then u = t end;
   end
   if curCoords[1] > pyramidYCoord + 2 then
      t = findText("Push this block South");
      if t ~= nil then u = t end;
   elseif curCoords[1] < pyramidYCoord - 2 then
      t = findText("Push this block North");
      if t ~= nil then u = t end;
   else
      t = findText("Turn this block to face East-West");
      if t ~= nil then u = t end;
   end
   if u ~= nil then
      clickText(u);
   end
end

function stirCement()
    t = waitForText("Stir the cement", 2000);
    if t then
        safeClick(t[0]+20,t[1]);
    else
        clickText(findText("This is [a-z]+ Clinker Vat", nil, REGEX));
        lsSleep(500);
        if stirMaster then
            take = findText("Take...")
            if take then
                clickText(waitForText("Take..."));
                clickText(waitForText("Everything"));
            end
            sleepWithStatus(1750, "Adding Bauxite to the Clinker Vat")
            clickText(waitForText("Load the vat with Bauxite"));
            waitForText("how much");
            srCharEvent("10\n");
            waitForNoText("how much");
            sleepWithStatus(1750, "Adding Gypsum to the Clinker Vat")
            clickText(waitForText("Load the vat with Gypsum"));
            waitForText("how much");
            srCharEvent("10\n");
            waitForNoText("how much");
            sleepWithStatus(1750, "Adding Clinker to the Clinker Vat")
            clickText(waitForText("Load the vat with Clinker"));
            waitForText("how much");
            srCharEvent("800\n");
            waitForNoText("how much");

            lsSleep(250);
            clickText(findText("This is [a-z]+ Clinker Vat", nil, REGEX));
            fuel = findText("Fuel level")
            if not fuel then
                sleepWithStatus(1750, "Adding Petroleum to the Clinker Vat")
                clickText(waitForText("Load the vat with Petroleum"));
                waitForText("much fuel");
                srCharEvent("40\n");
                waitForNoText("how much");
            end
            sleepWithStatus(1750, "Mixing a batch of Cement")
            clickText(waitForText("Make a batch of Cement"));
        end
    end
end

local function tapRods()
    local window = findText("This is [a-z]+ Bore Hole", nil, REGION + REGEX);
    if window == nil then
        return;
    end
    local t = findText("Tap the Bore Rod", window);
    local foundOne = false;
    if t then
        clickText(t);
        foundOne = true;
    end
    t = waitForText("Crack an outline", 300);
    if t then
        clickText(t);
        foundOne = true;
    end
    if foundOne == false and retrieveRods == true then
        t = findText("Retrieve the bore", window);
        if t then
            clickText(t);
        end
    end
end

local function excavateBlocks()
    local window = findAllText("This is [a-z]+ Pyramid Block(Roll", nil, REGION + REGEX);
    if window then
        for i = 1, #window do
            unpinWindow(window[i]);
        end
        lsSleep(50);
        srReadScreen();
    end
    window = findText("This is [a-z]+ Tooth Limestone Bl", nil, REGION + REGEX);
    if window == nil then
        return;
    end
    local t = findText("Dig around", window);
    if t then
        clickText(t);
    end
    t = waitForText("Slide a rolling rack", 300);
    if t then
        clickText(t);
        t = waitForText("This is [a-z]+ Pyramid Block(Roll", 300, nil, nil, REGION + REGEX);
        if t then
            unpinWindow(t);
        end
    end
    return;
end

function churnButter()
    local t = srFindImage("statclicks/churn.png");
    if t then
        srClickMouseNoMove(t[0]+5, t[1]);
    end
end
]]--

function doTasks()
    didTask = false;
    for i = 1, 4 do
        curTask = items[i][tasks[i]];
        if curTask ~= "" then
            srReadScreen();
            statImg = srFindImage("stats/" .. statNames[i] .. ".png");
            if statTimer[i] ~= nil then
                timeDiff = lsGetTimer() - statTimer[i];
            else
                timeDiff = 999999999;
            end
            local delay = 1400;
            if lagBound[curTask] then
                delay = 3000;
            end
            if not statImg and timeDiff > delay then
                --check for special cases, like flax.
                lsPrint(10, 10, 0, 0.7, 0.7, 0xB0B0B0ff, "Working on " .. curTask);
                lsDoFrame();
                digHole();
                if curtask == "Dig Hole" then
                  digHole();
                elseif curTask == "Tinder" then
                  carve(curTask);
                elseif curTask == "Rawhide Strips" then
                  carve(curTask);
                elseif curTask == "Long Sharp Stick" then
                  carve(curTask);
                elseif curTask == "Sharpened Stick" then
                  carve(curTask);
                elseif curTask == "Barrel Tap" then
                  carve(curTask);
                elseif curTask == "Bottle Stopper" then
                  carve(curTask);
                elseif curTask == "Crudely Carved Handle" then
                  carve(curTask);
                elseif curTask == "Large Crude Handle" then
                  carve(curTask);
                elseif curTask == "Personal Chit" then
                  carve(curTask);
                elseif curTask == "Wooden Peg" then
                  carve(curTask);
                elseif curTask == "Wooden Pestle" then
                  carve(curTask);
                elseif curTask == "Clay Lamp" then
                  carve(curTask);
                elseif curTask == "Tackle Block" then
                  carve(curTask);
                elseif curTask == "Wooden Cog" then
                  carve(curTask);
                elseif curTask == "Flax Comb" then
                  combFlax();
                elseif curTask == "Oil (Flax Seed)" then
                  flaxOil();
                elseif curTask == "Weave Canvas" then
                  weave("Canvas");
                elseif curTask == "Weave Linen" then
                  weave("Linen");
                elseif curTask == "Weave Wool Cloth" then
                  weave("Wool");
                elseif curTask == "Weave Papy Basket" then
                  weave("Basket");
                end
                --[[
                elseif curTask == "Hackling Rake" then
                    hacklingRake();
                elseif curTask == "Weave Silk" then
                    weave("Silk");
                elseif curTask == "Push Pyramid" then
                    pyramidPush();
                elseif curTask == "Excavate Blocks" then
                    excavateBlocks();
                elseif curTask == "Tap Rods" then
                    tapRods();
                elseif curTask == "Stir Cement" then
                    stirCement();
                elseif curTask == "Churn Butter" then
                    churnButter();
                elseif curTask == "Search Rotten Wood" then
                    searchRottenWood();
                else
                    clickText(findText(textLookup[curTask]));
                end
                ]]--
                statTimer[i] = lsGetTimer();
                didTask = true;
            end
        end
    end
    if didTask == false then
        lsPrint(10, 10, 0, 0.7, 0.7, 0xB0B0B0ff, "Waiting for task to be ready.");

        if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff,
            "End script") then
            error "Clicked End Script button";
        end

        lsDoFrame();
    else
        srReadScreen();
        --closeEmptyAndErrorWindows();
        closePopUp();
        lsSleep(per_tick);
    end
end

function closePopUp()
  while 1 do -- Perform a loop in case there are multiple pop-ups behind each other; this will close them all before continuing.
      checkBreak();
      lsSleep(250);
      srReadScreen();
      ok = srFindImage("OK.png");
      if ok then
        srClickMouseNoMove(ok[0],ok[1]);
      else
          break;
      end
  end
end

function doit()
    getClickActions();
    if items[2][tasks[2]] == "Push Pyramid" then
        pyramidXCoord = promptNumber("Pyramid x coordinate:");
        pyramidYCoord = promptNumber("Pyramid y coordinate:");
    end
    local mousePos = askForWindow(askText);
    windowSize = srGetWindowSize();
    done = false;
    while done == false do
        doTasks();
        checkBreak();
        lsSleep(80);
    end
end
