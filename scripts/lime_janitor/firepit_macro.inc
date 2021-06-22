dofile("lime_janitor/firepit_manager.inc")
FirepitMacro = class { class_name = "FirepitMacro" }
function FirepitMacro:init(window_manager)
    self.state = "initial"
    self.window_manager = window_manager
end

function FirepitMacro:start(config)
    self.config = config
    self.collector = ManualLocationCollector { selection_box_size = 40 }
    self.state = "awaiting_locations"
end

function FirepitMacro:run()
    if self.state == "initial" then
    elseif self.state == "awaiting_locations" then
        local locations = self.collector:run()
        if locations then
            self.firepit_managers = {}
            for i, location in ipairs(locations) do
                local manager = FirepitManager { firepit_screen_location = location, id = i, window_manager = self.window_manager, config = self.config }
                table.insert(self.firepit_managers, manager)
            end
            self.state = "firepits_selected"
            self.locations = locations
        end
    elseif self.state == "firepits_selected" then
        self.start_lighting = false
        local all_open = true
        for _, manager in ipairs(self.firepit_managers) do
            all_open = manager:open() and all_open
        end
        if all_open then
            self.state = "firepits_running"
        end
    elseif self.state == "firepits_running" then
        for _, manager in ipairs(self.firepit_managers) do
            manager:run(self.start_lighting)
        end
    end
    return JobRunning {}
end

ManualLocationCollector = class { class_name = "ManualLocationCollector" }
function ManualLocationCollector:init(o)
    self.selected_locations = {}
    self.selection_box_size = o.selection_box_size
    self.exit = false
    self.shift_has_been_released = true
end

function ManualLocationCollector:run()
    if not lsShiftHeld() then
        self.shift_has_been_released = true
    end
    if lsShiftHeld() and self.shift_has_been_released then
        self.shift_has_been_released = false
        local mouse_x, mouse_y = srMousePos()
        local point = { x = mouse_x, y = mouse_y }
        if self:not_close_to_existing(point) then
            table.insert(self.selected_locations, point)
            self.last_point_rejected = false
        else
            self.last_point_rejected = point
        end
    end
    if not self.exit then
        return false
    else
        return self.selected_locations
    end
end

function ManualLocationCollector:should_exit()
    self.exit = true
end
function ManualLocationCollector:reset()
    self.selected_locations = {}
end

function ManualLocationCollector:not_close_to_existing(point)
    for _, existing in ipairs(self.selected_locations) do
        if distance(existing, point) < 30 then
            return false
        end
    end
    return true
end

function distance(a, b)
    return math.sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y))
end
