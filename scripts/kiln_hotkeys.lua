-- Pottery_Wheel.lua v1.0 -- by Darkfyre. Credits to Cegaiel for the base code taken from apiary.lua, time_left code from wood.lua, and elements of the mining_ore.lua
--
 
dofile("common.inc");
dofile("settings.inc");

 
askText = "Allows you to quickly set all of your kiln locations by tapping the selected key over each one. Then run and it will make jugs on all marked kilns.\n \nIf you want to make claypots: \nSet the hotkey to P.\n \nMake sure CHAT IS MINIMIZED!\n \nPress Shift over ATITD window to continue.";
productNames = { "Wet Clay Bricks", "Wet Clay Mortars", "Wet Firebricks", "Wet Jugs", "Wet Claypots" };
productKey = "J";
total_delay_time = 142000; -- 2 minutes 22 seconds = 5 second buffer
dropdown_values = {"Shift Key", "Ctrl Key", "Alt Key", "Mouse Wheel Click"};
dropdown_cur_value = 1;
 
function getPoints()
clickList = {};
  local was_shifted = lsShiftHeld();
 
  if (dropdown_cur_value == 1) then
  was_shifted = lsShiftHeld();
  key = "tap Shift";
  elseif (dropdown_cur_value == 2) then
  was_shifted = lsControlHeld();
  key = "tap Ctrl";
  elseif (dropdown_cur_value == 3) then
  was_shifted = lsAltHeld();
  key = "tap Alt";
  elseif (dropdown_cur_value == 4) then
  was_shifted = lsMouseIsDown(2); --Button 3, which is middle mouse or mouse wheel
  key = "click MWheel ";
  end
 
  local is_done = false;
  local mx = 0;
  local my = 0;
  local z = 0;
  while not is_done do
    mx, my = srMousePos();
    local is_shifted = lsShiftHeld();
 
    if (dropdown_cur_value == 1) then
      is_shifted = lsShiftHeld();
    elseif (dropdown_cur_value == 2) then
      is_shifted = lsControlHeld();
    elseif (dropdown_cur_value == 3) then
      is_shifted = lsAltHeld();
    elseif (dropdown_cur_value == 4) then
      is_shifted = lsMouseIsDown(2); --Button 3, which is middle mouse or mouse wheel
    end
 
    if is_shifted and not was_shifted then
      clickList[#clickList + 1] = {mx, my};
    end
    was_shifted = is_shifted;
    checkBreak();
    lsPrint(10, 10, z, 0.7, 0.7, 0xFFFFFFff,
      "Set Pottery Wheel Locations (" .. #clickList .. ")");
    local y = 60;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Select camera and zoom level");
    y = y + 20
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "that best fits the pottery wheels in screen.")
    y = y + 20
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Suggest: F8F8 view.")
    y = y + 20
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Lock ATITD screen with Alt+L")
    y = y + 40;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "MAKE SURE CHAT IS MINIMIZED!")
    y = y + 40;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "1) Set all True Kiln locations:");
    y = y + 20;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Hover mouse, " .. key .. " over each")
    y = y + 20;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "True Kiln.")
    y = y + 30;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "2) After setting all True Kiln locations:")
    y = y + 20;
    lsPrint(5, y, z, 0.6, 0.6, 0xf0f0f0ff, "Click Start to begin checking True Kilns.")
 
    if #clickList >= 1 then -- Only show start button if one or more kiln was selected.
      if lsButtonText(10, lsScreenY - 30, z, 100, 0xFFFFFFff, "Start") then
        is_done = 1;
      end
    end
 
    if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff,
                    "End script") then
      error "Clicked End Script button";
    end
 
    lsDoFrame();
    lsSleep(50);
  end
end
 
function config()
  scale = 0.8;
  local z = 0;
  local is_done = nil;
  while not is_done do
    local y = 7;

    checkBreak("disallow pause");

    lsPrintWrapped(10, y, z+10, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
        "Global Settings\n-------------------------------------------");
    y = y + 35;

    kilnPasses = readSetting("kilnPasses",tonumber(kilnPasses));
    lsPrint(15, y, z, scale, scale, 0xffffffff, "Passes :");
    is_done, kilnPasses = lsEditBox("kilnPasses", 110, y-2, z, 50, 30, scale, scale,
                               0x000000ff, kilnPasses);
    if not tonumber(kilnPasses) then
      is_done = false;
      lsPrint(10, y+30, z+10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
      kilnPasses = 1;
    end
    writeSetting("kilnPasses",tonumber(kilnPasses));
    y = y + 32;

    -- lsPrint(15, y, 0, scale, scale, 0xffffffff, "Kiln Type:");
    -- kiln = lsDropdown("kiln", 110, y-2, 0, 150, kiln, kilnList);
    -- y = y + 32;

    lsPrint(15, y, 0, scale, scale, 0xffffffff, "Product:");
    typeOfProduct = readSetting("typeOfProduct",typeOfProduct);
    typeOfProduct = lsDropdown("typeOfProduct", 110, y-2, 0, 150, typeOfProduct, productNames);
    writeSetting("typeOfProduct",typeOfProduct);
    y = y + 32;


    if lsButtonText(10, lsScreenY - 30, z, 100, 0x00ff00ff, "Begin") then
        is_done = 1;
    end

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFF0000ff,
        "End script") then
        error "Clicked End Script button";
    end
    lsDoFrame();
    lsSleep(100);
  end
end

function doit()
  askForWindow(askText);
  config();
  if typeOfProduct == 1 then productKey = "C"; end
  if typeOfProduct == 2 then productKey = "M"; end
  if typeOfProduct == 3 then productKey = "B"; end
  if typeOfProduct == 4 then productKey = "J"; end
  if typeOfProduct == 5 then productKey = "P"; end
  getPoints();
  clickSequence();
end
 
function findClosePopUp()
  lsSleep(150);
    while 1 do
      checkBreak();
      srReadScreen();
      OK = srFindImage("OK.png");
    if OK then  
      srClickMouseNoMove(OK[0]+2,OK[1]+2);
      lsSleep(100);
    else
      break;
    end
    end
end
 
 
function clickSequence()
 
  sleepWithStatus(1000, "Starting... Don\'t move mouse!");
  startTime = lsGetTimer();
  for l=1, kilnPasses do  
      for i=1,#clickList do
    checkBreak();
    srSetMousePos(clickList[i][1], clickList[i][2]);
    lsSleep(100); -- ~65+ delay needed before the mouse can actually move.
    TakeProducts(i);
    lsSleep(32);
    RepairKiln();
    lsSleep(32);
    AddWood();
    lsSleep(32);
    AddProduct();
    lsSleep(32);
    FireKiln();
    lsSleep(100);
    count = i;
      end
    local time_left = total_delay_time - #clickList * 100;
  sleepWithStatus(time_left,"Pass " .. l .. " of " .. kilnPasses .. "\nWaiting for kilns to finish");
  end
 
    for i=1,#clickList do
      checkBreak();
      srSetMousePos(clickList[i][1], clickList[i][2]);
      lsSleep(100); -- ~65+ delay needed before the mouse can actually move.
      TakeProducts(i);
      count = i;
    end
 
  lsPlaySound("Complete.wav");
  lsMessageBox("Elapsed Time:", getElapsedTime(startTime), 1);
end
 
 
function FireKiln()
  checkBreak();
  findClosePopUp(); -- Screen clean up
  checkCloseWindows(); -- Screen clean up
  local OK = true;
  srKeyEvent('f'); -- Make Jug [J]
  sleepWithStatus(100,"Firing kiln");
  findClosePopUp(); -- Screen clean up
  checkCloseWindows(); -- Screen clean up
end
 
function RepairKiln()
  checkBreak();
  findClosePopUp(); -- Screen clean up
  checkCloseWindows(); -- Screen clean up
  local OK = true;
  srKeyEvent('r'); -- Make Jug [J]
  findClosePopUp(); -- Screen clean up
  checkCloseWindows(); -- Screen clean up
end
 
function AddWood()
  checkBreak();
  findClosePopUp(); -- Screen clean up
  checkCloseWindows(); -- Screen clean up
  local OK = true;
  srKeyEvent('w'); -- Make Jug [J]
  findClosePopUp(); -- Screen clean up
  checkCloseWindows(); -- Screen clean up
end
 
function AddProduct()
  checkBreak();
  findClosePopUp(); -- Screen clean up
  checkCloseWindows(); -- Screen clean up
  local OK = true;
  srKeyEvent(productKey); -- Make Product
  findClosePopUp(); -- Screen clean up
  checkCloseWindows(); -- Screen clean up
end
 
function TakeProducts()
  checkBreak();
  findClosePopUp(); -- Screen clean up
  checkCloseWindows(); -- Screen clean up
  local OK = true;
  srKeyEvent('t'); -- Take Everything [T]
end
 
function checkCloseWindows()
-- Rare situations a click can cause a window to appear for a pottery wheel, blocking the view to other pottery wheels.
-- This is a safeguard to keep random windows that could appear, from remaining on screen and blocking the view of other pottery wheels from being selected.
  srReadScreen();
  local closeWindows = findAllImages("thisis.png");

    if #closeWindows > 0 then
    for i=#closeWindows, 1, -1 do
      -- 2 right clicks in a row to close window (1st click pins it, 2nd unpins it
      g(closeWindows[i][0]+5, closeWindows[i][1]+10, true);
      lsSleep(100);
      g(closeWindows[i][0]+5, closeWindows[i][1]+10, true);
    end
    lsSleep(clickDelay);
    end
end