dofile("veg_janitor/vector.inc")

BLACK = 0x000000ff
WHITE = 0xFFFFFFff
GREY = 0x808080ff
RED = 0xFF2020ff
GREEN = 0x66CD00ff
ORANGE = 0xFFA500ff
YELLOW = 0xffff00ff
PINK = 0xffc0cbff
BROWN = 0xFFEBCDff
BLUE = 0x0000ffff
PURPLE = 0xcd00ffff
LIGHT_BLUE = 0x00ffe4ff

function iterateBoxPixels(box, xy_func, y_func)
    srReadScreen()
    for y = 0, box.height, 1 do
        if y_func then y_func(y) end
        for x = 0, box.width do
            local pixel = srReadPixelFromBuffer(box.left + x, box.top + y)
            if xy_func(x, y, pixel) then
                return
            end
        end
        checkBreak()
    end
end

function getBoxPixels(box)
    local pixels = {}
    iterateBoxPixels(box,
        function(x, y, pixel)
            pixels[y][x] = pixel
        end,
        function(y)
            pixels[y] = {}
        end)
    return pixels
end


function getScreenMiddle() local xyWindowSize = srGetWindowSize()
    return Vector:new { math.floor(xyWindowSize[0] / 2), math.floor(xyWindowSize[1] / 2) }
end

function makeLargeSearchBoxAroundPlayer(size)
  local search_size = size or 500
  local mid = getScreenMiddle()
  local top_left = mid - { math.floor(search_size / 2), math.floor(search_size / 2) }
  return makeBox(top_left.x, top_left.y, search_size, search_size)
end
