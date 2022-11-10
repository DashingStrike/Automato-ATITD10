dofile("common.inc");
dofile("serialize.inc");
dofile("settings.inc")

Status = {INITIALIZING = 0, LIGHTING = 1, IDLE = 2, COOLING = 3, EXTINGUISH = 4, EXTINGUISHING = 5, EXTINGUISHED = 6};
ForgeType = {STUDENT_FORGE = "Student's Forge", MASTER_FORGE = "Master's Forge", ANCIENT_FORGE = "Ancient Forge", STUDENT_CASTING = "Student's Casting Box", MASTER_CASTING = "Master's Casting Box"};

function makeForge (name)
  return {
    name = name,
    status = Status.INITIALIZING,
    lastCheck = lsGetTimer(),
    type = nil,
    initialCC = 0
  };
end

-- Some notes in this macro. You may pin any variety of student casting boxes, master casting boxes, and forges. The macro will prioritize making master only stuff in master boxes, but will then make student goods in them. SELECT HOW MANY OF AN ITEM YOU WANT TO MAKE, NOT HOW MANY ROUNDS TO DO. The macro does know, for instance, that each time you click to make nails it makes 12 nails. - Skyfeather
debug = false; -- This simply prevents the popup box (that tells you what materials you need) from closing, so you can view what it needs. No materials in inventory

function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0			-- iterator variable
  local iter = function ()	 -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

scale = 0.7;
monitor = {
  running = 0;
  startTime = 0;
  forge = {},
  completed = {},
  runCompact = false  
};


initialText = "Forge Macro 0.9 by Skyfeather\n    0.9.1 - MacPhisto\n\t- Added Cascade Mode: 25 or less windows recommended!";
gridModeText = "Grid Mode: true\nAll Forges & Casting Boxes should be pinned. Macro will start forges if needed. Forge & casting box windows should not overlap while cooling items.\n\n";
cascadeModeText = "Cascade Mode: true\nForges & Casting Boxes will be filled with minimum cc required and/or started if needed.\n\n";
materialsText = "\n----------------------------\nMaterials Required:\n";

textLookup = {};
textLookup["Nails - Iron"] = "batch of Nails";
textLookup["Nails - Silver"] = "batch of Silver Nails";
textLookup["Pinch Roller"] = "Make a Pinch Roller";
textLookup["Extrusion Plate"] = "Make an Extrusion Plate";
textLookup["10 Bearings"] = "Make a set of 10 Bearings";
textLookup["60 Washers"] = "Make a set of 60 Washers";
textLookup["40 Bolts"] = "Make a set of 40 Bolts";
textLookup["12 Washers"] = "Make a set of 12 Washers";
textLookup["a bearing"] = "Make a Bearing";
textLookup["4 Bolts"] = "Make a set of 4 Bolts";

windowMode = nil;
ARRANGE_STASH = ARRANGE_STASH or 0;
ARRANGE_GRID = ARRANGE_GRID or 1;
ARRANGE_CASCADE = ARRANGE_CASCADE or 2;

function askForWindowMode()
  scale = 1.1;
	local z = 0;
	local is_done = nil;
	-- Edit box and text display
	while not is_done do
		-- Make sure we don't lock up with no easy way to escape!
		checkBreak("disallow pause");		
		lsSetCamera(0,0,lsScreenX*scale,lsScreenY*scale);
		local y = 7;
		y = drawModeUI(y, z);

		lsPrintWrapped(10, lsScreenY - 75, z+20, lsScreenX - 20, 0.7, 0.7, 0xD0D0D0ff, "---------------------------------------------------------------");
		lsPrintWrapped(10, lsScreenY - 60, z+20, lsScreenX - 20, 0.75, 0.75, 0xD0D0D0ff, "Stand where you can reach all buildings!")
		if windowMode then
			if lsButtonText(10, lsScreenY - 30, z+20, 100, 0x00ff00ff, "Next") then
				is_done = 1;				
			end
		end
	
		if lsButtonText(lsScreenX - 110, lsScreenY - 30, z+20, 100, 0xFF0000ff, "End script") then
			error "Clicked End Script button";
		end
		
		lsDoFrame();
		lsSleep(tick_delay);
	end  
end

function chooseItems(itemList, multiple)    
  scale = 0.7;
  local x, y, z;
  local numRows = 9;
  local pickedOne = false;
  local retList = {};
  while true do
    lsSetCamera(0,0,lsScreenX*scale,lsScreenY*scale);    
    local currentItem = {};
    currentItem.parents = {};
    local leafNode = false;
    local curList = itemList;
    while leafNode == false do
      local parentString = "";
      local suff = "";
      for i=1, #currentItem.parents do
        parentString = parentString .. currentItem.parents[i] .. suff;
        suff = "/";
      end
      if parentString == "" then
        lsPrint(5, 2, z, scale, scale, 0xffffffff, "What would you like to do?");
      else
        lsPrint(5, 2, z, scale, scale, 0xffffffff, string.format("What kind of %s would you like to do?", parentString));
      end
      x = 10;
      y = 30;
      z = 0;
      local c = 0;
      for k, v in pairsByKeys(curList) do
        if c % numRows == 0 and c ~= 0 then
          x = x + 110;
          y = 30;
        end
        local suff = "";
        if v.q == nil then
          suff = "...";
        end
        local buttonColor = 0xffffffff
        if v.masterOnly then
          buttonColor = 0xffff00ff
        end
        if ButtonText(x, y, z, 140, buttonColor, k .. suff, scale, scale) then
          currentItem.name = k;
          curList = curList[k];
          -- check if q exists, which means we're at the leaf.
          if curList.q ~= nil then
            -- Special case treated metal sheeting, add in an extra parent
            if currentItem.name == "Treated Metal" then
              table.insert(currentItem.parents, "Make some Treated Metal Sheeting")
            end
            currentItem.item = curList;
            leafNode = true;
          else
            table.insert(currentItem.parents, currentItem.name);
          end
        end
        c = c + 1;
        y = y + 22;
      end

      auto_extinguish = readSetting("auto_extinguish", auto_extinguish)
      auto_extinguish = CheckBox(10, 232, z, 0xFFFFFFff, " Automatically extinguish forges", auto_extinguish, scale, scale)
      writeSetting("auto_extinguish", auto_extinguish)

      if (windowMode == ARRANGE_CASCADE) then
        auto_take = readSetting("auto_take", auto_take)
        auto_take = CheckBox(10, 252, z, 0xFFFFFFff, " Automatically take completed items", auto_take, scale, scale)
        writeSetting("auto_take", auto_take)

        auto_close = readSetting("auto_close", auto_close)
        auto_close = CheckBox(10, 272, z, 0xFFFFFFff, " Automatically close extinguished windows", auto_close, scale, scale)
        writeSetting("auto_close", auto_close)
      end

      x = 10;
      y = 64 + numRows *22;
      if pickedOne then
        lsPrint(x, y+26, z, scale, scale, 0x00ff00ff, #retList .. " Items Queued:");
        y = y + 22;
        for i=1, #retList do
          local leafParentsString = "";
          for j=1, #retList[i].parents do
            leafParentsString = leafParentsString .. retList[i].parents[j] .. "/";
          end
          local num = retList[i].num;
          if num == -1 then
            num = "Unlimited";
          else
            num = "" .. num;
          end
          lsPrint(x, y+21, z, scale, scale, 0x00ff00ff, string.format("%s %s%s", num, leafParentsString, retList[i].name));
          y = y + 15;
        end
        if shenanigans ~= null then
          lsPrintWrapped(x, y+27, z, lsScreenX + 80, 0.67, 0.67, 0xffff40ff, shenanigans);
        end
      end
      -- Add in exit and optionally done and Back buttons.
      --lsSetCamera(0,0,lsScreenX,lsScreenY);
      if #currentItem.parents ~= 0 then
        if ButtonText(lsScreenX - 80, lsScreenY - 50, z, 90, 0xffff40ff, "Back") then
          local p = currentItem.parents;
          currentItem = {};
          currentItem.parents = {};
          curList = itemList;
          for i=1, #p-1 do
            curList = curList[p[i]];
          end
          currentItem.name = p[#p];
          for i=1, #p-1 do
            currentItem.parents[i] = p[i];
          end
        end
      end
      if ButtonText(lsScreenX - 80, lsScreenY - 25, z, 90, 0xFF0000ff, "Exit") then
        return nil;
      end
      if pickedOne then
        if ButtonText(10, lsScreenY - 25, z, 90, 0x00ff00ff, "Done") then
          return retList;
        end
      end
      lsDoFrame();
      lsSleep(10);
    end
    local numToMake = nil;
    local leafParentsString = "";
    for i=1, #currentItem.parents do
      leafParentsString = leafParentsString .. currentItem.parents[i] .. "/";
    end

    -- less confusing name
    x_pos = string.find(leafParentsString,"x");
      if x_pos then
        x_pos = x_pos - 2; -- find the character before the " x"
        leafParentsString = string.sub(leafParentsString,1,x_pos);
        leafParentsString = leafParentsString .. "/";
      end

    batchItemName = leafParentsString .. currentItem.name;

    currentItem.num = promptNumber(string.format("How many %s%s would you like to make?", leafParentsString, currentItem.name),nil,0.66);
    if multiple then
      if currentItem.num ~= 0 then
        table.insert(retList, currentItem);
      end
    else
      return currentItem
    end
    pickedOne = true;

    --Extra Shenanigans
    -- Pre-Calculate the total amount of materials needed:
    if currentItem.num ~= 0 then
      for i, v in ipairs(retList) do
        lsPrintln(string.format("num = %d, prod = %d, q = %d", v.num, v.item.prod, v.item.q));
        local num = math.ceil(v.num/v.item.prod)*v.item.q;
        local metalType;
        batchNum = v.num;
        batchProd = v.item.prod;
        batchQty = v.item.q;
        batchReq = math.ceil(batchNum/batchProd);
        if batchReq == 1 then
          batchWord = "Batch";
        else
          batchWord = "Batches";
        end

        if v.item.time ~= nil then
          batchTime = v.item.time;
          batchTimeWord = "\nTime Req. Per Batch: " .. batchTime .. "m  ( Total: " .. batchTime * batchReq .. "m )\n";
        else
          batchTime = 0;
          batchTimeWord = "\n";
        end
      end
    else --if currentItem.num ~= 0
      shenanigans = "You chose 0 quantity.\nItem ignored/excluded from list.";
    end --if currentItem.num ~= 0

  end
end

local function makeItem(currentItem, window)
  local parents = currentItem[2];
  local name = currentItem[1];
  local t;
  local subWindow = nil;
  -- Start at 2 so that it skips the Forge... and Casting... objects
  lsPrintln("Making " .. name);
  if #parents >= 2 then
    if parents[2] == "Bars x1" or parents[2] == "Bars x5" or parents[2] == "Bars x10" then
      t = findText("Bars" .. "...", window);
      clickText(t, true, 310, 5);
      subWindow = true;
    elseif parents[2] == "Small Gear x1" or parents[2] == "Small Gear x10" or parents[2] == "Small Gear x20" then
      t = findText("Gearwork" .. "...", window);
      clickText(t, true, 310, 5);
      subWindow = true;
    elseif parents[2] == "Medium Gear x1" or parents[2] == "Medium Gear x10" or parents[2] == "Medium Gear x20" then
      t = findText("Gearwork" .. "...", window);
      clickText(t, true, 310, 5);
      subWindow = true;
    else
      t = findText(parents[2] .. "...", window);
    end
    lsSleep(120);
    if t == nil then
      lsPrintln("Initial window error: " .. parents[2]);
      return false;
    end
    clickText(t, true, 310, 5);
    lsSleep(120);
  end

  for i=3, #parents do
    t = waitForText(parents[i] .. "...", 1000);
    if t == nil then
      lsPrintln("Secondary window error");
      return false;
    end
    clickText(t);
    lsSleep(100);
  end
  local text;
  local lastParent = parents[#parents];  

  if lastParent == "Small Gear x1" then
    t = waitForText("Small Gear...");
    safeClick(t[0]+20,t[1]+4);
    t = waitForText("Make 1 ...");
    safeClick(t[0]+20,t[1]+4);
    text = name .. " Small Gear";
  elseif lastParent == "Small Gear x10" then
    t = waitForText("Small Gear...");
    safeClick(t[0]+20,t[1]+4);
    lsSleep(click_delay);
    t = waitForText("Make 10...");
    safeClick(t[0]+20,t[1]+4);
    lsSleep(click_delay);
    text = name .. " Small Gear";
  elseif lastParent == "Small Gear x20" then
    t = waitForText("Small Gear...");
    safeClick(t[0]+20,t[1]+4);
    t = waitForText("Make 20...");
    safeClick(t[0]+20,t[1]+4);
    text = name .. " Small Gear";
  elseif lastParent == "Medium Gear x1" then
    t = waitForText("Medium Gear...");
    safeClick(t[0]+20,t[1]+4);
    t = waitForText("Make 1 ...");
    safeClick(t[0]+20,t[1]+4);
    text = name .. " Medium Gear";
  elseif lastParent == "Medium Gear x10" then
    t = waitForText("Medium Gear...");
    safeClick(t[0]+20,t[1]+4);
    t = waitForText("Make 10...");
    safeClick(t[0]+20,t[1]+4);
    text = name .. " Medium Gear";
  elseif lastParent == "Medium Gear x20" then
    t = waitForText("Medium Gear...");
    safeClick(t[0]+20,t[1]+4);
    t = waitForText("Make 20...");
    safeClick(t[0]+20,t[1]+4);
    text = name .. " Medium Gear";
  elseif lastParent == "Bars x10" then
    t = waitForText("Make 10 sets");
    safeClick(t[0]+20,t[1]+4);
    text = name .. " Bars";
  elseif lastParent == "Bars x5" then
    t = waitForText("Make 5 sets");
    safeClick(t[0]+20,t[1]+4);
    text = name .. " Bars";
  elseif lastParent == "Bars x1" then
    t = waitForText("Make 1 set");
    safeClick(t[0]+20,t[1]+4);
    text = name .. " Bars";
  end  

  if (subWindow) then
    lsSleep(click_delay);
    srReadScreen();
    srSetMousePos(t[0]+40,t[1]+8);
    subWindow = getWindowBorders(t[0]+40,t[1]+28);
    lsSleep(click_delay);
    --print(dump(subWindow));
    --print("Box: " .. subWindow.x .. "," .. subWindow.y .. "/" .. subWindow.width .. "," .. subWindow.height);  
  end
  lsSleep(100);

  -- Check if we have to click down arrow button (scrollable menu)
  if (lastParent == "Bars x1" or lastParent == "Bars x5" or lastParent == "Bars x10") and name > "Titanium" then
    local t = waitForText("Aluminum Bars", nil, nil, subWindow);
    downArrow(); -- Click the Down arrow button to scroll
  end
  if (lastParent == "Sheeting" or lastParent == "Straps" or lastParent == "Wire")  and name > "Titanium" then
    local t = waitForText("Make Aluminum", nil, nil, subWindow);
    downArrow(); -- Click the Down arrow button to scroll
  end

  if lastParent == "Sheeting" or lastParent == "Wire" then
    text = string.format("Make %s %s", name, lastParent);
  elseif lastParent == "Pipes" or lastParent == "Foils" or lastParent == "Straps" then
    text = string.format("Make %s %s", name, string.sub(lastParent, 1, #lastParent-1));
  elseif lastParent == "Large Gear" then
    text = string.format("Make %s %s", name, lastParent);
  elseif lastParent == "Steam Mechanics" then
    text = "Make a " .. name;
  elseif lastParent == "Tools" then
    if name == "Iron Poker" then
      text = "Make an " .. name;
    else
      text = "Make a " .. name;
    end
  elseif lastParent == "Make some Treated Metal Sheeting" then
    text = "From";
  elseif text == nil then
    text = name;
  end
  if textLookup[text] ~= nil then
    text = textLookup[text];
  end

  lsPrintln(string.format("Searching for text %s", text));
  -- For top level items look in the window we're currently on
  -- otherwise, search the entire screen.
  if #parents == 1 then
    t = waitForText(text, 1000, nil, window);
  elseif subWindow ~= nil then
    t = waitForText(text, 1000, nil, subWindow);
  else
    t = waitForText(text, 1000);
  end
  
  if t == nil then
    lsPrintln("Couldn't find: " .. text);
    return false;
  end
  
  --lsPrintln("Found " .. text .. " @ ("..t[0]+20 .. "," .. t[1]+4 .. ")");
  safeClick(t[0]+20,t[1]+4);
  if #parents ~= 1 then
    waitForNoText(text, nil, nil, subWindow);
  end

  if name == "Pincher Axle" or name == "Pincher Claw" then

    if name == "Pincher Axel" then
      pincherPlating = "Platinum"
    elseif name == "Pincher Claw" then
      pincherPlating = "Aluminum"
    end

    srSetWindowBorderColorRange(minThickWindowBorderColorRange, maxThickWindowBorderColorRange);
    lsSleep(1000);
    srReadScreen();
    requiresWindow = findText("requires:", nil, REGION);
    t = findText(pincherPlating .. "-Plated",requiresWindow);
      if t ~= nil then
        safeClick(t[0],t[1]);
        lsSleep(per_tick);
        srReadScreen()
        ok = srFindImage("ok.png")
          if ok then
            safeClick(ok[0],ok[1]);
          end -- if ok
      end -- if t
    srSetWindowBorderColorRange(minThinWindowBorderColorRange, maxThinWindowBorderColorRange);
  end -- if name

  -- Quick/dirty hack to get Stainless working on T8. Above commented section doesn't work due to how the text displays
  if name == "Stainless Steel Pot" then
    local win = waitForText("A stainless Steel Pot requires", 1000, nil, nil, REGION);

    if win ~= nil then
      t = findText("Steel");

      if t ~= nil then
        safeClick(t[0]+20,t[1]+60);
        lsSleep(per_tick);
        srReadScreen()
        ok = srFindImage("ok.png")
        if ok then
          safeClick(ok[0],ok[1]);
        end -- if ok
      end -- if t
    end -- if win
  end -- if name
  lsSleep(per_tick);
  return true;
end

-- For cascade mode.
function extinguish(window)   
  local t = findText("is lit", window);
  if (t) then
    clickText(t);
    lsSleep(click_delay);
    clickText(findText("Put out", window));
    waitAndClickImage("Yes.png");
    --waitForNoText("Put out", 2500, "Extinguish Latency check...", window);
    --clickText(t);    
    return true;
  end

  return false;
end

-- Original for grid mode (unchanged)
function putOutWindows(text)
  t = findAllText(text .. " is lit", nil, REGION);
  for i=1, #t do
    clickText(findText("Put out", t[i]));
    local yes = waitForImage(
      "Yes.png",
      60000,
      "Waiting for 'Yes' text on the screen."
    );
    waitAndClickImage("Yes.png");
  end
  sleepWithStatus(2500, "Latency check", nil, 0.7);
  refreshWindows();
end

function doit()
  unpinOnExit(runForges);
end

function runForges()
  local t;
  success, forgeItems = deserialize("forge_items.txt");
  if success == false then
    error("Could not read forge info");
  end
  success, castingItems = deserialize("casting_items.txt");
  if success == false then
    error("Could not read casting box info");
  end
  success, ancientItems = deserialize("ancientforge_items.txt");
  if success == false then
    error("Could not read ancient forge info");
  end

  askForWindow(initialText);
  windowMode = windowManager(nil,nil, true, false, 483, 383, nil, 10, 20,false) or -1;
  print ('Arrange Mode: ' .. windowMode);
  if (windowMode < 1) then
    askForWindowMode();
  end

  local topLevel = {};
  topLevel.Forge = forgeItems;
  topLevel.Casting = castingItems;
  topLevel.Ancient = ancientItems;
  desiredItems = chooseItems(topLevel, true);
  local next = next;
  if desiredItems == nil or next(desiredItems) == nil then
    return;
  end

  -- Calculate the total amount of materials needed:
  local mats = {};
  local beeswax = 0;
  for i, v in ipairs(desiredItems) do
    lsPrintln(string.format("num = %d, prod = %d, q = %d", v.num, v.item.prod, v.item.q));
    local num = math.ceil(v.num/v.item.prod)*v.item.q;
    local metalType;
    if v.parents[1] == "Casting" or v.parents[1] == "Ancient" then
      if v.item.beeswax == nil then
        beeswax = beeswax + num;
      else
        beeswax = beeswax + math.ceil(v.num/v.item.prod)*v.item.beeswax;
      end
    end
    if v.item.metal == nil then
      metalType = v.name
    else
      metalType = v.item.metal;
    end
    if v.num ~= -1 then
      if mats[metalType] == nil then
        mats[metalType] = num;
      else
        mats[metalType] = num + mats[metalType];
      end
    end
  end

  local printText = (windowMode == ARRANGE_CASCADE) and cascadeModeText or gridModeText;
  printText = printText .. string.format("Auto Extinguish: %s\n", auto_extinguish);
  if (windowMode == ARRANGE_CASCADE) then      
    printText = printText .. string.format("Auto Take: %s\n", auto_take);
    printText = printText .. string.format("Auto Close: %s\n", auto_close);
  end
  printText = printText .. materialsText;
  for k, v in pairsByKeys(mats) do
    local num = mats[k];
    if num == -1 then
      num = "Unlimited";
    else
      num = "" .. num;
    end
    printText = printText .. string.format("%s %s\n", num, k);
  end
  if beeswax ~= 0 then
    printText = printText .. string.format("Beeswax %d\n", beeswax);
  end
  askForWindow(printText);

  itemQueue = {};
  itemQueue["Student's Forge"] = {};
  itemQueue["Master's Forge"] = {};
  itemQueue["Student's Casting Box"] = {};
  itemQueue["Master's Casting Box"] = {};
  itemQueue["Ancient Forge"] = {};
  viableQueue = {}
  viableQueue["Student's Forge"] = {"Student's Forge"};
  viableQueue["Master's Forge"] = {"Master's Forge", "Student's Forge"};
  viableQueue["Student's Casting Box"] = {"Student's Casting Box"};
  viableQueue["Master's Casting Box"] = {"Master's Casting Box", "Student's Casting Box"};
  viableQueue["Ancient Forge"] = {"Ancient Forge"};

  -- Build item queues that we're going to pull from to make stuff.
  -- Add them in backwards so that we can pop cheaply
  for i=#desiredItems, 1, -1 do
    local v = desiredItems[i];
    local toMake = math.ceil(v.num/v.item.prod);
    for j=1, toMake do
      if v.parents[1] == "Forge" then
        if v.item.masterOnly then
          table.insert(itemQueue["Master's Forge"], {v.name, v.parents});
        else
          table.insert(itemQueue["Student's Forge"], {v.name, v.parents});
        end
      elseif v.parents[1] == "Casting" then
        if v.item.masterOnly then
          table.insert(itemQueue["Master's Casting Box"], {v.name, v.parents});
        else
          table.insert(itemQueue["Student's Casting Box"], {v.name, v.parents});
        end
      elseif v.parents[1] == "Ancient" then
        ancientForging = true;
        table.insert(itemQueue["Ancient Forge"], {v.name, v.parents});
      else
        error("Invalid data type for queue");
      end
    end
  end

  if (windowMode == ARRANGE_GRID) then
    runGrid();
  elseif (windowMode == ARRANGE_CASCADE) then
    runCascade();
  end



end

-- Original grid mode (unchanged)
function runGrid()
  srReadScreen();
  clickAllText("in the chamber");
  lsSleep(200);
  srReadScreen();
  local t = nil;
  local win = findAllText("in the chamber", nil, REGION);
    for i=1, #win do
      -- is it lit? if not, light it.
      t = findText("is out", win[i]);
      local ccamount;
      local u = findText("in the chamber", win[i]);
      if ancientForging then
        curCC = tonumber(string.match(u[2], "(%d+) Orichalcum Pellet in the chamber."));
      else
        curCC = tonumber(string.match(u[2], "(%d+) Charcoal in the chamber."));
      end
        if findText("Student's Forge", win[i]) then
          ccamount = 60;
        elseif findText("Master's Forge", win[i]) then
          ccamount = 250;
        elseif findText("Student's Casting Box", win[i]) then
          ccamount = 100;
        elseif findText("Master's Casting Box", win[i]) then
          ccamount = 600;
        elseif findText("Ancient Forge", win[i]) then
          ccamount = 60;
        end
      local toAdd = ccamount - curCC;
        if t and toAdd > 0 then
          clickText(findText("Fill this ", win[i]));
            if ancientForging then
              waitForImage("max.png", nil, "Waiting for Orichalcum Pellet message");
            else
              waitForImage("max.png", nil, "Waiting for Charcoal message");
            end
          srKeyEvent(string.format("%d\n", toAdd));
          waitForNoImage("max.png");
          lsSleep(100);
          closePopUp();
        end
    end
  clickAllText("Start fire");

  -- Begin infinite loop. Broken out of by finishing making all items.
  while 1 do
    local t, u;
    sleepWithStatus(1500, "Sleeping before checking forges again", nil, 0.7);
    srReadScreen();
    foundOne = false;
    for k, v in pairs(itemQueue) do
      if #v > 0 then
        foundOne = true;
      end
    end

    t = findText("cooling");
    local numItemsLeft = 0;
    for k, v in pairs(itemQueue) do
      numItemsLeft = numItemsLeft + #itemQueue[k];
    end
    if t == nil and numItemsLeft == 0 then
      -- Queue is empty, put out the forges
      if auto_extinguish then
        putOutWindows("The fire");
        return;
      end
    end
    local windows = findAllText("is lit", nil, REGION);
    for i=1, #windows do
      local charcoalText = findText("in the chamber", windows[i]);
      if charcoalText then
        if ancientForging then
          local cc = tonumber(string.match(charcoalText[2], "(%d+) Orichalcum Pellet in the chamber."));
        else
          local cc = tonumber(string.match(charcoalText[2], "(%d+) Charcoal in the chamber"));
        end
          if cc and cc <= 10 then
            t = findText("Fill this ", windows[i]);
            clickText(t);
              if ancientForging then
                waitForImage("max.png", nil, "Waiting for orichalcum pellet topoff");
              else
                waitForImage("max.png", nil, "Waiting for charcoal topoff");
              end
            srKeyEvent("10\n");
            waitForNoImage("max.png");
          end
      end
      
      t = findText("is cooling", windows[i]);
      if t == nil then
        if findText("Master's Casting Box", windows[i]) then
          buildingType = "Master's Casting Box";
        elseif findText("Student's Casting Box", windows[i]) then
          buildingType = "Student's Casting Box";
        elseif findText("Master's Forge", windows[i]) then
          buildingType = "Master's Forge";
        elseif findText("Student's Forge", windows[i]) then
          buildingType = "Student's Forge";
        elseif findText("Ancient Forge", windows[i]) then
          buildingType = "Ancient Forge";
        end
        local currentItem, currentQueue;
        if #itemQueue[buildingType] ~= 0 then
          currentQueue = buildingType;
          currentItem = table.remove(itemQueue[currentQueue]);
        else
          if buildingType == "Master's Casting Box" and #itemQueue["Student's Casting Box"] ~= 0 then
            currentQueue = "Student's Casting Box";
            currentItem = table.remove(itemQueue[currentQueue]);
          elseif buildingType == "Master's Forge" and  #itemQueue["Student's Forge"] ~= 0 then
            currentQueue = "Student's Forge";
            currentItem = table.remove(itemQueue[currentQueue]);
          end
        end
        if currentItem ~= nil then
          local madeItem = makeItem(currentItem, windows[i]);
          if madeItem ~= true then
            table.insert(itemQueue[currentQueue], currentItem);
          end
        end
      end
    end
    lsSleep(100);
    srReadScreen();
    clickAllImages("ThisIs.png");
  end
end

function runCascade()
  local cascadeOffset = 650;
  
  srReadScreen();
  local wins = findAllImages("windowCorner.png", nil, 500);
  print('Windows found: ' .. #wins);
  
  local t, u;

  -- Setup forge monitor
  for i=1,#wins do   
    monitor.forge[#monitor.forge+1] = makeForge("Forge " .. i);    
  end
  
  monitor.startTime = lsGetTimer();
  -- Begin infinite loop. Broken out of by finishing making all items
  while 1 do         
    srReadScreen();
    wins = findAllImages("windowCorner.png", nil, 500); 
    --print("Windows found: " .. #wins);
  
    for i=1,#wins do
      local forge = monitor.forge[i];
      print(string.format("Begin: %s (%s)", forge.name, getElapsedTime(forge.lastCheck)));
      forge.lastCheck = lsGetTimer();
      forge.x = wins[i][0]+5;
      forge.y = wins[i][1]+5;    

      --print(forge.name);
     
      -- bring this window to the top
      safeClick(forge.x, forge.y);
      lsSleep(click_delay);
      srReadScreen();
      forge.bounds = getWindowBorders(forge.x, forge.y);

      if (forge.status == Status.EXTINGUISHED) then
        if auto_close then
          unpinWindow(forge.bounds);
          monitor.completed[#monitor.completed+1] = forge;
          monitor.forge[i] = nil;
          monitor.runCompact = true;
          goto skip
        end

        goto continue
      end     


      if (forge.status == Status.INITIALIZING) then
        if findText("Master's Casting Box", forge.bounds) then
          forge.type = ForgeType.MASTER_CASTING;
          forge.initialCC = 600;
        elseif findText("Student's Casting Box", forge.bounds) then
          forge.type = ForgeType.STUDENT_CASTING;
          forge.initialCC = 100;
        elseif findText("Master's Forge", forge.bounds) then
          forge.type = ForgeType.MASTER_FORGE;
          forge.initialCC = 250;
        elseif findText("Student's Forge", forge.bounds) then
          forge.type = ForgeType.STUDENT_FORGE;
          forge.initialCC = 60;
        elseif findText("Ancient Forge", forge.bounds) then
          forge.type = ForgeType.ANCIENT_FORGE;
          forge.initialCC = 60;
        end

        forge.itemQueue = itemQueue[forge.type];

        -- Forge hasn't been lit yet. Add CC if needed and light it
        if findText("is out", forge.bounds) then          
          local u = findText("in the chamber", forge.bounds);
          curCC = tonumber(string.match(u[2], "There is ([-0-9]+) "));
          local toAdd = (curCC < forge.initialCC) and (forge.initialCC - curCC) or 0;
          
          if toAdd > 0 then
            clickText(findText("Fill this ", forge.bounds));
            waitForImage("max.png", nil, "Waiting for Add Fuel message");
            lsSleep(tick_delay);
            srKeyEvent(string.format("%d\n", toAdd));
            waitForNoImage("max.png");
            lsSleep(tick_delay);
            closePopUp();
          end
    
          clickText(findText("Start fire", forge.bounds));
          lsSleep(click_delay);
          srReadScreen();

          if (findImage("ok.png")) then
            -- This suggest we don't have enough CC to add to start the forge
            closePopUp();
            print("Not enough CC to start this forge!");
          end
        end

        if (pollWindowForText("is lit", forge.bounds, 250, "Waiting for forge to light") ~= nil) then
        --if findText("is lit", forge.bounds) then
          forge.bounds = getWindowBorders(forge.x, forge.y);
          monitor.running = monitor.running + 1;
          forge.status = Status.IDLE;
        end

        lsSleep(tick_delay);
      end

      if (forge.status == Status.EXTINGUISHING) then
        if findText("is out", forge.bounds) then
          print("Fire is out.");                    
          forge.status = Status.EXTINGUISHED;
          forge.runTime = getElapsedTime(monitor.startTime, forge.lastCheck);                     
        end

        lsSleep(tick_delay);
      end

      if (forge.status ~= Status.EXTINGUISHED) then
        if (forge.status == Status.COOLING) then
          print("Forge Cooling...");

          if (findText("is out", forge.bounds)) then
            forge.status = Status.EXTINGUSHED;
          else
            topoffFuel(forge);
            local t = findText("cooling", forge.bounds);
            if not findText("cooling", forge.bounds) then       
              forge.status = Status.IDLE;
            end
          end

          lsSleep(tick_delay);
        end
        
        if (forge.status == Status.IDLE) then
          print("Forge Idle...");
         
          -- Forge is running... Add CC if it's low and keep making items!
          if findText("is lit", forge.bounds) then
            local currentItem;
            if #forge.itemQueue ~= 0 then
              currentItem = table.remove(forge.itemQueue);
            else
              if forge.type == MASTER_CASTING and #itemQueue[STUDENT_CASTING] ~= 0 then
                forge.itemQueue = itemQueue[STUDENT_CASTING];                
                currentItem = table.remove(forge.itemQueue);
              elseif forge.type == MASTER_FORGE and #itemQueue[STUDENT_FORGE] ~= 0 then
                forge.itemQueue = itemQueue[STUDENT_FORGE]; 
                currentItem = table.remove(forge.itemQueue);
              end
            end

            if currentItem ~= nil then
              topoffFuel(forge.bounds);
              
              local madeItem = makeItem(currentItem, forge.bounds);
              if madeItem ~= true then
                table.insert(forge.itemQueue, currentItem);
              else
                --safeClick(forge.x, forge.y);
                --lsSleep(click_delay);
                --srReadScreen();
    
                --lsPrintln("Box: " .. forge.bounds.x .. "," .. forge.bounds.y .. "/" .. forge.bounds.width .. "," .. forge.bounds.height);
                pollWindowForText("cooling", forge.bounds, nil, string.format("%s - Waiting for cooling...", forge.name));
                forge.status = Status.COOLING;
              end
            else
              print("No items left to make...");
              --if #forge.itemQueue == 0 then
                -- Queue is empty, we're finished with this building type..          
                if auto_take then 
                    local p = findText("Take...", forge.bounds);
                    if (p) then
                      clickText(p)
                      lsSleep(click_delay);
                      local e = waitForText("Everything");
                        if (e) then
                          clickText(e);
                          sleepWithStatus(500,"Taking Items...", nil, 0.7, 0.7);
                        end
                  end
                end
        
                if auto_extinguish then forge.status = Status.EXTINGUISH; end
            end
          else
            forge.status = Status.EXTINGUISHED;
          end

          lsSleep(tick_delay);
        end

        if (forge.status == Status.EXTINGUISH) then
          print("Extinguishing fire...");
          if (extinguish(forge.bounds)) then
            monitor.running = monitor.running - 1;   
            forge.status = Status.EXTINGUISHING;
          end

          lsSleep(tick_delay);
        end        
      end

      ::continue::
      lsSleep(100);
      print(string.format("Moving Window: (%s,%s) -> (%s,%s)", forge.x, forge.y, forge.x+cascadeOffset+1, forge.y+1));
      safeDrag(forge.x, forge.y, forge.x+cascadeOffset+1, forge.y+1);
      lsSleep(click_delay);
      --srReadScreen();
      print(string.format("End: %s (%s)", forge.name, getElapsedTime(forge.lastCheck)));
      forge.lastCheck = lsGetTimer();
      ::skip::
    end

    if ((auto_close and next(monitor.forge) == nil) or (not auto_close and monitor.running <= 0)) then
      print("Elapsed Time: " .. getElapsedTime(monitor.startTime));
      lsMessageBox("Elapsed Time:", getElapsedTime(monitor.startTime), 1);
      return;
    end

  
    if monitor.runCompact then 
      compactTable(monitor.forge, function (t, i, j) return t[i] ~= nil; end); 
      monitor.runCompact = false;
    end

    cascadeOffset = cascadeOffset * -1;
    sleepWithStatus(1500, "Sleeping before checking forges again", nil, 0.7);
  end

end

function downArrow()
  srReadScreen();
  downPin = srFindImage("Fishing/Menu_DownArrow.png");
    if downPin then
      srClickMouseNoMove(downPin[0]+8,downPin[1]+5);
      lsSleep(100);
    end
end

function topoffFuel(forge)
  local charcoalText = findText("in the chamber", forge.bounds);
  if charcoalText then    
    local cc = tonumber(string.match(charcoalText[2], "There is ([-0-9]+) "));
    if cc and cc <= 10 then
      clickText(findText("Fill this ", forge.bounds));
      waitForImage("max.png", nil, "Waiting for fuel topoff");
      srKeyEvent("10\n");
      waitForNoImage("max.png");
    end
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

function drawModeUI(y, z)
	local gridModeColor = 0xffffffff;
	local cascadeModeColor = 0xffffffff;
	local helpText = "Check Grid or Cascade Mode to Begin"
	gridMode = readSetting("gridMode",gridMode);
	cascadeMode = readSetting("cascadeMode",cascadeMode);

	if gridMode then
		gridModeColor = 0x80ff80ff;
		helpText = "Uncheck to switch to Cascade Mode"
	elseif hotkeyMode then
		cascadeModeColor = 0x80ff80ff;
		helpText = "Uncheck to switch to Grid Mode"
	end

	if not gridMode and not cascadeMode then
		lsPrintWrapped(10, y, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff, "Window Mode Settings\n---------------------------------------");
		y = y + 28;
		gridMode = CheckBox(10, y, z, gridModeColor, " Grid Mode", gridMode, 0.65, 0.65);
		writeSetting("gridMode",gridMode);
		y = y + 22;
		cascadeMode = CheckBox(10, y, z, cascadeModeColor, " Cascade Mode", cascadeMode, 0.65, 0.65);
		writeSetting("cascadeMode",cascadeMode);
		y = y + 28;
		lsPrint(10, y, z, 0.65, 0.65, 0xFFFFFFff, helpText);
    windowMode = nil;
	elseif gridMode and not cascadeMode then
		lsPrintWrapped(10, y, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff, "Window Mode Settings\n---------------------------------------");
		y = y + 28;
		gridMode = CheckBox(10, y, z, gridModeColor, " Grid Mode", gridMode, 0.65, 0.65);
		writeSetting("gridMode",gridMode);
    cascadeMode = false;
		y = y + 22;
		lsPrint(10, y, z, 0.65, 0.65, 0xFFFFFFff, helpText);
    windowMode = ARRANGE_GRID;
	elseif cascadeMode and not pinnedMode then
		lsPrintWrapped(10, y, z, lsScreenX - 20, 0.7, 0.7, 0xffff40ff, "Window Mode Settings\n---------------------------------------");
		y = y + 28;
		cascadeMode = CheckBox(10, y, z, cascadeModeColor, " Cascade Mode", cascadeMode, 0.65, 0.65);
		writeSetting("cascadeMode",cascadeMode);
		gridMode = false;
		writeSetting("gridMode",gridMode);
		y = y + 22;
		lsPrint(10, y, z, 0.65, 0.65, 0xFFFFFFff, helpText);							
    windowMode = ARRANGE_CASCADE;
	end	
  
	return y + 28; 
end


function drawCascadeMonitorUI(monitor, index, forge)
  -- TODO
end


-- The waitFor functions in common_wait don't 
function pollText(args)
  local text = args[1];
  local range = args[2];
  local flags = args[3];
  local sizemod = args[4];
  safeClick(range.x+10,range.y+5);
  lsSleep(click_delay);
  srReadScreen();
  return findText(text, range, flags, sizemod);
end
function pollWindowForText(text, range, timeout, message, flags, sizemod)
  if not text and not range then
    error("Incorrect number of arguments for pollForText()");
  end
  return waitForFunction(pollText, {text, range, flags, sizemod}, timeout, message);
end


-------------------------------------------------------------------------------
-- getElapsedTime(startTime)
--
-- Returns a formatted string containing the elapsed time
--
-- startTime -- The time the macro started as returned by lsGetTimer()
-- endTime [optional] -- The time the macro ended. Defaults to lsGetTimer()
-------------------------------------------------------------------------------
local function getElapsedTime(startTime, endTime)
  local endTime = endTime or lsGetTimer();
  local duration = math.floor((endTime - startTime) / 1000);
  local hours = math.floor(duration / 60 / 60);
  local minutes = math.floor((duration - hours * 60 * 60) / 60);
  local seconds = duration - hours * 60 * 60 - minutes * 60;
  return string.format("%02d:%02d:%02d",hours,minutes,seconds);
end


function dump(o)
  if type(o) == 'table' then
     local s = '{ '
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. dump(v) .. ','
     end
     s = s .. '} ';
     return s;
  else
     return tostring(o)
  end
end

function compactTable(t, filterFn)
  local j, n = 1, #t;

  for i=1,n do
      if (filterFn(t, i, j)) then
          -- Move i's kept value to j's position, if it's not already there.
          if (i ~= j) then
              t[j] = t[i];
              t[i] = nil;
          end
          j = j + 1; -- Increment position of where we'll place the next kept value.
      else
          t[i] = nil;
      end
  end

  return t;
end