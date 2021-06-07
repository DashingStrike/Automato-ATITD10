dofile("common.inc");

askText = singleLine([[
  Provides a control interface for running many charcoal hearths or
  ovens simultaneously.
]]);

wmText = "Tap Ctrl on Charcoal Hearths or Ovens\nto open and pin. Tap Alt to open, pin\nand stash.";

click_delay = 0;

buttons = {
  {
    name = "Begin",
    buttonPos = makePoint(10, 110),
    buttonSize = 270,
    image = "charcoal/begin.png",
    offset = makePoint(25, 10)
  },
  {
    name = "Wood",
    buttonPos = makePoint(10, 166),
    buttonSize = 130,
    image = "charcoal/wood.png",
    offset = makePoint(0, 25)
  },
  {
    name = "Water",
    buttonPos = makePoint(150, 166),
    buttonSize = 130,
    image = "charcoal/water.png",
    offset = makePoint(0, 25)
  },
  {
    name = "Closed",
    buttonPos = makePoint(10, 215),
    buttonSize = 80,
    image = "charcoal/vent.png",
    offset = makePoint(18, 25)
  },
  {
    name = "Open",
    buttonPos = makePoint(105, 215),
    buttonSize = 80,
    image = "charcoal/vent.png",
    offset = makePoint(34, 25)
  },
  {
    name = "Full",
    buttonPos = makePoint(200, 215),
    buttonSize = 80,
    image = "charcoal/vent.png",
    offset = makePoint(52, 25)
  }
};

function doit()
  askForWindow(askText);
	--function windowManager(title, message, allowCascade, allowWaterGap, varWidth, varHeight, sizeRight, offsetWidth, offsetHeight)
  windowManager("Charcoal Setup", wmText, nil, nil, nil, nil, nil, nil, 16);   --add 16 extra pixels to window height because window expands with 'Take...' menu after first batch is created
  unpinOnExit(ccMenu);
end

function ccMenu()
  while 1 do
    for i=1, #buttons do
      if showButton(buttons[i]) then
	runCommand(buttons[i]);
      end
    end
    statusScreen("CC Control Center", 0x00d000ff);
  end
end

function showButton(button)
  return lsButtonText(button.buttonPos[0], button.buttonPos[1],
		      0, button.buttonSize, 0xFFFFFFff, button.name)
end

function runCommand(button)
  return clickAllImages(button.image, button.offset[0], button.offset[1]);
end
