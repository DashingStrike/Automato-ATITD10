-- v2.0 Tribisha: new apiary harvesting method that handles lag and all configurations of beehive placement
-- waits for a beehive menu, pins it and checks the hive for honey and wax.
-- then waits for the server lag to catch up and takes the honey and wax.

dofile("common.inc");

askText = "Press SHIFT over the ATITD window to start.\n\nMacro will search for the \'Check this Beehive\' message.\n\nClick on a Beehive and don't move you mouse.\n\nThe macro will pin the window, click the check button, then wait for the Take button, and unpin the window.\n\nThe macro will return to looking for a \'Check this Beehive\' message.";
check_text = "Check this Beehive";
take_text = "Take...";
this_is = "This is";
stage = 0;  -- 0 = checking for beehive, 1 = checking for take message


function doit()
  askForWindow(askText);
  while 1 do
    if stage == 0 then
      sleepWithStatus(100, "Searching for \'Check this Beehive\' message...", false);
      srReadScreen();
      click_text = findText(this_is);
      if click_text then
        clickAllText(this_is, 0, 0, true);
        lsSleep(16);
        clickAllText(check_text);
        stage = 1;
      end
    else
      sleepWithStatus(100, "Searching for \'Take...\' message...", false);
      srReadScreen();
      click_text2 = findText(this_is);
      if click_text2 then
        clickAllText(this_is);
        lsSleep(32);
      end
     
      srReadScreen();
      click_text3 = findText(take_text);
      if click_text3 then
        clickAllText(take_text);
        lsSleep(32);
        clickAllText("Everything");
        lsSleep(16);
        clickAllText(this_is, 0, 0, true);
        stage = 0;
      end
    end
    checkBreak();
  end
end
