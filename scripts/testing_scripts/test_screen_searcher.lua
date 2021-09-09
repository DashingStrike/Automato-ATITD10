dofile("common.inc");
dofile("screen_searcher.inc");

windowIndex = 1;

function doit()
  askForWindow("This macro lets you test the ScreenSearcher utility class. Press Shift over ATITD window.");

  local quarterScreenWidth = srGetWindowSize()[0] / 4
  local yourBoxToSearch = makeLargeSearchBoxAroundPlayer(quarterScreenWidth)
  local screenSearcher = ScreenSearcher:new(yourBoxToSearch, 'compareColorEx')

  while true do
    checkBreak();

    displayUI(screenSearcher)

    checkBreak();
    lsDoFrame();
    lsSleep(tick_delay);
  end
end

function displayUI(screenSearcher)
  local screenWidth = lsGetWindowSize()[0]
  local screenHeight = lsGetWindowSize()[1]
  current_y = 10
  lsPrint(10, 0, current_y, 1, 1, 0xFFFFFFff, "Screen Searcher Tester:");
  current_y = current_y + 30
  if lsButtonText(X_PADDING, current_y, z, 100, ORANGE, "Snapshot") then
    screenSearcher:snapshotScreen('main')
    snapshotted = true
  end

  if snapshotted then
    current_y = current_y + 30
    if lsButtonText(X_PADDING, current_y, z, 300, 0xFFFFFFff, "Mark Changes As Dead Zone") then
      screenSearcher:markChangesAsDeadZone('main')
    end
    current_y = current_y + 30
    if lsButtonText(X_PADDING, current_y, z, 300, 0xFFFFFFff, "Mark Changes As Region 1") then
      screenSearcher:markAllChangesAsRegion('main', 1)
    end
    current_y = current_y + 30
    if lsButtonText(X_PADDING, current_y, z, 300, 0xFFFFFFff, "Mark Connected Areas As New Regions") then
      screenSearcher:markConnectedAreasAsNewRegions('main')
    end
    current_y = current_y + 30
    if lsButtonText(X_PADDING, current_y, z, 200, GREEN, "Draw Regions") then
      screenSearcher:drawRegions(3000)
    end
  end

  if lsButtonText(screenWidth - 110, screenHeight - 30, z, 100, 0xFFFFFFff, "End script") then
    error "Script exited by user";
  end
end
