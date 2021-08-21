



dofile("common.inc");
dofile("settings.inc");

perls = {};
solutions = {};
solved = false;

xyWindowSize = {};

colorNames     = {"Aqua",      "Beige",     "Black",     "Coral",     "Pink",      "Smoke",     "White"};
colorValues    = {0x00FFFFff,  0xF5F5DCff,  0x000000ff,  0xFF7F50ff,  0xFFC0CBff,  0x738276ff,  0xF0F0F0ff};
sizeNames      = {"Small",     "Medium",    "Large",     "Huge"};

smallNecklace  = 1
mediumNecklace = 2
largeNecklace  = 3
hugeNecklace   = 4
sizeCount      = 4;
smallLength    = 7;
mediumLength   = 4;
largeLength    = 2;
hugeLength     = 1;

tableImageXOffset = 10;
tableImageYOffset = 10;
tableColOffset    = 79;
tableRowOffset    = 90;
tableWidth        = 257;
tableHeight       = 443;
tableSlotSize     = 25;

statusXOffset = 2;
statusYOffset = 2;
statusScale = 0.9;

resetXOffset = 5;
resetYOffset = 5;

slotStatus =     {[0] = "-", "o", "X", "?"};
necklace = {
               {
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0}
               },
               {
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0}
               },
               {
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0}
               },
               {
                   {0, 0, 0, 0, 0, 0, 0}
               }
           };

function clearTable()
    necklace = {
               {
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0}
               },
               {
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0}
               },
               {
                   {0, 0, 0, 0, 0, 0, 0},
                   {0, 0, 0, 0, 0, 0, 0}
               },
               {
                   {0, 0, 0, 0, 0, 0, 0}
               }
           };
    saveNecklace();
end

necklaceFileName = "necklace.txt";

function saveNecklace()
    serialize(necklace, necklaceFileName);
    loadNecklace();
end
function loadNecklace()
    local success = false;
    if (pcall(dofile, necklaceFileName)) then
        success, necklace = deserialize(necklaceFileName);
    end
    
    return success;
end


function doit()
  askForWindow("Press shift over ATiTD window.");
  xyWindowSize = srGetWindowSize();
  if not loadNecklace() then saveNecklace(); end;
  while 1 do
    doSolver(getBedSize());
  end
  
end


function getBedSize()

  local button_selected = nil;
  local is_done = nil;
  
  while not is_done do

    checkBreak();

    local bsize = 250;
    local x = 25;
    local y = 10;
    local bed_size = 0;

    local button_names = {"5x5 One Color", "6x6 One Color", "7x7 Two Colors",
                          "8x8 Three Colors", "My Necklace Table" };

    for i=1, #button_names do

      if lsButtonText(x, y, 0, bsize, 0x5555AAff, button_names[i]) then

        button_selected = i;
	is_done = 1;

      end

      y = y + 30;

    end

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100,
                    0xFFFFFFff, "End Script") then

      error("User exited.");

    end

    lsDoFrame();
    lsSleep(10);

  end

  bed_size = 4 + button_selected;
  if bed_size > 8 then bed_size = 0; end;

  return bed_size;

end



function doSolver(bedSize)

  solutionDiving = true;

  perls = {};
  
  local maxPerlColors = 1;

  if bedSize == 7 then maxPerlColors = 2; end;
  if bedSize == 8 then maxPerlColors = 3; end;

  imgcount = maxPerlColors + 1;
  colcount = bedSize;
  rowcount = bedSize;

  local startX = 10;
  local startY = 20;

  local perlWHSize = 26;
  local perlGap = 2;

  local solXOffset = 7;
  local solYOffset = 2;
  local solScale = 1;
  local solColor = 0xFF0000ff;

  local solShadowXOffset = 1;
  local solShadowYOffset = 1;
  local solShadowScale = 1;
  local solShadowColor = 0x000000ee;
  local error = false;
  local solved = false;
  local detected = false;
  local topLeftGridPos = {[0] = 0, 0};
  local gapDistance = 0;
  local gotoPosFromCenter = {[0] = 0, 0};
  while true do

    checkBreak();

    local z = 0;

    
    if solutions then
      --lsPrintln("solutions: " .. inspectit.inspect(solutions));
    end
    if bedSize ~= 0 then
      local baseSize = (bedSize * (perlWHSize + perlGap)) + perlGap;

      lsDisplaySystemSprite(1, startX + perlGap, startY + perlGap, z,
                            baseSize, baseSize, 0x9A9A9Aff);

      local mouseClick = lsMouseClick(startX + (perlGap * 2), startY + (perlGap * 2), baseSize + (perlGap * 2), baseSize + (perlGap * 2), 1);

    z = z + 1;
      for w = 1, bedSize do
        for h = 1, bedSize do

          local x = 0;
          local y = 0;

          local perlColor = 0x000000ff;

          if not perls[w] then perls[w] = {}; solutions[w] = {}; end;
          if not perls[w][h] then perls[w][h] = 0; solutions[w][h] = 0; end;


          x = (startX + perlGap + (w * (perlWHSize + perlGap))) - perlWHSize;
          y = (startY + perlGap + (h * (perlWHSize + perlGap))) - perlWHSize;


          if mouseClick and 
             mouseClick[0] >= x and mouseClick[1] >= y and
             mouseClick[0] <= perlWHSize + x and mouseClick[1] <= perlWHSize + y
          then
            if not solved then
              perls[w][h] = perls[w][h] + 1;
              if perls[w][h] > maxPerlColors then perls[w][h] = 0; end;
            elseif not error and solved then
              if solutionDiving then
                safeClick(xyWindowSize[0]*.5+100, xyWindowSize[1]*.5+100, 1);
              end
              if bedSize ~= 5 then
                 perls[w][h] = perls[w][h] + 1;
                 if perls[w][h] > maxPerlColors then perls[w][h] = 0; end;
              end;
              if w > 1 then
                perls[w-1][h] = perls[w-1][h] + 1;
                if perls[w-1][h] > maxPerlColors then perls[w-1][h] = 0; end;
              end
              if h > 1 then
                perls[w][h-1] = perls[w][h-1] + 1;
                if perls[w][h-1] > maxPerlColors then perls[w][h-1] = 0; end;
              end
              if w < bedSize then
                perls[w+1][h] = perls[w+1][h] + 1;
                if perls[w+1][h] > maxPerlColors then perls[w+1][h] = 0; end;
              end
              if h < bedSize then
                perls[w][h+1] = perls[w][h+1] + 1;
                if perls[w][h+1] > maxPerlColors then perls[w][h+1] = 0; end;
              end
              solutions[w][h] = solutions[w][h] - 1;
              if solutions[w][h] < 0 then solutions[w][h] = maxPerlColors; end;
            end

          end

          lsDisplaySystemSprite(1, x, y, z, perlWHSize, perlWHSize, 0x000000ff);

          if     perls[w][h] == 1 then perlColor = 0x0000FFee;
          elseif perls[w][h] == 2 then perlColor = 0x00FF00ee;
          elseif perls[w][h] == 3 then perlColor = 0xFFD0D0ee;
          end

          lsDrawCircle(x + (perlWHSize * .5), y + (perlWHSize * .5), z + 1, (perlWHSize * .33), .5, perlColor)

          if solutions[w][h] ~= 0 then
            lsPrint(x + solXOffset + solShadowXOffset, y + solYOffset + solShadowYOffset, z+2, solShadowScale, solShadowScale, solShadowColor, "" .. solutions[w][h]);
            lsPrint(x + solXOffset, y + solYOffset, z+3, solScale, solScale, solColor, "" .. solutions[w][h]);
          end

        end
      end

      z = z + 3;

      local solveColor = 0xFFFFFFff;
      local solveText = "Solve";
      if error then
        solveText = "Error";
        solveColor = 0xFF0000ff;
      elseif solved then
        solveText = "Unsolve";
        solveColor = 0x0000FFff;
      end
      if lsButtonText(startX + perlGap, startY + baseSize + (perlGap * 2) + 10, z, 75,
                      solveColor, solveText) then
        if not solved then
          error = (not solve());
          solved = true;
        else
          for w = 1, bedSize do
            solutions[w] = {};
            for h = 1, bedSize do
              solutions[w][h] = 0;
            end
          end
          error = false;
          solved = false;
        end
      end

      if lsButtonText(startX - perlGap + baseSize + (perlGap * 2) - 65, startY + baseSize + (perlGap * 2) + 10, z, 65,
                      0xFFFFFFff, "Reset") then

        for w = 1, bedSize do
          perls[w] = {}; solutions[w] = {};
          for h = 1, bedSize do
            perls[w][h] = 0; solutions[w][h] = 0;
          end
        end
        error = false;
        solved = false;
      end

      
      if true then
        
        
        if lsButtonText(startX + perlGap, startY + baseSize + (perlGap * 2) + 10 + 30, z, 75,
                        0xFFFFFFff, "Detect") then
          for w = 1, bedSize do
            perls[w] = {}; solutions[w] = {};
            for h = 1, bedSize do
              perls[w][h] = 0; solutions[w][h] = 0;
            end
          end
          error = false;
          solved = false;

            local leftMostCluster = 0;
            local rightMostCluster = 0;
            local topMostCluster = 0;
            local bottomMostCluster = 0;

          
          clusters = {}
          for c = 1, maxPerlColors do
            if c == 1 then -- blue
              clusters[c] = lsAnalyzeCustom(15, 200, 0, xyWindowSize[1] * 0.9,  0xB1B1C0ff, 0xCECEFFff); 
            elseif c == 2 then -- green
              clusters[c] = lsAnalyzeCustom(15, 200, 0, xyWindowSize[1] * 0.9,  0x9EC27Eff, 0xC9F0B1ff); -- green
            else -- redish white :( the worst to detect
              clusters[c] = lsAnalyzeCustom(20, 200, 0, xyWindowSize[1] * 0.9,  0xC6C087ff, 0xFEEEF6ff); -- redish white
            end
          end
          
          if clusters then
            for c = 1, maxPerlColors do
              --lsPrintln("Color: " .. c .. "\n" ..inspectit.inspect(clusters[c]));
            end
            local clusterGrid = {};
            local gridPositions = {};
            for x = 1, bedSize do
              if not clusterGrid[x] then clusterGrid[x] = {}; end;
              if not gridPositions[x] then gridPositions[x] = {}; end;
              for y = 1, bedSize do
                clusterGrid[x][y] = 0;
                gridPositions[x][y] = {[0] = x, y};
              end
            end
            --lsPrintln("gridPositions: \n" .. inspectit.inspect(gridPositions));
            local minX = 99999;
            local maxX = 0;
            local minY = 99999;
            local maxY = 0;

            

            local leftMostColor = 1;
            local rightMostColor = 1;
            local topMostColor = 1;
            local bottomMostColor = 1;

            

            
            for c = 1, #clusters do
              --clusters[c][0] = {};
              
              for i = 1, #clusters[c] do
                minX = math.min(minX, clusters[c][i][0]);
                minY = math.min(minY, clusters[c][i][1]);
                maxX = math.max(maxX, clusters[c][i][0]);
                maxY = math.max(maxY, clusters[c][i][1]);
                clusters[c][0] = {[0] = 99999, 99999};
                if c ~= 3  and minX < clusters[leftMostColor][leftMostCluster][0] then
                  leftMostCluster = i;
                  leftMostColor = c;
                end
                if c ~= 3 and minY < clusters[topMostColor][topMostCluster][1] then
                  topMostCluster = i;
                  topMostColor = c;
                end
                clusters[c][0] = {[0] = 0, 0};
                if c ~= 3 and maxX > clusters[rightMostColor][rightMostCluster][0] then
                  rightMostCluster = i;
                  rightMostColor = c;
                end
                if c ~= 3 and maxY > clusters[bottomMostColor][bottomMostCluster][1] then
                  bottomMostCluster = i;
                  bottomMostColor = c;
                end
              end
              
              detected = true;
            end
            
            --lsPrintln("left="..leftMostCluster .. ", top=" .. topMostCluster .. 
            --          ", right=" .. rightMostCluster .. ", bottom=" .. bottomMostCluster);
            gridPositions[1][1] = {[0] = clusters[leftMostColor][leftMostCluster][0],
                                   clusters[topMostColor][topMostCluster][1]};
            topLeftGridPos = {[0] = clusters[leftMostColor][leftMostCluster][0],
                                   clusters[topMostColor][topMostCluster][1]};
            --lsPrintln("going to: " .. inspectit.inspect(topLeftGridPos));
            gridPositions[bedSize][bedSize] = {[0] = clusters[rightMostColor][rightMostCluster][0],
                                               clusters[bottomMostColor][bottomMostCluster][1]};
            
            local gridWidth = gridPositions[bedSize][bedSize][0] - gridPositions[1][1][0];
            local gridHeight = gridPositions[bedSize][bedSize][1] - gridPositions[1][1][1];
            local gridXGap = (gridWidth/(bedSize-1));
            local gridYGap = (gridHeight/(bedSize-1));
            gapDistance = 0;
            if gridXGap > gridYGap then
              gapDistance = ((gridXGap - gridYGap)*.5)+gridYGap;
            elseif gridYGap > gridXGap then
              gapDistance = ((gridYGap - gridXGap)*.5)+gridXGap;
            else
              gapDistance = gridXGap;
            end
            --lsPrintln("gapDistance = " .. gapDistance);

              for x = 1, bedSize do
                for y = 1, bedSize do
                  --if not (x == 1 and y == 1) and not (x == bedSize and y == bedSize) then 
                    gridPositions[x][y] = {[0] = math.floor(gridPositions[1][1][0] + (gapDistance * (x-1))+0.5), math.floor(gridPositions[1][1][1] + (gapDistance * (y-1))+0.5)};
                  --end
                end
              end

            --lsPrintln("clusers: \n" .. inspectit.inspect(clusters));
            --lsPrintln("gridPositions: \n" .. inspectit.inspect(gridPositions));
            for c = 1, #clusters do
              for x = 1, bedSize do
                for y = 1, bedSize do
                  for i = 1, #clusters[c] do
                    --perls[w][h]
                    if perls[x][y] < 2 and
                       clusters[c][i][0] < gridPositions[x][y][0] + 15 and
                       clusters[c][i][1] < gridPositions[x][y][1] + 15 and
                       clusters[c][i][0] > gridPositions[x][y][0] - 15 and
                       clusters[c][i][1] > gridPositions[x][y][1] - 15 then
                      perls[x][y] = c;
                    end
                  end
                end
              end
            end
          end
        end

        if detected and solved and lsButtonText(startX - perlGap + baseSize + (perlGap * 2) - 65, startY + baseSize + (perlGap * 2) + 10 + 30, z, 65,
                      0xFFFFFFff, "Autodive") then

          local x = 1;
          local y = 1;
          gotoPosFromCenter = {[0] = 0, 0};
          local rlToggle = false;
          gapDistance = math.floor(gapDistance+.5);
          --lsPrintln("gapDistance: " .. gapDistance .. " going to: " .. inspectit.inspect(topLeftGridPos));
          
          safeClick(topLeftGridPos[0], topLeftGridPos[1]);
          --srSetMousePos(topLeftGridPos[0], topLeftGridPos[1]);
          --srClickMouse(topLeftGridPos[0], topLeftGridPos[1]);
          
          sleepWithBreakCheck(7000);
          while y ~= bedSize+1  do
            while x ~= bedSize+1 and x ~= 0 do
              --lsPrintln("Top of while loops, x="..x.." y="..y);
              --
              if solutions[x][y] ~= 0 then
                --lsPrintln("perls="..solutions[x][y].." gotoPosFromCenter: " ..inspectit.inspect(gotoPosFromCenter));
                gotoPosFromCenter[0] = gotoPosFromCenter[0]+(xyWindowSize[0]*.5);
                gotoPosFromCenter[1] = gotoPosFromCenter[1]+(xyWindowSize[1]*.5);
                safeClick(gotoPosFromCenter[0], gotoPosFromCenter[1]);
                gotoPosFromCenter = {[0] = 0, 0};
                sleepWithBreakCheck(7000);
                local sleepTime = 0;
                while solutions[x][y] ~= 0 do
                  solutions[x][y] = solutions[x][y] - 1;
                  lsSleep(75);
                  safeClick((xyWindowSize[0]*.5)+100, (xyWindowSize[1]*.5)+100, 1);
                  lsSleep(150);
                  sleepTime = sleepTime + 7000;
                  checkBreak();
                end
                sleepWithBreakCheck(sleepTime);
              end
              if not rlToggle then x = x + 1;
              else x = x - 1; end;
              if x ~= 0 and x ~= bedSize+1 then
                if not rlToggle then
                  gotoPosFromCenter[0] = gotoPosFromCenter[0] + gapDistance;
                else
                  gotoPosFromCenter[0] = gotoPosFromCenter[0] - gapDistance;
                end
              end
            end
            if not rlToggle then x = bedSize; rlToggle = true;
            else x = 1; rlToggle = false; end;
            y = y + 1;
            if y ~= bedSize+1 then
              gotoPosFromCenter[1] = gotoPosFromCenter[1] + gapDistance;
            end
          end


        end
        solutionDiving = lsCheckBox(startX + perlGap, startY + baseSize + (perlGap * 2) + 10 + 60, z, 0xFFFFFFff, " Dive on solution clicks", solutionDiving)
        lsPrintWrapped(startX + perlGap, startY + baseSize + (perlGap * 2) + 10 + 95, z, lsScreenX - (startX*2),
                       0.75, 0.75, 0xFF7733ff, "    Detection can be difficult depending on the time of day, " ..
                       "afternoon is the worst and pinkish-white is the toughest to detect.  It may take several "..
                       "clicks of [Detect] to fully, or mostly, detect all spots.  You may manually fix detected or "..
                       "missed spots.\n    Autodive will attempt to "..
                       "swim and dive your solution.  It is dependent on detection to get the grid "..
                       "size correct, so you need to have had detected a non-white spot on all 4 sides in order "..
                       "to use it.\n    Clicking on a solved grid position will cause you to dive where you are "..
                       "currently, so you can swim to a position with a number manually in-game and click on the solution in that position "..
                       "the number of times indicated to dive that many times in that location, then swim "..
                       "to another position and repeat watching the puzzle get solved in game matching the "..
                       "solution grid.");
        --lsDoFrame();
      end


    --------------------------

    else
      srShowImageDebug("perlAssistant/perlAssistantTable.png", tableImageXOffset, tableImageYOffset, 0, 1);
      z = z + 1;
      local mouseClick = lsMouseClick(tableColOffset+tableImageXOffset,
                                      tableRowOffset+tableImageYOffset,
                                      tableSlotSize*#colorValues, tableSlotSize*(smallLength+mediumLength+largeLength+hugeLength), 1);
      if mouseClick then
          local col = math.floor((mouseClick[0] - (tableColOffset+tableImageXOffset)) / tableSlotSize)+1;
          local row = math.floor((mouseClick[1] - (tableRowOffset+tableImageYOffset)) / tableSlotSize)+1;
          local colorClicked = col;
          local sizeClicked = 1;
          local slotClicked = row;
          if row > smallLength then                          sizeClicked = sizeClicked + 1; slotClicked = slotClicked - smallLength; end;
          if row > smallLength+mediumLength then             sizeClicked = sizeClicked + 1; slotClicked = slotClicked - mediumLength; end;
          if row > smallLength+mediumLength+largeLength then sizeClicked = sizeClicked + 1; slotClicked = slotClicked - largeLength; end;
          
          necklace[sizeClicked][slotClicked][colorClicked] = necklace[sizeClicked][slotClicked][colorClicked] + 1;
          if necklace[sizeClicked][slotClicked][colorClicked] > #slotStatus then
              necklace[sizeClicked][slotClicked][colorClicked] = 0;
          end;
          saveNecklace();
          --lsPrintln("sizeClicked: " .. sizeNames[sizeClicked] .. ", slotClicked: " .. slotClicked .. ", colorClicked: " .. colorNames[colorClicked] .. " Set to: " .. slotStatus[necklace[sizeClicked][slotClicked][colorClicked]]);
          --lsPrintln(inspectit.inspect(necklace));
      end

      local slots = 0;
      for size = 1, sizeCount do
        for slot = 1, #necklace[size] do
          slots = slots + 1;
          for color = 1, #necklace[size][slot] do
            local x = tableColOffset + tableImageXOffset + (color*tableSlotSize) - tableSlotSize;
            local y = tableRowOffset + tableImageYOffset + (slots*tableSlotSize) - tableSlotSize;
              --lsPrint(x+statusXOffset, y+statusYOffset, z, statusScale, statusScale, colorValues[color], "" .. slotStatus[necklace[size][slot][color]]);


            if necklace[size][slot][color] == 0 then
               srShowImageDebug("perlAssistant/perl_Empty.png", x+statusXOffset, y+statusYOffset, z, 1);
            elseif necklace[size][slot][color] == 1 then
               srShowImageDebug("perlAssistant/perl_"..colorNames[color]..".png", x+statusXOffset, y+statusYOffset, z, 1);
            elseif necklace[size][slot][color] == 2 then
               srShowImageDebug("perlAssistant/perl_colorWrong_"..colorNames[color]..".png", x+statusXOffset, y+statusYOffset, z, 1);
            elseif necklace[size][slot][color] == 3 then
               srShowImageDebug("perlAssistant/perl_slotWrong_"..colorNames[color]..".png", x+statusXOffset, y+statusYOffset, z, 1);
            end
            --  lsPrint(x+statusXOffset, y+statusYOffset, z, statusScale, statusScale, colorValues[color], "" .. slotStatus[necklace[size][slot][color]]);
            --end
            if necklace[size][slot][color] == 1 then
              srShowImageDebug("perlAssistant/perl_"..colorNames[color]..".png", tableColOffset + tableImageXOffset + statusXOffset - tableSlotSize , y+statusYOffset, z, 1);
            end
          end
        end
      end

      if lsButtonText(tableImageXOffset + resetYOffset, tableImageYOffset + tableHeight + resetYOffset, z, 100,
                      0xFF0000ff, "Reset") then
          clearTable();
      end
    end

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100,
                    0xFFFFFFff, "Back") then
      if bedSize ~= 0  then
        for w = 1, bedSize do
          perls[w] = {}; solutions[w] = {};
          for h = 1, bedSize do
            perls[w][h] = 0; solutions[w][h] = 0;
          end
        end
        error = false;
        solved = false;
      end
      return;
    end

    lsDoFrame();
    lsSleep(10);

  end

end


imgcount = 0;
colcount = 0;
rowcount = 0;

-- finite field matrix solver

mat = {};   -- integer[i][j]
cols = {};  -- integer[]
m = 0;      -- count of rows of the matrix
n = 0;      -- count of columns of the matrix
np = 0;     -- count of columns of the enlarged matrix
r = 0;      -- minimum rank of the matrix
maxr = 0;   -- maximum rank of the matrix

function a(i,j)
  return mat[i][cols[j]];
end

function setmat(i,j,val)
  mat[i][cols[j]] = modulate(val);
end

-- finite field algebra solver
function modulate(x) 
    -- returns z such that 0 <= z < imgcount and x == z (mod imgcount)
    if x >= 0 then
      return x % imgcount;
    end
    x = (x * -1) % imgcount;
    if x == 0 then
      return 0;
    end
    return imgcount - x;
end

function gcd(x, y)  -- call when: x >= 0 and y >= 0
    if (y == 0) then return x; end;
    if (x == y) then return x; end;
    if (x > y) then x = x % y; end; -- x < y
    while x > 0 do
        y = y % x; -- y < x
        if (y == 0) then return x; end;
        x = x % y; -- x < y
    end
    return y;
end

function invert(value) -- call when: 0 <= value < imgcount
    -- returns z such that value * z == 1 (mod imgcount), or 0 if no such z
    if (value <= 1) then return value; end;
    local seed = gcd(value,imgcount);
    if (seed ~= 1) then return 0; end;
    local a = 1;
    local b = 0;
    local x = value;    -- invar: a * value + b * imgcount == x
    local c = 0;
    local d = 1;
    local y = imgcount; -- invar: c * value + d * imgcount == y
    while x > 1 do
        local tmp = math.floor(y / x);
        y = y - (x * tmp);
        c = c - (a * tmp);
        d = d - (b * tmp);
        tmp = a;  a = c;  c = tmp;
        tmp = b;  b = d;  d = tmp;
        tmp = x;  x = y;  y = tmp;
    end
    return a;
end



function initMatrix()

  maxr = math.min(m,n);
  mat = {};
    for col = 0, colcount - 1 do
      for row = 0, rowcount - 1 do
        local i = row * colcount + col;
        mat[i] = {};
        for j = 0, n - 1 do
          mat[i][j] = 0;
        end
        
        if colcount ~= 5      then mat[i][i]            = 1; end;
        if col > 0            then mat[i][i - 1]        = 1; end;
        if row > 0            then mat[i][i - colcount] = 1; end;
        if col < colcount - 1 then mat[i][i+1]          = 1; end;
        if row < rowcount - 1 then mat[i][i+colcount]   = 1; end;
      end
    end

    cols = {};
    for j = 0, np - 1 do cols[j] = j; end;

end

function solveProblem(goal)
    local size = colcount * rowcount;
    m = size;
    n = size;
    np = n + 1;
    initMatrix();
    for col = 0, colcount - 1 do
      for row = 0, rowcount - 1 do
        mat[(row * colcount) + col][n] = modulate(goal - perls[col+1][row+1]);
      end
    end
    return sweep();
end

function solve()
    local col;
    local row;
    for goal = 0, imgcount - 1 do
        if solveProblem(goal) then -- found an integer solution
            local anscols = {};
            for j = 0, n - 1 do  anscols[cols[j]] = j; end;
            for col = 0, colcount - 1 do
              for row = 0, rowcount -1 do
                local value;
                j = anscols[row * colcount + col];
                if j < r then
                  value = a(j,n);
                else
                  value = 0;
                end
                solutions[col+1][row+1] = value;
              end
            end
            return true;
        else
          return false
        end
    end
    
end

function sweep() 
    for step = 0, maxr  do
        r = step;
        if not sweepStep() then return false; end; -- failed in founding a solution
        if (r == maxr) then break; end;
    end
    return true; -- successfully found a solution
end

function sweepStep()
    local i;
    local j;
    local finished = true;
    for j = r, n - 1 do
        for i = r, m - 1 do
            local aij = a(i,j);
            if (aij ~= 0) then finished = false; end;
            local inv = invert(aij);
            if (inv ~= 0) then
                for jj = r, np - 1 do
                    setmat(i,jj, a(i,jj) * inv);
                end
                doBasicSweep(i,j);
                return true;
            end
        end
    end
    if (finished) then -- we have: 0x = b (every matrix element is 0)
        maxr = r;   -- rank(A) == maxr
        for j = n, np - 1 do
            for i = r, m - 1 do
                if (a(i,j) ~= 0) then return false; end; -- no solution since b != 0
            end
        end
        return true;    -- 0x = 0 has solutions including x = 0
    end
    return false;   -- failed in finding a solution
end


function swapMat(x,y) 
    local tmp  = mat[x];
    mat[x] = mat[y];
    mat[y] = tmp;
end

function swapCols(x,y)
    local tmp  = cols[x];
    cols[x] = cols[y];
    cols[y] = tmp;
end

function doBasicSweep(pivoti, pivotj)
    if (r ~= pivoti) then swapMat(r,pivoti); end;
    if (r ~= pivotj) then swapCols(r,pivotj); end;
    for i = 0, m - 1 do
        if (i ~= r) then
            local air = a(i,r);
            if (air ~= 0) then
                for j = r, np - 1 do
                    setmat(i,j, a(i,j) - a(r,j) * air);
                end
            end
        end
    end
end

function sleepWithBreakCheck(delay_time)
    local start_time = lsGetTimer();
    while delay_time - (lsGetTimer() - start_time) > 0 do
        checkBreak();
        lsSleep(50);
    end
end
