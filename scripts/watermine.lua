--
-- 
--

dofile("common.inc");
dofile("settings.inc");

do_initial_wind = readSetting("do_initial_wind",do_initial_wind);
do_wind = readSetting("do_wind",do_wind);
do_log = readSetting("do_log",do_log);
do_pitch_change = readSetting("do_pitch_change",do_pitch_change);

wind_time = 7920000;  	-- 2 hours teppy time
check_time = 10000;   	-- 10 seconds

srdelay = 100;  	--how long to wait after interacting before assuming the screen has finished changing
delay   = 10;  	--how long to wait when busy waiting
gems = 0;
total_gems = 0;
last_gem_hour = lsGetTimer(); -- init

-- Logfile writing variables
pitch = 0; -- current pitch
time = ""; -- time of gem found



function writeToLog(new_wind)
  srReadScreen();
  local fetch_time = getTime(1);
  if fetch_time then
    time = getTime(1)
  else
    time = "Time NOT Found";
  end
  
  local time_since = timestr(lsGetTimer() - last_gem_hour);
  local mine_region = findText("Water Mine",nil,REGION);
  local mine_text = parseText(mine_region.x, mine_region.y, mine_region.width, mine_region.height);
  local text = "";
  local filename = "WaterMine -";
  local is_not_label = string.sub(mine_text[2][2],1,11);

  if is_not_label == "Pitch Angle" then -- we need to check to see if water mine has a label
  	filename = filename .. ".txt"; -- default filename for unlabelled water mines
    text = "Current Pitch: " .. pitch .. 
           "\nGame Time: " .. time .. 
           "\nTime since last: " .. time_since .. 
           "\n---";
  else
  	filename = filename .. " " .. mine_text[2][2] .. ".txt"; -- add the label to filename
 	  text = "-=> " .. mine_text[2][2] ..  -- add the label to log
 	         " <=- \nCurrent Pitch: " .. pitch .. 
 	         "\nGame Time: " .. time .. 
 	         "\nTime since last: " .. time_since .. 
 	         "\n---";
  end

  local logfile = io.open(filename,"a+");
  if new_wind == 1 then -- if the macro has restarted, add this line
    logfile:write("\n\n*** Started new log ***\n Game Time: " .. time .. "\n---");
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

	find_pitch = findText("Pitch Angle");
	if find_pitch then
        pitch = tonumber(string.match(find_pitch[2],"Pitch Angle is ([-0-9]+)"));
    end
    if(do_log) then
    	writeToLog(1); 
    end

	initial_start_time = lsGetTimer();
    last_gem_hour = initial_start_time; -- get accurate start time
	while 1 do
		start_time = lsGetTimer();
		gems = gems + trygem();
		wind_timer = wind(wind_timer);
		while ((lsGetTimer() - start_time) < check_time) do
				time_left = check_time - (lsGetTimer() - start_time);
				time_left2 = wind_time - (lsGetTimer() - wind_timer);
				if (do_wind) then
					if gems ~= 0 then
						statusScreen("Current Pitch: " .. pitch .. "\nGems found: " .. gems .. " of " .. total_gems .. "\nLast gem found " .. timestr(lsGetTimer() - last_gem_hour) .. " ago\n\nTotal runtime: " .. 
							timestr(lsGetTimer() - initial_start_time) .. "\nChecking in: " .. timestr(time_left) .. 
							"\nWinding in: " .. timestr(time_left2));
					else
						statusScreen("Current Pitch: " .. pitch .. "\nGems found: " .. gems .. " of " .. total_gems .. "\n\nTotal runtime: " .. 
						    timestr(lsGetTimer() - initial_start_time) .. "\nChecking in: " .. timestr(time_left) .. 
						    "\nWinding in: " .. timestr(time_left2));
					end				
				else
					if gems ~= 0 then
						statusScreen("Current Pitch: " .. pitch .. "\nGems found: " .. gems .. " of " .. total_gems .. "\nLast gem found " .. timestr(lsGetTimer() - last_gem_hour) .. " ago\n\nTotal runtime: " .. 
							timestr(lsGetTimer() - initial_start_time) .. "\nChecking in: " .. timestr(time_left) .. "\nNot Winding");
					else
						statusScreen("Current Pitch: " .. pitch .. "\nGems found: " .. gems ..  " of " .. total_gems .. "\n\nTotal runtime: " .. 
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
	local touch = findText("Water Mine");
	if (touch) then -- Don't error if we can't find it.  Assume the user will come back to the mine and touch the screen himself.
		srClickMouseNoMove(touch[0],touch[1]);
	end

  find_pitch = findText("Pitch Angle");  -- update pitch if user changed it manually
  if find_pitch then 
    pitch = tonumber(string.match(find_pitch[2],"Pitch Angle is ([-0-9]+)"));
  end
	
	local take_every = findText("Take..."); -- new menu
	local take_the = findText("Take the"); -- old/current menu
  local cur_gem_hour = (lsGetTimer() - last_gem_hour); -- milliseconds since last gem found or macro start

	if take_every then -- potentially new menu for upgraded water mine with basket
			srClickMouseNoMove(take_every[0]+10, take_every[1]+5);
			lsSleep(srdelay);
			clickAllText("Everything");
			lsSleep(srdelay);
	    clickAllText("Water Mine");
	    writeToLog(0);
	    last_gem_hour = lsGetTimer();
	    total_gems = total_gems + 1;
	    return 1;
	elseif take_the then -- original style of take
			srClickMouseNoMove(take_the[0]+10, take_the[1]+5);
			lsSleep(srdelay);
	    clickAllText("Water Mine");
	    writeToLog(0);
	    last_gem_hour = lsGetTimer();
	    total_gems = total_gems + 1;
	    return 1;
  else
		if (do_pitch_change) then
	  	if cur_gem_hour >= 1320000 then -- 1320000 ms = 22mins real time = 1 hour gametime
		    -- Change pitch +1
		    find_pitch = findText("Pitch Angle");
	    	if find_pitch then
	        new_pitch = tonumber(string.match(find_pitch[2],"Pitch Angle is ([-0-9]+)"));
	      end

		    new_pitch = pitch + 1;
		    if new_pitch > 30 then -- max pitch possible is 30, restart at lowest (10)
		    	new_pitch = 10;
		    end

		    local changePitch = findText("Set the Pitch");
		    if changePitch then
		    	srClickMouseNoMove(changePitch[0]+10, changePitch[1]+5);
	        lsSleep(srdelay);
	        clickAllText("Angle of " .. new_pitch);
	        pitch = new_pitch;
	        last_gem_hour = lsGetTimer(); -- reset change pitch timer
	        lsSleep(srdelay);
	      	srReadScreen();
	      	touch = findText("Water Mine");
					if (touch) then -- Don't error if we can't find it.  Assume the user will come back to the mine and touch the screen himself.
						srClickMouseNoMove(touch[0],touch[1]);
					end
					gems = 0; -- reset gem found count after pitch change
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

		do_log = CheckBox(10, y, z+10, 0xFFFFDDff, " Log gems found (WaterMine.txt)", do_log, scale);
		y = y + 32;
        writeSetting("do_log",do_log);

		do_pitch_change = CheckBox(10, y, z+10, 0xFFFFDDff, " Change pitch", do_pitch_change, scale);
		y = y + 16;
	    lsPrint(10, y, z, scale, scale, 0xFFFFFFff, "If no gems are found for 22 real");
	    y = y + 16;
	    lsPrint(10, y, z, scale, scale, 0xFFFFFFff, "minutes, pitch will change by +1");
        writeSetting("do_pitch_change",do_pitch_change);

        if do_pitch_change then
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