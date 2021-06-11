dofile("common.inc");
dofile("settings.inc");

kilnList = {"True Kiln"};
kilnImage = { "trueKiln.png" };
productNames = { "Wet Clay Bricks", "Wet Clay Mortars", "Wet Firebricks", "Wet Jugs", "Wet Claypots" };
productImages = { "loadClayBricks.png", "loadClayMortars.png", "loadFirebricks.png", "loadJugs.png", "loadClaypot.png" };
arrangeWindows = true;

-- Tweakable delay values
refresh_time = 250 -- Time to wait for windows to update

askText = "Pin up windows manually or use the Arrange Windows option to pin/arrange windows.";

function doit()
  askForWindow(askText);
  config();
  sleepWithStatus(1200, "Preparing to Start ...\n\nHands off the mouse!");
    if(arrangeWindows) then
      arrangeInGrid(nil, nil, 490, 200, false, 25, 50);
    end
  unpinOnExit(start);
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

    lsPrint(15, y, 0, scale, scale, 0xffffffff, "Kiln Type:");
    kiln = lsDropdown("kiln", 110, y-2, 0, 150, kiln, kilnList);
    y = y + 32;

    lsPrint(15, y, 0, scale, scale, 0xffffffff, "Product:");
    typeOfProduct = readSetting("typeOfProduct",typeOfProduct);
    typeOfProduct = lsDropdown("typeOfProduct", 110, y-2, 0, 150, typeOfProduct, productNames);
    writeSetting("typeOfProduct",typeOfProduct);
    y = y + 32;

    arrangeWindows = readSetting("arrangeWindows",arrangeWindows);
    arrangeWindows = CheckBox(15, y, z+10, 0xFFFFFFff, "Arrange windows (Grid format)", arrangeWindows, 0.65, 0.65);
    writeSetting("arrangeWindows",arrangeWindows);
    y = y + 28;

    if lsButtonText(10, lsScreenY - 30, z, 100, 0x00ff00ff, "Begin") then
        is_done = 1;
    end

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFF0000ff,
        "End script") then
        error "Clicked End Script button";
    end
    lsDoFrame();
    lsSleep(shortWait);
  end
end

function start()
  takeFromKilns();

    for i=1, kilnPasses do
      refreshWindows();
      checkRepair();
      srReadScreen();


      clickAllImages("kilns/loadWood.png");
      lsSleep(refresh_time);
    	clickAllImages("kilns/" .. productImages[typeOfProduct]);
    	print("clicking: " .. productImages[typeOfProduct]);
      lsSleep(refresh_time)
      clickAllImages("kilns/fireKiln.png");
      lsSleep(refresh_time)
      --Check Repair for any that failed this round then fire any that were broken.
      checkRepair();
      lsSleep(refresh_time)
      clickAllImages("kilns/fireKiln.png");
      lsSleep(refresh_time)

      closePopUp();
      checkFiring();
      refreshWindows();
      takeFromKilns();
    end
  lsPlaySound("Complete.wav");
end

function takeFromKilns()
  srReadScreen();
  kilnRegions = findAllImages("kilns/" .. kilnImage[kiln]);
  for i = 1, #kilnRegions do
    checkBreak();
    local x = kilnRegions[i][0]-165;
    local y = kilnRegions[i][1];
    local width = 491;
    local height = 216;
    local p = srFindImageInRange("take.png", x, y, width, height);
      if (p) then
  		safeClick(p[0]+4,p[1]+4);
  		lsSleep(refresh_time);
  		srReadScreen();
  		local e = srFindImage("everything.png");
      		if (e) then
      			safeClick(e[0]+4,e[1]+4);
      			lsSleep(refresh_time);
      			safeClick(kilnRegions[i][0]+4, kilnRegions[i][1]+4);
      			lsSleep(refresh_time);
      	 end
  	   end
   end
end

function refreshWindows()
  srReadScreen();
  this = findAllImages("kilns/" .. kilnImage[kiln]);
    for i = 1, #this do
      safeClick(this[i][0]+4,this[i][1]+4);
    end
  lsSleep(refresh_time);
end

function checkRepair()
  lsSleep(refresh_time);
  closePopUp();
  srReadScreen();
  clickAllImages("kilns/repairKiln.png");
  lsSleep(refresh_time);
end

function checkFiring()
  while 1 do
    refreshWindows();
    srReadScreen();
    firing = findAllImages("kilns/isFiring.png");;
    if #firing == 0 then
        break; --We break this while statement because Making is not detect, hence we're done with this round
    end
    sleepWithStatus(999, "Waiting for " .. productNames[typeOfProduct] .. " to finish", nil, 0.7);
  end
end

function closePopUp()
  while 1 do
    srReadScreen()
    local outofresource = srFindImage("YouDont.png");
    local ok = srFindImage("OK.png");
      if ok then
          statusScreen("Found and Closing Popups ...", nil, 0.7);
          safeClick(ok[0]+2,ok[1]+2);
          lsSleep(100);
            if outofresource then
               error("Out of resources");
            end
      else
          break;
      end
  end
end
