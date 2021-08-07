dofile("common.inc");

-- 7 Aug 2021: Quality of life improvement, prompt to continue journey

function doit()
  while 1 do
	  askForWindow("Click on Chariot, then click on Destination: <Location> you want to travel to. Pin that window.");

	  startTime = lsGetTimer();
	  while 1 do
		srReadScreen();
		window = findText("Travel will be free");
		dest = findText("Travel to");
		if dest then
		  chariot = string.match(dest[2], "Travel to (%a+)");
		end
		travelFree = findText("Travel now for free");

		if window then
		  message = "Waiting for travel to be free ...";
		  safeClick(window[0]+10, window[1]+2);
		else
		  message = "Could not find Chariot window";
		end

		if travelFree then
		  safeClick(travelFree[0]+10, travelFree[1]+2);
		  break;
		end

		sleepWithStatus(999, "Traveling to " .. chariot .. "\n\n" .. message .. "\n\nElapsed Time: " .. getElapsedTime(startTime), nil, 0.7, "Monitoring / Refreshing Chariot")
   	lsPlaySound("trolley.wav");

    -- Add prompt to continue using Free Chariot macro
		if promptOkay("You have arrived at " .. chariot .. " !\n\nElapsed Time: " .. 
			             getElapsedTime(startTime) .. "\n\nDo you want to keep traveling?", nil, 0.7, true, true) == nil then
			lsPlaySound("complete.wav");
      error("Journey completed. Have a great day!");
    else
    	sleepWithStatus(2000,"Starting over...",nil, 0.7,nil);
    end
  end
end 
