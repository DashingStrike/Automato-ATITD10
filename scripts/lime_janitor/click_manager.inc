ClickManager = class { class_name = "ClickManager" }
function ClickManager:init()
    self.click_delay = 200
    self.last_click = 0
end
function ClickManager:click(o)
    if not o.location then
        print(debug.traceback())
    end
    lsSleep(self.click_delay)
    safeClick(o.location.x, o.location.y, o.right_click)
    lsSleep(self.click_delay)
    return true
end
function ClickManager:click_image(action)
    lsSleep(self.click_delay)
    srReadScreen()
    local found
    if action.range then
        found = srFindImageInRange(action.image, action.range.x, action.range.y, action.range.width, action.range.height, action.tol or 7500)
    else
        found = srFindImage(action.image, action.tol or 7500)
    end
    if found then
        self:click{location = {x=found[0], y=found[1]}, action.right_click}
    end
    return found
end
function ClickManager:drag(action)
    lsSleep(self.click_delay)
    drag(action.x, action.y, action.target_x, action.target_y, action.delay or self.click_delay)
    lsSleep(self.click_delay)
    return true
end


