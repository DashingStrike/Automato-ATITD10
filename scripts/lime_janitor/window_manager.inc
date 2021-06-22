WindowManager = class { class_name = "WindowManager" }
function WindowManager:init(click_manager)
    self.click_manager = click_manager
    self.windows = {}
    self.indexes = {}
    self.next_free_index = 1
    table.insert(cleanups, self)
end

function WindowManager:cleanup()
    for window, status in pairs(self.windows) do
        self:close(window)
    end
end

function WindowManager:close(window)
    if self.windows[window] == "opened" then
        if self:click_button_if_present(window, "lime_janitor/unpin.png") then
            self.windows[window] = nil
        end
    end
end

function WindowManager:open_verify_and_stash_window(window)
    assert(not self.windows[window], "Warning trying to open an existing window!")
    self.windows[window] = "unopened"
    self.indexes[window] = self.next_free_index
    self.next_free_index = self.next_free_index + 1
    local window_top_left = self:open_window(window)
    if window_top_left then
        if self:drag_window_to_free_slot {
            window_top_left = window_top_left,
            window = window } then
            self.windows[window] = "opened"
            return true
        end
    end
    return false
end

WINDOW_OFFSET_X = 10
WINDOW_OFFSET_Y = 10
function indexToWindowPos(index, width, height)
    local columns = getNumberWindowColumns(width)
    local x = width * ((index - 1) % columns) + WINDOW_OFFSET_X
    local y = height * math.floor((index - 1) / columns) + WINDOW_OFFSET_Y
    return Vector(x, y, 1)
end

function getNumberWindowColumns(window_width)
    local xyWindowSize = srGetWindowSize()
    local width = xyWindowSize[0] * 0.6
    return math.floor(width / window_width);
end

function WindowManager:retry_clicking_popup_triggering_button(window, image)
    if self:click_button_if_present(window, image) then
        window:refresh()
        return not self:verify_window_has_image {
            window = window,
            image = image }
    end
    return false
end
function WindowManager:close_popup_if_present()
    return self.click_manager:click_image {
        image = "ok.png"
    }
end

function WindowManager:click_button_if_present(window, image)
    if type(window) == "string" then
        return self.click_manager:click_image {
            image = window,
        }
    end
    if not window.x or not window.y then
        error("Cannot click " .. image .. " as don't know where the window is ")
    end
    return self.click_manager:click_image {
        image = image,
        range = { x = math.max(window.x, 0), y = math.max(window.y, 0), width = window.initial_width, height = window.initial_height },
    }
end

function WindowManager:wait_for_button(window, image)
    srReadScreen()
    if not window.x or not window.y then
        error("Cannot click " .. image .. " as don't know where the window is ")
    end
    return srFindImageInRange(image, math.max(window.x, 0), math.max(window.y, 0), window.initial_width, window.initial_height)
end

function WindowManager:drag_window_to_free_slot(o)
    local window = o.window
    local location = indexToWindowPos(self.indexes[window], o.window.initial_width, o.window.initial_height)

    if self.click_manager:drag {
        x = o.window_top_left.x,
        y = o.window_top_left.y,
        target_x = location.x,
        target_y = location.y } then
        local top_left_if_open = self:verify_window_open_at_new_location {
            window = o.window,
            x = location.x,
            y = location.y }
        if top_left_if_open then
            window:set_location(top_left_if_open)
            return true
        end
    end
    return false
end

function WindowManager:open_window(window)
    self.click_manager:click {
        right_click = true,
        location = window.click_location }
    return self:verify_initial_window_open(window)
end

function WindowManager:verify_open(o)
    local top_left_x, top_left_y
    if o.coord_is_middle_side then
        top_left_x = o.x - 20
        top_left_y = o.y - math.floor(o.height / 2)
    else
        top_left_x = o.x - 20
        top_left_y = o.y - 20
    end
    top_left_y = math.max(0, top_left_y)
    top_left_x = math.max(0, top_left_x)

    local search_width = o.width + 40
    local search_height = o.height + 40
    srReadScreen()
    local found_verification_image = srFindImageInRange(o.open_verification_image, top_left_x, top_left_y,
            search_width, search_height, 7500);
    local window_top_left = srFindImageInRange("lime_janitor/top_left.png", top_left_x, top_left_y,
            search_width, search_height, 7500);
    if found_verification_image and window_top_left then
        return Vector(window_top_left[0], window_top_left[1], 1)
    else
        return false
    end
end
function WindowManager:verify_window_has_image(o)
    return self:verify_open {
        x = o.window.x,
        y = o.window.y,
        width = o.window.initial_width,
        height = o.window.initial_height,
        open_verification_image = o.image
    }
end
function WindowManager:verify_window_open_at_new_location(o)
    return self:verify_open {
        x = o.x,
        y = o.y,
        width = o.window.initial_width,
        height = o.window.initial_height,
        open_verification_image = o.window.open_verification_image
    }
end

function WindowManager:verify_initial_window_open(window)
    return self:verify_open {
        coord_is_middle_side = true,
        x = window.click_location.x,
        y = window.click_location.y,
        width = window.initial_width,
        height = window.initial_height,
        open_verification_image = window.open_verification_image
    }
end

