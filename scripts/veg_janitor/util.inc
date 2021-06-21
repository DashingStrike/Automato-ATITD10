

function playErrorSoundAndExit(message)
    lsPlaySound("fail.wav");
    error(message)
end
-- Helper function used in an objects constructor to setup its metatable correctly allowing for basic inheritence.
function newObject(class, o, read_only)
    o = o or {}
    setmetatable(o, class)
    class.__index = class
    if read_only then
        makeReadOnly(o)
    end
    return o
end

function makeReadOnly(table)
    local mt = getmetatable(table)
    if not mt then
        mt = {}
        if not table then print(debug.traceback()) end
        setmetatable(table, mt)
    end
    mt.__newindex = function(t, k, v)
        error("Attempt to update a read-only table", 2)
    end
    return table
end

function findRemoveNewWindows(existing_unpin_locs)
  local new_unpins = findAllImages("veg_janitor/pin.png",
    4800)
  local found_new_window = false
  if #new_unpins > 0 then
    for j=1, #new_unpins do
      local new_unpin = new_unpins[j]
      local new_x = new_unpin[0]
      local new_y = new_unpin[1]
      local new_unpin_is_an_old_one = false
      for i = 1, #existing_unpin_locs do
        local existing_x = existing_unpin_locs[i][0]
        local existing_y = existing_unpin_locs[i][1]
        local d_x = new_x - existing_x
        local d_y = new_y - existing_y
        local distance = math.sqrt(d_x*d_x + d_y*d_y)
        if distance < 20 then
          new_unpin_is_an_old_one = true
        end
      end
      if not new_unpin_is_an_old_one then
        lsSleep(click_delay)
        srClickMouse(new_unpin[0]+5,new_unpin[1]+5, 0)
        lsSleep(click_delay)
        srClickMouse(new_unpin[0]+5,new_unpin[1]+5, 0)
        found_new_window = true
      end
    end
  end
  return found_new_window
end
