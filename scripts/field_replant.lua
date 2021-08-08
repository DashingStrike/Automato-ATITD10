dofile("common.inc");

askText = "Hover over ATITD window and hit SHIFT.\n\nClick on a field to Harvest and Replant same seeds." ..
          "\n\nMake sure you are not holding other vegetable seeds before you start, otherwise it may plant the wrong seed.";
veg_field = "Vegetable Field";
harvest_text = "Harvest Crop";
plant_text = "Plant";
stage = 0;

function doit()
  askForWindow(askText);
  while 1 do
    if stage == 0 then
      sleepWithStatus(16, "Searching for \'Vegetable Field\'...", false);
      srReadScreen();
      click_text = findText(veg_field);
      if click_text then
        clickAllText(veg_field, 0, 0, true); -- pin window
        lsSleep(16);
        clickAllText(harvest_text); -- harvest crop
        waitForNoImage("ok.png");   -- wait for harvesting window to go away
        stage = 1;
      end
    end

    if stage == 1 then
      sleepWithStatus(16, "Searching for \'Plant...\' message...", false);
      srReadScreen();
      click_text2 = findText(veg_field); -- refresh the vegetable field window
      if click_text2 then
        clickText(click_text2);
        lsSleep(32);
      end
  
      srReadScreen();
	    click_text3 = findText(plant_text); -- wait for the plant message
	    if click_text3 then
	      clickText(click_text3);
	      lsSleep(32);
	      srReadScreen();
	      click_loc = findText("Seeds");
	      if click_loc then
	      	clickText(click_loc); -- click seeds
	      	lsSleep(32);
	      	local clickx = tonumber(click_loc[0]) + 30; -- click submenu with offset
	      	local clicky = tonumber(click_loc[1]) + 20;
	      	clickXY(clickx,clicky);
	      end
	      lsSleep(16);
	      clickAllText(veg_field, 0, 0, true); -- unpin vegetable window
	      stage = 0; -- go back to looking for the new window
	    end
    end
    checkBreak();
  end
end