-- Wood gathering v1.0 by Manon & Cegaiel for T9 Beta
--

dofile("common.inc");

function doit()
    askForWindow("Pin 5-10 tree windows, will click them VERTICALLY (left to right if there is a tie - multiple columns are fine). \n\nOptionally, pin a Bonfire window for stashing wood. \n\nIf the trees are part of an oasis, you only need to pin 1 of the trees.");
    while 1 do
        checkBreak();
        refreshWindows();
        findWood();
        refreshWindows();
        --bonfire();
        --refreshWindows();
      --  sleepWithStatus(5000, "Searching\n\nPinned Trees found: " .. #nowood .. "\nBonfire found: ".. (#Bonfire > 0 and 'Yes' or 'No') );
        sleepWithStatus(5000, "Searching\n\nPinned Trees found: " .. #nowood);
    end
end

function refreshWindows()
    srReadScreen();
    this = findAllImages("wood/This.png");
    --Bonfire = findAllText("Bonfire");
    for i=1,#this do
      safeClick(this[i][0], this[i][1])
    end
    lsSleep(500);
end

function findWood()
    srReadScreen();
    clickWood = findAllImages("wood/gather_wood.png");
    nowood = findAllImages("wood/no_wood.png")
    for i=1,#clickWood do
      safeClick(clickWood[i][0], clickWood[i][1])
    end
end

--[[
function bonfire()
    srReadScreen();
    BonfireAdd = findAllText("Add some Wood");
    for i=1,#BonfireAdd do
        safeClick(BonfireAdd[i][0]+10, BonfireAdd[i][1]+10);
        lsSleep(500);
        srReadScreen();
        max = srFindImage("max.png");
        if max then
            safeClick(max[0]+5,max[1]+5,1);
        else
            sleepWithStatus(500, "Could not add wood to the bonfire");
        end
    end
end
]]--
