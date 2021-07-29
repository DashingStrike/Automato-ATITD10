--
-- 
--

dofile("common.inc");
dofile("settings.inc");

do_initial_wind = readSetting("do_initial_wind",do_initial_wind);
do_wind = readSetting("do_wind",do_wind);
do_log = readSetting("do_log",do_log);
do_pitch_change = readSetting("do_pitch_change",do_pitch_change);
flip_flop = readSetting("flip_flop",flip_flop);
flip1 = readSetting("flip1",flip1);
flip2 = readSetting("flip2",flip2);
change_pitch_time = readSetting("change_pitch_time",change_pitch_time);

wind_time = 7920000;  	-- 2 hours teppy time
check_time = 10000;   	-- 10 seconds

srdelay = 100;  	--how long to wait after interacting before assuming the screen has finished changing
delay   = 10;  	--how long to wait when busy waiting
gems = 0;
total_gems = 0;
last_gem_hour = lsGetTimer(); -- init
gems_reset = 0;

-- low_range = 19;  -- floor of range to cycle pitches through
-- high_range = 22; -- ceiling of range to cycle pitches through

-- Logfile writing variables
pitch = 0;
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
	askForWindow("Pin a WaterMine and hit shift.\n\nStay in range of the water mine, doing whatever you want.\n	\n" .. 
		           "If you leave the area, the macro will keep running till it's time to wind again. When you get" .. 
		           " back in range, just click on the water mine screen to refresh it, and the macro will" ..
		           "continue without problems.\n\nLog gems found option will track: pitch, gametime, last gem found time." .. 
		           " If you label your watermine, the filename and log will contain the label.\n\n Change Pitch option" ..
		           " will change the pitch every 22 minutes if a gem not found. Additional option for Change pitch is flip-flop," ..
		           " which allows you to set 2 pitches to flip back and forth between when it changes the pitch."
		           );
	wind_timer = -1 - wind_time;
	gems = 0;

 if(do_log) then
  	writeToLog(1); 
  end

find_pitch = findText("Pitch Angle");
if find_pitch then
  pitch = tonumber(string.match(find_pitch[2],"Pitch Angle is ([-0-9]+)"));
end

if flip_flop then
	if pitch ~= tonumber(flip1) and pitch ~= tonumber(flip2) then
		changePitch(flip1);
	end
end

	initial_start_time = lsGetTimer();
    last_gem_hour = initial_start_time; -- get accurate start time
	while 1 do
		start_time = lsGetTimer();
		gems = gems + trygem();
		if gems_reset == 1 then -- reset found count but not total count
			gems = 0;
			gems_reset = 0;
		end
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
	if touch ~= nil then -- Don't error if we can't find it.  Assume the user will come back to the mine and touch the screen himself.
		clickAllText("Water Mine");
	end

  srReadScreen();
  local find_pitch = findText("Pitch Angle");  -- update pitch if user changed it manually
  if find_pitch then 
    pitch = tonumber(string.match(find_pitch[2],"Pitch Angle is ([-0-9]+)"));
  end
	
	local take_every = findText("Take..."); -- new menu
	local take_the = findText("Take the"); -- old/current menu
  local cur_gem_hour = (lsGetTimer() - last_gem_hour); -- milliseconds since last gem found or macro start
  local not_refreshed = 1; -- var to detect if the menu has refreshed after taking

	if take_every then -- potentially new menu for upgraded water mine with basket
			clickAllText("Take...");
			lsSleep(srdelay);
			clickAllText("Everything");
			while not_refreshed == 1 do
			  clickAllText("Water Mine");	

				srReadScreen();
				take_every = findText("Take...");
        statusScreen("Waiting for server update.")
			  if take_every == nil then
			  	not_refreshed = 0;
			  end
			  lsSleep(50); -- don't chew up all the cpu
			end
	    writeToLog(0);
	    last_gem_hour = lsGetTimer();
	    total_gems = total_gems + 1;
	    return 1;
	elseif take_the then -- original style of take
			clickAllText("Take the");
			while not_refreshed == 1 do
			  clickAllText("Water Mine");	
				
				srReadScreen();
				take_the = findText("Take the");
        statusScreen("Waiting for server update.")
			  if take_the == nil then
			  	not_refreshed = 0;
			  end
			  lsSleep(50); -- don't chew up all the cpu
			end
	    writeToLog(0);
	    last_gem_hour = lsGetTimer();
	    total_gems = total_gems + 1;
	    return 1;
  else
		if (do_pitch_change) then
	  	if tonumber(cur_gem_hour) >= tonumber(change_pitch_time) * 60000 then 

        srReadScreen();
		    find_pitch = findText("Pitch Angle");
	    	if find_pitch then
	        new_pitch = tonumber(string.match(find_pitch[2],"Pitch Angle is ([-0-9]+)"));
	      end

        if flip_flop then
        	if new_pitch == tonumber(flip1) then
            changePitch(flip2);
        	else
            changePitch(flip1);
        	end
        else
			    new_pitch = pitch + 1;
			    if new_pitch > 30 then -- max pitch possible is 30, restart at lowest (10)
			    	new_pitch = 10;
			    end
			    changePitch(new_pitch);
			  end
		  end
		end
		return 0;
	end
end

function changePitch(change_to)
  local set_pitch = findText("Set the Pitch");
  if set_pitch then
  	clickAllText("Set the Pitch");
    lsSleep(srdelay);
    clickAllText("Angle of " .. change_to);
    pitch = change_to;
    last_gem_hour = lsGetTimer(); -- reset change pitch timer
    lsSleep(srdelay);

  	srReadScreen(); -- update window
  	touch = findText("Water Mine");
		if (touch) then -- Don't error if we can't find it.  Assume the user will come back to the mine and touch the screen himself.
			clickAllText("Water Mine");
		end
		gems_reset = 1; -- reset gem found count after pitch change
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
	    y = y + 32;
	    flip_flop = CheckBox(10, y, z+10, 0xFFFFDDff, " Pitch flip-flop", flip_flop, scale);
	    if flip_flop then
				lsPrint(10, y+24, z, scale, scale, 0xffffffff, "Pitch 1:");
				is_done, flip1 = lsEditBox("flip1", 185, y+24, z, 50, 30, scale, scale,
											   0x000000ff, flip1);
				if not tonumber(flip1) then
				  is_done = false;
				  lsPrint(140, y+24, z+10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
				  flip1 = 15;
				end
				writeSetting("flip1",tonumber(flip1));

				lsPrint(10, y+52, z, scale, scale, 0xffffffff, "Pitch 2:");
				is_done, flip2 = lsEditBox("flip2", 185, y+48, z, 50, 30, scale, scale,
											   0x000000ff, flip2);
				if not tonumber(flip2) then
				  is_done = false;
				  lsPrint(140, y+52, z+10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
				  flip2 = 15;
				end
				writeSetting("flip2",tonumber(flip2));

				lsPrint(10, y+74, z, scale, scale, 0xffffffff, "Minutes before change:");
				is_done, change_pitch_time = lsEditBox("change_pitch_time", 185, y+72, z, 50, 30, scale, scale,
											   0x000000ff, change_pitch_time);
				if not tonumber(change_pitch_time) then
				  is_done = false;
				  lsPrint(140, y+74, z+10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
				  change_pitch_time = 22; -- default to 1 game hour
				end
				writeSetting("change_pitch_time",tonumber(change_pitch_time));

	    end
      writeSetting("flip_flop",flip_flop);
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
