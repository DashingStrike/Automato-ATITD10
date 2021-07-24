dofile("common.inc");

local bases = {};
local additive;
local unique = math.random();

function displayOptions()
  while true do
    checkBreak();

    lsPrint(5, 5, z, 1, 1, 0xFFFFFFff, "Base 1:");
    _, bases[1] = lsEditBox(unique .. "base1", 100, 5, z, lsScreenX - 105, 0, 1.0, 1.0, 0x000000ff, bases[1]);
    lsPrint(5, 35, z, 1, 1, 0xFFFFFFff, "Base 2:");
    _, bases[2] = lsEditBox(unique .. "base2", 100, 35, z, lsScreenX - 105, 0, 1.0, 1.0, 0x000000ff, bases[2]);
    lsPrint(5, 65, z, 1, 1, 0xFFFFFFff, "Base 3:");
    _, bases[3] = lsEditBox(unique .. "base3", 100, 65, z, lsScreenX - 105, 0, 1.0, 1.0, 0x000000ff, bases[3]);

    lsPrint(5, 125, z, 1, 1, 0xFFFFFFff, "Additive:");
    _, additive = lsEditBox(unique .. "additive", 100, 125, z, lsScreenX - 105, 0, 1.0, 1.0, 0x000000ff, additive);

    if lsButtonText(5, lsScreenY - 30, z, 90, 0x00FF00ff, "Cook") then
      return;
    end
    if lsButtonText(lsScreenX / 2 - 45, lsScreenY - 30, z, 90, 0xFFFF00ff, "Clear") then
      bases = {};
      additive = nil;
      unique = math.random();
    end
    if lsButtonText(lsScreenX - 95, lsScreenY - 30, z, 90, 0xFFFFFFff, "Quit") then
      error("Quit");
    end

    lsDoFrame();
    lsSleep(10);
  end
end

function getKitchens()
  local kitchens = {};
  while #kitchens ~= 4 do
    srReadScreen();
    kitchens = findAllText("Kitchen", nil, REGION);
    if #kitchens ~= 4 then
      if not promptOkay("Please pin open exactly 4 kitchens.") then
        error("Quit");
      end
    end
  end

  return kitchens;
end

function addIngredient(kitchen, ingredient, count)
  waitAndClickText("Mix...", kitchen);
  waitAndClickText(ingredient);
  if not waitForImage("ok2.png", 60000, "Waiting for ok button") then
    error("No ok button");
  end
  lsSleep(100);
  srKeyEvent(tostring(count));
  lsSleep(100);
  waitAndClickImage("ok2.png");
  lsSleep(1000);
end

function getMealName(i)
  if i <= 3 then
    return bases[i] .. ":" .. additive .. " at 6:1";
  else
    return bases[1] .. ":" .. additive .. " at 13:1";
  end
end

function cook()
  local kitchens = getKitchens();

  for i = 1, 3 do
    addIngredient(kitchens[i], bases[i], 6);
  end

  addIngredient(kitchens[4], bases[1], 13);

  for i = 1, 4 do
    addIngredient(kitchens[i], additive, 1);
  end

  lsSleep(1000);

  for i = 1, 4 do
    waitAndClickText("Kitchen", kitchens[i]);
    waitAndClickText("Cook", kitchens[i]);
    if not waitForImage("ok2.png", 60000, "Waiting for ok") then
      error("No ok button");
    end

    lsSleep(1000);
    srKeyEvent(getMealName(i));
    lsSleep(100);
    waitAndClickImage("ok2.png");
  end

  for i = 1, 4 do
    waitAndClickText("Kitchen", kitchens[i]);
    waitAndClickText("Critically", kitchens[i]);
    if not waitForImage("ok.png", 60000, "Waiting for ok") then
      error("No ok button");
    end

    promptOkay("Record the pair times for " .. getMealName(i));

    srReadScreen();
    local ok = findImage("ok.png");
    if ok then
      clickText(ok);
    end

    waitAndClickText("Clean", kitchens[i]);
    waitAndClickImage("yes.png");
    waitAndClickText("Kitchen", kitchens[i]);
  end
end

function doit()
  askForWindow([[
Kooking by Kavad

This macro helps with cooking research.

It will run a test of 3 bases against an additive.

It will cook a 6:1 dish for each,
and a single 13:1, all at the same time.

Hover over the ATITD window and press shift.
]]);

  while true do
    checkBreak();

    displayOptions();
    cook();
  end
end
