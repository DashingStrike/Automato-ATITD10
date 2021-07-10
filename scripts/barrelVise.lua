dofile("screen_reader_common.inc");
dofile("ui_utils.inc");
dofile("common.inc");
dofile("settings.inc");

----------------------------------------
--          Global Variables          --
----------------------------------------
window_w = 200;
window_h = 195;
taken=0;
made=0;
stop_cooking=0;
per_click_delay = 0;
tick_time = 100;
----------------------------------------

function doit()

	-- testReorder();
	num_barrels = promptNumber("How many barrels?", 1);
	askForWindow("Have " .. 100*num_barrels  .. " Boards, " .. 2*num_barrels .. " Copper Straps & " .. 80*num_barrels
	.. " Wood in your inventory for every barrel you want to make.\n\n"
	.. "For large numbers of barrels you can get away with less wood, the average used is 60.\n\n"
	.. "Pin as many vises as you want, put the cursor over the ATITD window, press Shift.");

	srReadScreen();

	local vise_windows = findAllImages("ThisIs.png");

	if #vise_windows == 0 then
		error 'Could not find \'Barrel Vise\' windows.';
	end

	local last_ret = {};
	local should_continue = 1;
	while should_continue > 0 do

		-- Tick
		clickAll("ThisIs.png", 1);
		closePopUp();
		lsSleep(200);

		srReadScreen();
		local vise_windows2 = findAllImages("ThisIs.png");
		if #vise_windows == #vise_windows2 then
			for window_index=1, #vise_windows do
				local r = process_vise(vise_windows[window_index]);
				last_ret[window_index] = r;
			end
		end

		-- Display status and sleep
		should_continue = 0;
		checkBreak();
		local start_time = lsGetTimer();
		while tick_time - (lsGetTimer() - start_time) > 0 do
			time_left = tick_time - (lsGetTimer() - start_time);
			lsPrint(10, 6, 0, 0.7, 0.7, 0xB0B0B0ff, "Hold Ctrl+Shift to end this script.");
			lsPrint(10, 18, 0, 0.7, 0.7, 0xB0B0B0ff, "Hold Alt+Shift to pause this script.");
			lsPrint(10, 30, 0, 0.7, 0.7, 0xFFFFFFff, "Waiting " .. time_left .. "ms...");

			if not (#vise_windows == #vise_windows2) then
				lsPrintWrapped(10, 45, 5, lsScreenX-15, 1, 1, 0xFF7070ff, "Expected " ..
				#vise_windows .. " windows, found " .. #vise_windows2 .. ", not ticking.");
			elseif (made>=num_barrels) or (taken >= num_barrels) or (stop_cooking>0) then
				lsPrint(10, 45, 5, 0.8, 0.8, 0x70FF70ff, "Finishing up.");
			elseif (taken > made) then
				lsPrint(10, 45, 5, 0.8, 0.8, 0xFFFFFFff, taken .. "/" .. num_barrels .. " finished");
			else
				lsPrint(10, 45, 5, 0.8, 0.8, 0xFFFFFFff, made .. "/" .. num_barrels .. " complete");
			end

			for window_index=1, #vise_windows do
				if last_ret[window_index] then
					should_continue = 1;
					lsPrint(10, 80 + 15*window_index, 0, 0.7, 0.7, 0xFFFFFFff, "#" .. window_index .. " - " .. last_ret[window_index]);
				else
					lsPrint(10, 80 + 15*window_index, 0, 0.7, 0.7, 0xFFFFFFff, "#" .. window_index .. " - Finished");
				end
			end

			if lsButtonText(lsScreenX - 110, lsScreenY - 60, 0, 100, 0xFFFFFFff, "Finish up") then
				stop_cooking = 1;
			end
			if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFFFFFFff, "End script") then
				error "Clicked End Script button";
			end

			checkBreak();
			lsDoFrame();
			lsSleep(25);
		end

		checkBreak();
		-- error 'done';
	end
	lsPlaySound("Complete.wav");
end

function process_vise(window_pos)
	FuelStatus = 0;
	oneWood = makePoint(57,5);
	twoWood = makePoint(63,5);
	maxFlame = makePoint(148,20);
	progressOff = makePoint(176,56);
	barColor = 0x0101F9;

	-- if we can take anything do that
	local take = srFindImageInRange("barrelVise/Take.png", window_pos[0]-35, window_pos[1], window_w, window_h);
		if take then
			srClickMouseNoMove(take[0]+10, take[1]);
			lsSleep(250);
			srReadScreen();
			local everything = srFindImage("barrelVise/Everything.png");
				if(everything) then
					srClickMouseNoMove(everything[0]+10,everything[1]+4);
					lsSleep(100);
				end
			taken = taken+1;
			return 'Take Everything'
		end;

	-- else if we can start a barrel do that
	local barrel = srFindImageInRange("barrelVise/Makeabarrel.png", window_pos[0]-35,window_pos[1], window_w, window_h);
	if barrel then
		if (made>=num_barrels) or (taken >=num_barrels) or (stop_cooking>0) then
			return nil;
		else
			made = made+1;
			srClickMouseNoMove(barrel[0], barrel[1]);
			return 'Starting New Barrel'
		end;
	end;

	local cooldown = 0;
	local pos = srFindImageInRange("barrelVise/viseBars.png", window_pos[0]-35, window_pos[1], window_w, window_h);
	if not pos then
		error 'Could not find Vise bars';
	end;
	local curFuel1 = pixelMatch(pos, oneWood, barColor, 8)
	local curFuel2 = pixelMatch(pos, twoWood, barColor, 8)
	local curFlame = pixelMatch(pos, maxFlame, barColor, 8)
	local curProgress = pixelMatch(pos, progressOff, barColor, 8)

	if curFuel2 then
		FuelStatus = 2
	elseif curFuel1 then
		FuelStatus = 1
	else
		FuelStatus = 0
	end;

	if curProgress then
		cooldown = 1
	end

	if cooldown > 0 then	--Stop Stoking, should be enough heat to finish
		return('waiting for finish');
	elseif not curFlame then
		if FuelStatus < 1 then		-- Add 2 wood
			stoke(window_pos);
			stoke(window_pos);
			return "Flame: OK; Stoke (2 Wood)";
		elseif FuelStatus < 2 then		-- Add 1 wood
			stoke(window_pos);
			return "Flame: OK; Stoke (1 Wood)";
		end;
	else
		return "DANGER; No Stoke (0 Wood)";
	end;

	return 'Flame: OK; Fuel OK';
end

function stoke(window_pos)
	-- lsPrintln(window_pos[0] .. " " .. window_pos[1] .. " " .. window_w .. " " .. window_h);
	local pos = srFindImageInRange("barrelVise/Stoke.png", window_pos[0], window_pos[1], window_w, window_h);
		if not pos then
			error 'Could not find Stoke button';
		end
	srClickMouseNoMove(pos[0]+5, pos[1]+2);
end

function clickAll(image_name, up)
-- Find buttons and click them!
srReadScreen();
local buttons = findAllImages(image_name);
	if up then
		for i=#buttons, 1, -1  do
			srClickMouseNoMove(buttons[i][0]+5, buttons[i][1]+3);
			lsSleep(per_click_delay);
		end
	else
		for i=1, #buttons  do
			srClickMouseNoMove(buttons[i][0]+5, buttons[i][1]+3);
			lsSleep(per_click_delay);
		end
	end
end

function closePopUp()
  while 1 do
    srReadScreen()
    local ok = srFindImage("OK.png")
	    if ok then
	      statusScreen("Found and Closing Popups ...", nil, 0.7);
	      srClickMouseNoMove(ok[0]+5,ok[1]);
	      lsSleep(100);
	    else
	      break;
	    end
  end
end
