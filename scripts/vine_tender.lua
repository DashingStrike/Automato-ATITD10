dofile("common.inc");

----------------------------------------
--          Global Variables          --
----------------------------------------
alsoTend = 1;
alsoCutting = 0;
alsoHarvest = 0;
replant = 0;
harvestFlag = 0;
vineForReplanting=1;
tendedCount = 0
vines = {};
vinesUsed = {};
vineCustomsUsed = {};

knownVineNames = {
  { name = "Amusement",
    image = "Amusement" },
  { name = "Appreciation",
    image = "Appreciation" },
  { name = "Balance",
    image = "Balance" },
  { name = "Brilliance",
    image = "Brilliance" },
  { name = "Distraction",
    image = "Distraction" },
  { name = "Frivolity",
    image = "Frivolity" },
  { name = "Wisdom",
    image = "Wisdom" }
};

vineyardActions = { "Tend", "Harvest", "Cutting" };
vineyardImages = { "", "Harvest the Gr", "Take a Cutting of the V" };

stateNames = {"Fat", "Musty", "Rustle", "Sagging", "Shimmer",
	      "Shrivel", "Wilting"};

vineStates = { "vineyard/State_Fat.png", "vineyard/State_Musty.png",
	       "vineyard/State_Rustle.png", "vineyard/State_Sagging.png",
	       "vineyard/State_Shimmer.png", "vineyard/State_Shrivel.png",
	       "vineyard/State_Wilting.png" };

tendActions = {"AS", "MG", "PO", "SL", "SV", "TL", "TV"};
tendIndices = { ["AS"] = 1, ["MG"] = 2, ["PO"] = 3, ["SL"] = 4, ["SV"] = 5,
		["TL"] = 6, ["TV"] = 7 };

tendImages = {
  ["AS"] = "vineyard/Action_AS.png",
  ["MG"] = "vineyard/Action_MG.png",
  ["PO"] = "vineyard/Action_PO.png",
  ["SL"] = "vineyard/Action_SL.png",
  ["SV"] = "vineyard/Action_SV.png",
  ["TL"] = "vineyard/Action_TL.png",
  ["TV"] = "vineyard/Action_TV.png" };

vigorNames = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11",
	       "12", "13", "14", "15" };

askText = "Automatically tends vineyards based on vine type.\n\n"
.. "Make sure you are standing to where vineyard windows open away from VT screen."
.. " This version uses OCR and reads text, that will fail if the window"
.. " (or borders) is even slightly blocked from view.";

----------------------------------------
function doit()
  askForWindow(askText);
  parseVines();
  local status = "";
  while 1 do
    promptVineyard(status);
    local x, y = srMousePos();
    openAndPin(x, y, 2000);
    srReadScreen();
    local activeVine = getVineName();
    if alsoTend  then
      status = processVineyard();
    end
    if alsoCutting then
      status = status .. "\n\n" .. cutMe();
    end
    if harvestFlag == 2 then
      --harvest first
      status = status .. "\n\n" .. harvestMe()
      if replant then
        if vineForReplanting==1 then
          status = status .. "\n\n" .. plantMe(activeVine.image);
        else
          status = status .. "\n\n" .. plantMe(vines[vineForReplanting-1].image);
        end
        if alsoTend then
          sleepWithStatus(1000, "Waiting for plants to grow");
          if refreshVineyard() then
            waitForImage("vineyard/CanBeTended.png",2000,"Waiting for refresh")
            sleepWithStatus(500, "Preparing to tend");
            status = status .. "\n\n" .. processVineyard();
          else
            status = status .. "\n\nCould not locate vineyard";
          end
        end
      end
    end
    --Using this to close the window instead of CloseAllWindows() as this appears to havew a double click issue.
    srReadScreen();
    clickAllText("Vineyard", 20, 2, 1)
  end
end

function promptVineyard(status)
    local scale = 0.7;
    while not lsControlHeld() do
    local checkStart = 150

    local edit = lsButtonText(10, lsScreenY - 30, 0, 120, 0xBBA661FF, "Edit Tends");
    lsPrint(10, lsScreenY - 103, 0, 0.7, 0.7, 0xffff40ff,
    "----------------------------------------------------------------");
    alsoTend = CheckBox(20, lsScreenY - checkStart + 63, 10, 0xFFFFFFFF,
    " Tend Vine", alsoTend, scale, scale);
    alsoCutting = CheckBox(20, lsScreenY - checkStart + 83, 10, 0xFFFFFFFF,
    " Take Cuttings", alsoCutting, scale, scale);
    alsoHarvest = CheckBox(170, lsScreenY - checkStart + 63, 10, 0xFFFFFFFF,
    " Auto Harvest", alsoHarvest, scale, scale);
    replant = CheckBox(170, lsScreenY - checkStart + 83, 10, 0xFFFFFFFF,
    " Auto Replant", replant, scale, scale);
    lsPrint(10, lsScreenY - checkStart + 96, 0, 0.7, 0.7, 0xffff40ff,
    "----------------------------------------------------------------");

    if replant then
      local tends = {};
      tends[1] = "same as harvested"
      if #vines > 0 then
        for i=1,#vines do
          tends[i+1] = vines[i].name;
        end
        lsPrint(10, 56, 0, 0.7, 0.7, 0xffff40ff,"----------------------------------------------------------------");
        lsPrint(30, 40, 0, 0.7, 0.7, 0x00ff00ff,"Replant Vine: ");
        lsSetCamera(0,0,lsScreenX*1.4,lsScreenY*1.4);
        vineForReplanting = lsDropdown("With", 180, 56, 0, 200, vineForReplanting, tends);
        lsSetCamera(0,0,lsScreenX*1.0,lsScreenY*1.0);
      end
    end

    lsSetCamera(0,0,lsScreenX*1.0,lsScreenY*1.0);
    lsPrint(10, 9, 0, 0.7, 0.7, 0xffd0d0ff,"Tap Ctrl key over a vineyard");
    lsPrint(10, 24, 0, 0.7, 0.7, 0xffff40ff,"----------------------------------------------------------------");
    statusScreen(status,nil,false,0.7);
      if edit then
        promptTends();
      end
    lsSleep(tick_delay);
  end

  while lsControlHeld() do
    statusScreen("Release control (Ctrl)");
  end
  return 1;
end

function harvestMe()
  local clickPos = findText(vineyardImages[2]);
  myStatus = " ";
  if clickPos then
    safeClick(clickPos[0] + 10, clickPos[1] + 5);
    local yes = waitForImage("Yes.png", 500);
    if yes then
      safeClick(yes[0] + 5, yes[1] + 5);
    end
    myStatus = vineyardActions[2] .. " complete";
  else
    myStatus = "Cannot find " .. vineyardActions[2] .. " button";
  end
return myStatus;
end

function noCuttings()
local hasNoCuttings = waitForImage("OK.png",250,"Waiting for popup");
  if hasNoCuttings then
      safeClick(hasNoCuttings[0] + 10, hasNoCuttings[1] + 10);
      return "No Cuttings";
  else
      return vineyardActions[3]
	  .. " complete";
  end
end

function cutMe()
  local clickPos = findText(vineyardImages[3]);
    if clickPos then
      safeClick(clickPos[0] + 10, clickPos[1] + 5);
      myStatus = noCuttings();
    else
      myStatus = "Cannot find " .. vineyardActions[3] .. " button";
    end
  return myStatus;
end

function refreshVineyard()
  local refreshPos = findText("Vineyard");
  if refreshPos then
    safeClick(refreshPos[0] + 10, refreshPos[1] + 5);
  end
return refreshPos
end

function plantMe(vineToPlant)
  --refresh window first
  sleepWithStatus(500, "Refreshing window");
  myStatus = "Attempting to find (" .. vineToPlant .. ")";
  if refreshVineyard() then
    local PlantPos = waitForText("Plant", 500);
    if PlantPos then
      safeClick(PlantPos[0] + 10, PlantPos[1] + 5);
      sleepWithStatus(500, "Waiting for new window");
      srReadScreen();
      local newVine = findText( vineToPlant );
      if newVine then
        sleepWithStatus(500, "Planting new vine: " .. vineToPlant );
        safeClick(newVine[0] + 25, newVine[1] + 5);
        sleepWithStatus(250, "Final click");
        myStatus = "Replanted " .. vineToPlant
      else
        myStatus = "\n\nCould not find (" .. vineToPlant .. ") to replant.";
      end
    else
      myStatus =  "\n\nCould not find 'Plant.'";
    end
  else
    myStatus = "\n\nCould not find name.";
  end
  return myStatus;
end

function promptTends()
  local done = false;
  local vineIndex = 1;
  while not done do
    local add = lsButtonText(lsScreenX/2 - 60, 10, 0, 120, 0xffffffff, "Add Tend");
    local edit = false;
    local delete = false;
    if #vines > 0 then
      local tends = {};
        for i=1,#vines do
          tends[i] = vines[i].name;
        end
      lsSetCamera(0,0,lsScreenX*1.2,lsScreenY*1.2);
      vineIndex = lsDropdown("TendIndex", 30, 100, 0, 250, vineIndex,
			     tends);
      lsSetCamera(0,0,lsScreenX*1.0,lsScreenY*1.0);
      edit = lsButtonText(lsScreenX/2 - 60, 120, 0, 120, 0xffffffff, "Edit Tend");
      delete = lsButtonText(lsScreenX/2 - 60, 150, 0, 120, 0xffffffff, "Delete Tend");
    end
    done = lsButtonText(10, lsScreenY - 30, 0, 100, 0x00ff00ff, "Done");
    if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFF0000ff,"End Script") then
      error(quit_message);
    end
    checkBreak();
    lsSleep(tick_delay);
    lsDoFrame();
      if add then
        promptAdd();
      elseif edit then
        promptEdit(vines[vineIndex]);
      elseif delete then
        table.remove(vines, vineIndex);
        saveVines();
        parseVines();
      end
    lsSleep(tick_delay);
  end
end

function promptAdd()
  local vineNames = {};
  local vineCustoms = {};
  for i=1,#knownVineNames do
    if not vinesUsed[knownVineNames[i].name]
      and not vineCustomsUsed[knownVineNames[i].image]
    then
      vineNames[#vineNames + 1] = knownVineNames[i].name;
      vineCustoms[#vineCustoms + 1] = knownVineNames[i].image;
    end
  end
  vineNames[#vineNames + 1] = "Other";
  local otherIndex = #vineNames;
  local addIndex = 1;

  local done = false;
  while not done do
    lsPrint(10, 10, 0, 0.9, 0.9, 0xffffffff, "Adding New Vine");
    done = lsButtonText(10, lsScreenY - 30, 0, 80, 0xffffffff, "Next");
    local cancel = lsButtonText(100, lsScreenY - 30, 0, 80, 0xffffffff, "Cancel");
    if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFF0000ff,"End Script") then
      error(quit_message);
    end

    lsSetCamera(0,0,lsScreenX*1.2,lsScreenY*1.2);
    addIndex = lsDropdown("VineAddIndex", 30, 50, 0, 250, addIndex,
			  vineNames);
    lsSetCamera(0,0,lsScreenX*1.0,lsScreenY*1.0);

    local vineName, vineCustom;
    if addIndex == otherIndex then
      local foo;
      lsPrint(10, 80, 0, 0.7, 0.7, 0xd0d0d0ff, "Title Name (Displayed in menus):");
      lsSetCamera(0,0,lsScreenX*1.2,lsScreenY*1.2);
      foo, vineName = lsEditBox("aVineName", 30, 125, 0, 250, 30, 1.0, 1.0,
				0x000000ff, "Custom");
      lsSetCamera(0,0,lsScreenX*1.0,lsScreenY*1.0);
      lsPrint(10, 155, 0, 0.7, 0.7, 0xd0d0d0ff, "Vine Cut Name:");
      lsSetCamera(0,0,lsScreenX*1.2,lsScreenY*1.2);
      foo, vineCustom = lsEditBox("avineCustom", 30, 210, 0, 250, 30, 1.0, 1.0,
				 0x000000ff);
      lsSetCamera(0,0,lsScreenX*1.0,lsScreenY*1.0);
      lsPrint(10, 225, 0, 0.6, 0.6, 0xd0d0d0ff, "Vine Cut Name is case sensitive!");
      lsPrint(10, 240, 0, 0.6, 0.6, 0xd0d0d0ff, "ie \"Pascarella Hexkin 6K\" - enter exactly.");
      lsPrint(10, 255, 0, 0.6, 0.6, 0xd0d0d0ff, "Above \"Text\" searched in vineyard windows.");
      lsPrint(10, 270, 0, 0.6, 0.6, 0xd0d0d0ff, "OR enter path/filename, ie vineyard/Custom.png");
    else
      vineName = vineNames[addIndex];
      vineCustom = vineCustoms[addIndex];
    end

    if vinesUsed[vineName] then
      done = false;
      lsPrint(30, 135, 10, 0.7, 0.7, 0xFF2020ff, "Title Name In Use");
    elseif vineCustomsUsed[vineCustom] then
      done = false;
      lsPrint(30, 205, 10, 0.7, 0.7, 0xFF2020ff, "Vine Cut Name In Use");
    elseif string.match(vineCustom, ".png$") then
      local status, error = pcall(srImageSize, vineCustom);
        if not status then
          done = false;
          lsPrint(30, 205, 10, 0.7, 0.7, 0xFF2020ff, "Image Not Found");
        end
    end

    checkBreak();
    lsSleep(tick_delay);
    lsDoFrame();

    if done then
      vines[#vines + 1] = {
      name = vineName,
      image = vineCustom,
      tends = {1, 1, 1, 1, 1, 1, 1},
      vigors = {1, 1, 1, 1, 1, 1, 1}
      };
      vinesUsed[vineName] = vines[#vines];
      vineCustomsUsed[vineCustom] = vines[#vines];
      promptEdit(vines[#vines]);
    elseif cancel then
      done = true;
    end
    lsSleep(tick_delay);
  end
end

function promptEdit(vine)
  local done = false;
  while not done do
    lsPrint(10, 10, 0, 1.0, 1.0, 0xffffffff, "Editing " .. vine.name);
    lsPrint(74, 60, 0, 0.7, 0.7, 0xd0d0d0ff, "Action");
    lsPrint(139, 60, 0, 0.7, 0.7, 0xd0d0d0ff, "Vigor");
    local y = 100;
    for i=1,#stateNames do
      lsSetCamera(0,0,lsScreenX*1.2,lsScreenY*1.2);
      lsPrint(10, y, 0, 0.7, 0.7, 0xd0d0d0ff, stateNames[i] .. ":");
      local tendIndex = tendIndices[vine.tends[i]];
      local tend  = lsDropdown(stateNames[i] .. "T" .. "-" .. vine.name,
			       85, y, 0, 60, tendIndex, tendActions);
      vine.tends[i] = tendActions[tend];
      vine.vigors[i] = lsDropdown(stateNames[i] .. "V" .. "-" .. vine.name,
				  160, y, 0, 60, vine.vigors[i], vigorNames);
      lsSetCamera(0,0,lsScreenX*1.0,lsScreenY*1.0);
      y = y + 30;
    end
    done = lsButtonText(10, lsScreenY - 30, 0, 80, 0xffffffff, "Save");
    local cancel = lsButtonText(100, lsScreenY - 30, 0, 80, 0xffffffff, "Cancel");
    if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFF0000ff,"End Script") then
      error(quit_message);
    end

    checkBreak();
    lsSleep(tick_delay);
    lsDoFrame();
    if done then
      saveVines();
    elseif cancel then
      parseVines();
      done = true;
    end
    lsSleep(tick_delay);
  end
end

function processVineyard()
  srReadScreen();
  harvestFlag = 0

  local window = srFindImage("vineyard/CanBeTended.png" );
  if not window then
    return "Vineyard is not ready for tending";
  end

  srReadScreen();
  local vigorText = findText("Vigor")
  if vigorText == nil then
    return "Did not find 'Vigor' text";
  end
  local vigor = string.match(vigorText[2], "Vigor: ([-0-9]+)");
  if not vigor then
    return "Could not read Vigor";
  end

  srReadScreen();
  vineType = getVineName()
  if not vineType then
    return "Could not identify this vine type";
  end

  local vineState = findVineState();
  if vineState == 0 then
    return "Could not determine vine state";
  end

  if tonumber(vigor) <= tonumber(vineType.vigors[vineState]) then
    sleepWithStatus(1500, "This vine does not have enough vigor. Time to harvest.");
    if alsoHarvest then
      harvestFlag = 2;
    end
    return "This vine does not have enough vigor. Time to harvest.";
  end

  harvestFlag = 0

  local clickPos = srFindImage(tendImages[vineType.tends[vineState]]);
  if not clickPos then
    return "Could not find tend action to click";
  end
  safeClick(clickPos[0], clickPos[1]);
  sleepWithStatus(200, "Tending vineyard");
  return statusSuccess(vineType);
end

function findVine(vineName)
  if findText(vineName) then
    return findText(vineName);
  end
end

function getVineName()
  for i=1,#vines do
    if findVine(vines[i].name) then
      local thisVine = vines[i];
      return thisVine;
    end
  end
end

function statusSuccess(vine)
  srReadScreen();
  tendedCount = tendedCount + 1;
  local result = "Tend Count: (" .. tendedCount .. ") \nTended: " .. vine.name .. "\n \n";
  result = result .. statusNumber("Acid:");
  result = result .. statusNumber("Color:");
  result = result .. statusNumber("Grapes:");
  result = result .. statusNumber("Quality:");
  result = result .. statusNumber("Skin:");
  result = result .. statusNumber("Sugar:");
  result = result .. statusNumber("Vigor:");
  return result;
end

function statusNumber(name,endCharacter,suppressName)
  local result = "";
  local anchor = findText(name);
  if not endCharacter then
    endCharacter = "\n";
  end
  if anchor then
    local number = string.match(anchor[2], name .. " ([-0-9]+)");
    if number then
  if not suppressName then
      result = name .. ": " .. number .. endCharacter;
	else
      result = number .. endCharacter;
	end
	end
  end
  return result;
end

function findVineState()
  local result = 0;
  srReadScreen();
  for i=1,#vineStates do
    if srFindImage(vineStates[i]) then
      result = i;
      break;
    end
  end
  return result;
end

function parseVines()
  vines = {};
  vinesUsed = {};
  vineCustomsUsed = {};
  local file = io.open("vines.txt", "a+");
  io.close(file);
  for line in io.lines("vines.txt") do
    -- local fields = csplit(line, ",");
    local fields = explode(",", line);
    if #fields == 9 then
      vines[#vines + 1] = {
	name = fields[1],
	image = fields[2],
	tends = {},
	vigors = {}
      };
      vinesUsed[fields[1]] = vines[#vines];
      vineCustomsUsed[fields[2]] = vines[#vines];

      for i=3,#fields do
	-- local sub = csplit(fields[i], "-");
        local sub = explode("-", fields[i]);
	if #sub ~= 2 then
	  error("Failed parsing line: " .. line);
	end
	if not tendImages[sub[1]] then
	  error("Failed parsing line: " .. line);
	end
	vines[#vines].tends[i-2] = sub[1];
	local vigor = tonumber(sub[2])
	if not vigor then
	  error("Failed parsing line: " .. line);
	end
	vines[#vines].vigors[i-2] = vigor;
      end
    end
  end
end

function saveVines()
  local file = io.open("vines.txt", "w+");
  for i=1,#vines do
    file:write(vines[i].name .. "," .. vines[i].image);
    for j=1,#vines[i].tends do
      file:write("," .. vines[i].tends[j] .. "-" .. vines[i].vigors[j]);
    end
    file:write("\n");
  end
  io.close(file);
end

-- Added in an explode function (delimiter, string) to deal with broken csplit.
function explode(d,p)
   local t, ll
   t={}
   ll=0
   if(#p == 1) then
      return {p}
   end
   while true do
      l = string.find(p, d, ll, true) -- find the next d in the string
      if l ~= nil then -- if "not not" found then..
         table.insert(t, string.sub(p,ll,l-1)) -- Save it in our array.
         ll = l + 1 -- save just after where we found it for searching next time.
      else
         table.insert(t, string.sub(p,ll)) -- Save what's left in our array.
         break -- Break at end, as it should be, according to the lua manual.
      end
   end
   return t
end

function statusScreen(message, color, allow_break, scale)
  if not message then
    message = "";
  end
  if not color then
    color = 0xFFFFFFff;
  end
  if allow_break == nil then
    allow_break = true;
  end
  if not scale then
    scale = 0.8;
  end
  lsPrintWrapped(10, 80, 0, lsScreenX - 20, scale, scale, color, message);
  lsPrintWrapped(10, lsScreenY-100, 0, lsScreenX - 20, scale, scale, 0xffd0d0ff,
                 error_status);
  if lsButtonText(lsScreenX - 110, lsScreenY - 30, nil, 100, 0xFF0000ff, "End Script") then
    error(quit_message);
  end
  if allow_break then
    lsPrint(10, 10, 0, 0.7, 0.7, 0xB0B0B0ff,
            "Hold Ctrl+Shift to end this script.");
    if allow_pause then
      lsPrint(10, 24, 0, 0.7, 0.7, 0xB0B0B0ff,
              "Hold Alt+Shift to pause this script.");
    end
    checkBreak();
  end
  lsSleep(tick_delay);
  lsDoFrame();
end
