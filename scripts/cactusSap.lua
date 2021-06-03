--
-- CactusSap Collector v1.0 by Larame
--

dofile("common.inc");

cactus = {};
collected = 0;

function doit()
	askForWindow("Pin Royal Cactus.");
	srReadScreen();
	cactus = findAllImages("ThisIs.png");

	while (1) do
		srReadScreen();
		checkBreak();
		for i=1,#cactus do
			safeClick(cactus[i][0], cactus[i][1]);
			lsSleep(200);
			srReadScreen();
			text = findAllImages("cactus/sap.png");
			for i=#text, 1, -1 do
				safeClick(text[i][0], text[i][1]);
				collected = collected + 1;
			end
		end
		sleepWithStatus(4000, "Cactus Sap Collected: " .. collected)
	end
end
