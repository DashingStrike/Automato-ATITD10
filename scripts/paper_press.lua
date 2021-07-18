dofile("common.inc");
dofile("settings.inc");

----------------------------------------
--          Global Variables          --
----------------------------------------
askText = singleLine([[
  Automatically runs many paper presses, adding/removing linen as necessary. Make sure the
  VT window is in the TOP-RIGHT corner of the screen.
]])

wmText = "Tap Ctrl on paper presses to open and pin.\nTap Alt on paper presses to open, pin and stash.";

num_loops = 0;
----------------------------------------

function doit()
	num_loops = promptNumber("How many passes ?", 100);
	askForWindow(askText);
  windowManager("Paper Press Setup", wmText, false, true, 420, 145, nil, 10, 25);
  askForFocus();
  doPaper();
end

function refreshWindows()
  srReadScreen();
  this = findAllText("This is");
    for i=1,#this do
      clickText(this[i]);
    end
  lsSleep(150);
end

function doPaper()
	for i=1, num_loops do

		-- refresh windows
		refreshWindows();
		lsSleep(200);

		clickAllText("Line the press with Linen");
		lsSleep(200);

		clickAllText("Make some papyrus paper");
		lsSleep(200);

		sleepWithStatus(75000, "[" .. i .. "/" .. num_loops .. "] Waiting for 1st batch of paper to finish", nil, 0.7);

		clickAllText("Make some papyrus paper");
		lsSleep(200);

		sleepWithStatus(75000, "[" .. i .. "/" .. num_loops .. "] Waiting for 2nd batch of paper to finish", nil, 0.7);

		clickAllText("Remove the Linen from the press");
		lsSleep(200);

		clickAllText("Take...");
		lsSleep(200);

		clickAllText("Everything");
		lsSleep(200);

	end
end
