--
-- 
--

dofile("common.inc");
dofile("settings.inc");

do_initial_wind = readSetting("do_initial_wind",do_initial_wind);
do_wind = readSetting("do_wind",do_wind);
doLog = readSetting("doLog",doLog);
doPitchChange = readSetting("doPitchChange",doPitchChange);

wind_time = 7920000;  	-- 2 hours teppy time
check_time = 10000;   	-- 10 seconds

srdelay = 100;  	--how long to wait after interacting before assuming the screen has finished changing
delay   = 10;  	--how long to wait when busy waiting
gems = 0;
lastGemHour = lsGetTimer(); -- init

-- Logfile writing variables
pitch = 0; -- current pitch
time = ""; -- time of gem found
fileName = "WaterMine.txt"; -- name of file to write to



function writeToLog(newWind)
  local text;

  srReadScreen();
  local fetchTime = getTime(1);
  if fetchTime then
    time = getTime(1)
  else
    time = "Time NOT Found";
  end
  
  timeSince = timestr(lsGetTimer() - lastGemHour);

  text = "---\nCurrent Pitch: " .. pitch .. "\nGame Time: " .. time .. "\nTime since last: " .. timeSince .. "\n---";

  logfile = io.open(fileName,"a+");
  if newWind == 1 then
    logfile:write("\n-= Started new log =-\n Game Time: " .. time .. "\n");
  else
    logfile:write(text .. "\n");
  end
  logfile:close();
end


function doit()
	promptOptions();
	askForWindow("\nPin a WaterMine and hit shift\n	\nstay in range of the water mine, doing whatever you want.\n	\nIf you leave the area, the macro will keep running till it's time to wind again. When you get back in range, just click on the water mine screen to refresh it, and the macro will continue without problems.\nThe macro will error out if you're not in range of the mine when the time comes to wind it up.");
	wind_timer = -1 - wind_time;
	gems = 0;

	findPitch = findText("Pitch Angle");
	if findPitch then
        pitch = tonumber(string.match(findPitch[2],"Pitch Angle is ([-0-9]+)"));
    end
    if(doLog) then
    	writeToLog(1); 
    end

	initial_start_time = lsGetTimer();
    lastGemHour = initial_start_time; -- get accurate start time
	while 1 do
		start_time = lsGetTimer();
		gems = gems + trygem();
		wind_timer = wind(wind_timer);
		while ((lsGetTimer() - start_time) < check_time) do
				time_left = check_time - (lsGetTimer() - start_time);
				time_left2 = wind_time - (lsGetTimer() - wind_timer);
				if (do_wind) then
					if gems ~= 0 then
						statusScreen("Current Pitch: " .. pitch .. "\nGems found: " .. gems .. "\nLast gem found " .. timestr(lsGetTimer() - lastGemHour) .. " ago\n\nTotal runtime: " .. 
							timestr(lsGetTimer() - initial_start_time) .. "\nChecking in: " .. timestr(time_left) .. 
							"\nWinding in: " .. timestr(time_left2));
					else
						statusScreen("Current Pitch: " .. pitch .. "\nGems found: " .. gems .. "\n\nTotal runtime: " .. 
						    timestr(lsGetTimer() - initial_start_time) .. "\nChecking in: " .. timestr(time_left) .. 
						    "\nWinding in: " .. timestr(time_left2));
					end				
				else
					if gems ~= 0 then
						statusScreen("Current Pitch: " .. pitch .. "\nGems found: " .. gems ..  "\nLast gem found " .. timestr(lsGetTimer() - lastGemHour) .. " ago\n\nTotal runtime: " .. 
							timestr(lsGetTimer() - initial_start_time) .. "\nChecking in: " .. timestr(time_left) .. "\nNot Winding");
					else
						statusScreen("Current Pitch: " .. pitch .. "\nGems found: " .. gems ..  "\n\nTotal runtime: " .. 
							timestr(lsGetTimer() - initial_start_time) .. "\nChecking in: " .. timestr(time_left) .. "\nNot Winding");
					end
				end
				lsSleep(delay);
				checkBreak();
		end
	end
end

function wind (wind_timer)
	if (do_wind) then
	    if (do_initial_wind) then
		if ((lsGetTimer() - wind_timer) < wind_time) then
			return wind_timer;
		else
			srReadScreen();
			--Windthe = srFindImage("Windthecollarspring.png");
			Windthe = findText("Wind the mechanism");
			if Windthe then
				srClickMouseNoMove(Windthe[0]+10, Windthe[1]+5);
				lsSleep(srdelay)
				return lsGetTimer();
			else
				error 'Could not find Water Mine Wind location';
			end
		end
	    else
		do_initial_wind = 1;
		return lsGetTimer();
	    end

	else
		return 0; 
	end
end

function trygem () -- Main status update
	srReadScreen();
	touch = findText("Water Mine");
	if (touch) then -- Don't error if we can't find it.  Assume the user will come back to the mine and touch the screen himself.
		srClickMouseNoMove(touch[0],touch[1]);
	end

	lsSleep(srdelay);
	srReadScreen();
    findPitch = findText("Pitch Angle");  -- update pitch if user changed it manually
    if findPitch then 
        pitch = tonumber(string.match(findPitch[2],"Pitch Angle is ([-0-9]+)"));
    end
	TakeEvery = findText("Take..."); -- new menu
	Takethe = findText("Take the"); -- old/current menu

    curGemHour = (lsGetTimer() - lastGemHour); -- milliseconds since last gem found or macro start



	if TakeEvery then -- potentially new menu for upgraded water mine with basket
		srClickMouseNoMove(TakeEvery[0]+10, TakeEvery[1]+5);
		lsSleep(srdelay);
		clickAllText("Everything");
		lsSleep(srdelay);
	    clickAllText("Water Mine");
	    writeToLog(0);
	    lastGemHour = lsGetTimer();
        return 1;
	elseif Takethe then -- original style of take
		srClickMouseNoMove(Takethe[0]+10, Takethe[1]+5);
		lsSleep(srdelay);
	    clickAllText("Water Mine");
	    writeToLog(0);
   	    lastGemHour = lsGetTimer();
        return 1;
    else
    	if (doPitchChange) then
	    	if curGemHour >= 1320000 then -- 1320000 ms = 22mins real time = 1 hour gametime
	    	    -- Change pitch +1
	   	    	findPitch = findText("Pitch Angle");
	        	if findPitch then
	                newPitch = tonumber(string.match(findPitch[2],"Pitch Angle is ([-0-9]+)"));
	            end

	    	    newPitch = pitch + 1;
	    	    if newPitch > 30 then -- max pitch possible is 30, restart at lowest (10)
	    	    	newPitch = 10;
	    	    end

	    	    changePitch = findText("Set the Pitch");
	    	    if changePitch then
	    	    	srClickMouseNoMove(changePitch[0]+10, changePitch[1]+5);
	                lsSleep(srdelay);
	                clickAllText("Angle of " .. newPitch);
	                pitch = newPitch;
	                lastGemHour = lsGetTimer(); -- reset change pitch timer
	                lsSleep(srdelay);
                	srReadScreen();
                	touch = findText("Water Mine");
					if (touch) then -- Don't error if we can't find it.  Assume the user will come back to the mine and touch the screen himself.
						srClickMouseNoMove(touch[0],touch[1]);
					end
	            end
		    end
		end
	 return 0;

	end
end



function promptOptions()
	scale = 0.8;
	
	local z = 0;
	local is_done = nil;
	local value = nil;
	-- Edit box and text display
	while not is_done do
		-- Put these everywhere to make sure we don't lock up with no easy way to escape!
		checkBreak("disallow pause");
		
		lsPrint(10, 10, z, scale, scale, 0xFFFFFFff, "Choose Options");
		
		-- lsEditBox needs a key to uniquely name this edit box
		--   let's just use the prompt!
		-- lsEditBox returns two different things (a state and a value)
		local y = 60;

		do_initial_wind = CheckBox(10, y, z+10, 0xFFFFFFff, " Do Initial Wind", do_initial_wind, scale);
        writeSetting("do_initial_wind",do_initial_wind);
		y = y + 32;
        
		do_wind = CheckBox(10, y, z+10, 0xFFFFFFff, " Do Any Windings", do_wind, scale);
		writeSetting("do_wind",do_wind);
		y = y + 32;

		doLog = CheckBox(10, y, z+10, 0xFFFFDDff, " Log gems found (WaterMine.txt)", doLog, scale);
		y = y + 32;
        writeSetting("doLog",doLog);

		doPitchChange = CheckBox(10, y, z+10, 0xFFFFDDff, " Change pitch", doPitchChange, scale);
		y = y + 16;
	    lsPrint(10, y, z, scale, scale, 0xFFFFFFff, "If no gems are found for 22 real");
	    y = y + 16;
	    lsPrint(10, y, z, scale, scale, 0xFFFFFFff, "minutes, pitch will change by +1");
        writeSetting("doPitchChange",doPitchChange);

        if doPitchChange then
	    lsPrint(10, y-16, z, scale, scale, 0xAAFFAAff, "If no gems are found for 22 real");
	    lsPrint(10, y, z, scale, scale, 0x88FFFAAff, "minutes, pitch will change by +1");
		end


		if lsButtonText(10, lsScreenY - 30, z, 100, 0xFFFFFFff, "Start") then
			is_done = 1;
		end

		
		if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFFFFFFff, "End script") then
			error "Clicked End Script button";
		end
	
		
		lsDoFrame();
		lsSleep(10); -- Sleep just so we don't eat up all the CPU for no reason
	end
end

function timestr (timer)
 	local fraction = timer - math.floor(timer/1000);
	local seconds =  math.floor(timer/1000);
	local minutes = math.floor(seconds/60);
	      seconds = seconds - minutes*60
	local hours = math.floor(minutes/60);
	      minutes = minutes - hours*60;
	local days = math.floor(hours/24);
	      hours = hours - days*24;

	local result = "";
	if (days > 0) then
		result = result .. days .. "d ";
	end
	if ((hours > 0) or (#result >1)) then
		result = result .. hours .. "h ";
	end
	if ((minutes > 0) or (#result>1)) then
		result = result .. minutes .. "m ";
	end
	if ((seconds > 0) or (#result>1)) then
		result = result .. seconds .. "s";
	else 
		result = result .. "0s";
	end
	return result;
end