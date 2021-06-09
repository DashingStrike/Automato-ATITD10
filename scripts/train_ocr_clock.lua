-- Console will output last character in each line (when training).
-- Also check https://www.atitd.org/wiki/tale6/User:Skyfeather/VT_OCR for more info on OCR

dofile("common.inc");
dofile("settings.inc");

offsetX = 0;
offsetY = 0;

function doit()
  askForWindow("Train Clock OCR\n\nUse offsetX/Y to get the white box to surround a letter/number on Clock. Then click Train button to show the code (in Console).\n\nOnce you find the values in Console, copy that to automato/games/ATITD9//data/charTemplate.txt file.");

  srReadScreen()
  clockRegion = findClockRegion();

  while true do
    findStuff();
  end
end


function findStuff()
  checkBreak();

  local y = 0;
  local scale = 0.9;

  srReadScreen();
  lsPrint(10, lsScreenY - 160, z, scale, scale, 0xFFFFFFff, "offsetX:");

  offsetX = readSetting("offsetX",offsetX);
  foo, offsetX = lsEditBox("offsetX", 80, lsScreenY - 160, 0, 50, 30, 1.0, 1.0, 0x000000ff, offsetX);
  offsetX = tonumber(offsetX);
  if not offsetX then
    lsPrint(140, lsScreenY - 160+3, 10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
    offsetX = 0;
  end
  writeSetting("offsetX",offsetX);

  lsPrint(10, lsScreenY - 130, z, scale, scale, 0xFFFFFFff, "offsetY:");

  offsetY = readSetting("offsetY",offsetY);
  foo, offsetY = lsEditBox("offsetY", 80, lsScreenY - 130, 0, 50, 30, 1.0, 1.0, 0x000000ff, offsetY);

  offsetY = tonumber(offsetY);
  if not offsetY then
    lsPrint(140, lsScreenY - 130+3, 10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
    offsetY = 0;
  end
  writeSetting("offsetY",offsetY);

    zoom = CheckBox(10, lsScreenY - 100, z, 0xffffffff, " Zoom 2.5x", zoom);
    if zoom then
      zoomLevel = 2.5;
    else
      zoomLevel = 1.0;
    end

    lsPrint(10, lsScreenY - 80, 10, 0.7, 0.7, 0xFFFFFFff, "Train Results displays in Console!");
    lsPrint(10, lsScreenY - 60, 10, 0.7, 0.7, 0xFFFFFFff, "Replace ? with the character you are training");


  srStripRegion(clockRegion.x, clockRegion.y, clockRegion.width, clockRegion.height)
  if lsButtonText(0, lsScreenY - 30, z, 100,
                  0xFFFFFFff, "Train") then

    --Console will output ??? as last character in each line (when training). Replace ??? with the correct number of letter (case sensitive)
    srTrainTextReader(clockRegion.x+offsetX,clockRegion.y+offsetY, '?')
  end

  srMakeImage("clock-region", clockRegion.x, clockRegion.y, clockRegion.width, clockRegion.height, true);
  srShowImageDebug("clock-region", 0, 0, 1, zoomLevel);

  lsDrawLine(offsetX * zoomLevel, offsetY * zoomLevel, offsetX * zoomLevel, (offsetY + 12) * zoomLevel, 2, 1 + zoomLevel, 1, 0x66FF66FF);

  if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100,
                  0xFFFFFFff, "End Script") then
    error(quitMessage);
  end

  lsDoFrame();
  lsSleep(50);

end
