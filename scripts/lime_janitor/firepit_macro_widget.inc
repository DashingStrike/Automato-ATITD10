dofile("lime_janitor/firepit_manager_widget.inc")
dofile("lime_janitor/ui/check_box.inc")
FirepitMacroWidget = class { class_name = "FirepitMacroWidget" }
function FirepitMacroWidget:init(macro)
    self.macro = macro
    self.stoke_hue = EditBox { key = "stoke_hue", initial_text = 33, type = "number", use_settings = true }
    self.merry_hue = EditBox { key = "merry_hue", initial_text = 20, type = "number", use_settings = true }
    self.moving_average_size = EditBox { key = "moving_average_size", initial_text = 10, type = "number", use_settings = true }
    self.stoke_time = EditBox { key = "stoke_time", initial_text = 22000, type = "number", use_settings = true }
    self.firepit_box_size = EditBox { key = "firepit_box_size", initial_text = 20, type = "number", use_settings = true }
    self.time_to_run_edit_box = EditBox { key = "time_to_run", initial_text = 65, type = "number", use_settings = true }
    self.limestone = CheckBox { key = "limestone", value = true, text = "Auto load limestone?" }
    self.restart_on_completion = CheckBox { key = "restart_on_completion", value = true, text = "Restart on completion?" }
    self.light = CheckBox { key = "light", value = true, text = "Auto light fires?" }
    self.output_logs = CheckBox { key = "output_logs", value = true, text = "Write log files to data folder?" }
end

function concat(a, b)
    for _, x in ipairs(b) do
        table.insert(a, x)
    end
end

function FirepitMacroWidget:render(_)

    if self.macro.state == "initial" then
        local widgets = {
            Text("Minutes to run each firepit for:"),
            self.time_to_run_edit_box,
            self.limestone,
            self.restart_on_completion,
            self.light,
            self.output_logs

        }
        if not self.show_advanced_config then
            table.insert(widgets,
                    Button { text = "Advanced Config", on_pressed = function()
                        self.show_advanced_config = true
                    end })
        else
            local advanced_widgets = {
                Button { text = "Hide", colour = RED, on_pressed = function()
                    self.show_advanced_config = false
                end },
                Text("Stoke hue (stoke when the moving average of the hue of the pixels inside the firepit search box goes above this value, recommended is 30):"),
                self.stoke_hue,
                Text("Merry hue (opposite of stoke hue, reset to merry when under this value, only when a firepit goes back to merry can it be stoked again):"),
                self.merry_hue,
                Text("Moving average size (number of previous hue readings to include in the moving average, the larger the slower the macro will respond and the more smoothed out small hue spikes will be):"),
                self.moving_average_size,
                Text("How long after stoking to stop the macro from stoking again, this prevents a small dip in the hue during the bright phase triggering a restoke:"),
                self.stoke_time,
                Text("The size of the box of pixels around each firepit location to be read by the macro when calculating the firepits hue. Smaller values might speed up the macro, however if too small the window might miss the flames when they go into the bright period:"),
                self.firepit_box_size,
            }
            concat(widgets, advanced_widgets)
        end
        if self.time_to_run_edit_box.text then
            local config = {
                time_to_run = self.time_to_run_edit_box.text * 60 * 1000,
                load_limestone = self.limestone.value,
                restart = self.restart_on_completion.value,
                light = self.light.value,
                stoke_hue = self.stoke_hue.text,
                merry_hue = self.merry_hue.text,
                moving_average_size = self.moving_average_size.text,
                stoke_time = self.stoke_time.text,
                output_logs = self.output_logs.value,
                firepit_box_size = self.firepit_box_size.text,
            }
            table.insert(widgets,
                    Button { text = "Start", colour = GREEN, on_pressed = function()
                        self.macro:start(config)
                    end })
        end
        return Column(widgets, { child_padding = 5 })
    elseif self.macro.state == "awaiting_locations" then
        return ManualLocationCollectorWidget(self.macro.collector, "firepits to run!", self.macro.config.firepit_box_size * 2)
    elseif self.macro.state == "firepits_running" then
        local manager_widgets = { Text("Running " .. #self.macro.firepit_managers .. " firepits:") }
        if not self.macro.start_lighting then
            table.insert(manager_widgets, Button{text="Start lighting", on_pressed = function()
                self.macro.start_lighting = true
            end})
        end
        for _, manager in ipairs(self.macro.firepit_managers) do
            table.insert(manager_widgets, FirepitManagerWidget(manager))
        end
        return Column(manager_widgets, { child_padding = 5 })
    else
        return Text("state = " .. self.macro.state)
    end
end

ManualLocationCollectorWidget = class { class_name = "ManualLocationCollectorWidget" }
function ManualLocationCollectorWidget:init(collector, target_text, box_size)
    self.collector = collector
    self.target_text = target_text
    self.box_size = box_size
end

function ManualLocationCollectorWidget:render(_)
    local widgets = {
        Text("Press shift over " .. self.target_text),
    }
    if #self.collector.selected_locations > 0 then
        table.insert(widgets,
                Text(#self.collector.selected_locations .. " selected so far.")
        )
        table.insert(widgets,
                Button { text = "Reset", colour = RED, on_pressed = function()
                    self.collector:reset()
                end }
        )
        table.insert(widgets,
                Button { text = "Done", on_pressed = function()
                    self.collector:should_exit()
                end, colour = GREEN }
        )
        table.insert(widgets, MultiBoxScreenRenderer { locations = self.collector.selected_locations, padding = self.box_size, box_size = self.box_size })
    end
    if self.collector.last_point_rejected then
        table.insert(widgets,
                Text("Last selection was too close to an existing one, try again!", RED)
        )
    end
    return Column(widgets, { child_padding = 5 })
end

Stack = class { class_name = "Stack" }
function Stack:init(children)
    assert(#children > 0)
    self.children = children
end
function Stack:render(render_box)
    local max_width, max_height = 0, 0
    for i, child in ipairs(self.children) do
        local result = child:render(Box(Vector(render_box.top_left.x, render_box.top_left.y, render_box.top_left.z + i), render_box.width, render_box.height))
        if result.box_taken_by_child.width > max_width then
            max_width = result.box_taken_by_child.width
        end
        if result.box_taken_by_child.height > max_height then
            max_height = result.box_taken_by_child.height
        end
    end
    return RenderResult(Box(render_box.top_left, max_width, max_height))
end

MultiBoxScreenRenderer = class { class_name = "MultiBoxScreenRenderer" }
function MultiBoxScreenRenderer:init(o)
    self.box_locations = o.locations
    self.padding = o.padding
    self.box_size = o.box_size
    assert(#self.box_locations > 0)
    local first = self.box_locations[1]
    self.min_x = first.x
    self.min_y = first.y
    self.max_x = first.x
    self.max_y = first.y
    for _, location in ipairs(self.box_locations) do
        if location.x < self.min_x then
            self.min_x = location.x
        end
        if location.y < self.min_y then
            self.min_y = location.y
        end
        if location.x > self.max_x then
            self.max_x = location.x
        end
        if location.y > self.max_y then
            self.max_y = location.y
        end
    end
end
function MultiBoxScreenRenderer:render(_)
    local width = self.max_x - self.min_x + self.padding * 2
    local height = self.max_y - self.min_y + self.padding * 2

    local stack = { ScreenRenderBox { x = self.min_x - self.padding, y = self.min_y - self.padding, width = width, height = height } }

    for _, box in ipairs(self.box_locations) do
        table.insert(stack, HighlightBox { size = self.box_size, x = box.x - self.min_x + self.padding, y = box.y - self.min_y + self.padding })
    end

    return Stack(stack)
end
HighlightBox = class { class_name = "HighlightBox" }
function HighlightBox:init(o)
    self.x = o.x
    self.y = o.y
    self.size = o.size
    self.colour = o.colour or RED
end
function HighlightBox:render(render_box)
    local colour = self.colour
    lsDisplaySystemSprite(1, render_box.x + self.x, render_box.y + self.y, 1, 1, 1, colour)
    local half = math.floor(self.size / 2)
    for i = 1, self.size do
        lsDisplaySystemSprite(1, render_box.x + self.x - half + i, render_box.y + self.y - half, render_box.z, 1, 1, colour)
        lsDisplaySystemSprite(1, render_box.x + self.x - half + i, render_box.y + self.y + half, render_box.z, 1, 1, colour)
        lsDisplaySystemSprite(1, render_box.x + self.x - half, render_box.y + self.y - half + i, render_box.z, 1, 1, colour)
        lsDisplaySystemSprite(1, render_box.x + self.x + half, render_box.y + self.y - half + i, render_box.z, 1, 1, colour)
    end
    return RenderResult(Box(Vector(render_box.x + self.x - half, render_box.y + self.y - half, render_box.z), self.size, self.size))
end

ScreenRenderBox = class { class_name = "ScreenRenderBox" }
function ScreenRenderBox:init(o)
    self.x = o.x
    self.y = o.y
    self.width = o.width
    self.height = o.height
end
function ScreenRenderBox:render(render_box)
    for y = 1, self.height do
        for x = 1, self.width do
            local colour = srReadPixelFromBuffer(self.x + x, self.y + y)
            lsDisplaySystemSprite(1, render_box.x + x, render_box.y + y, render_box.z, 1, 1, colour)
        end
    end
    return RenderResult(Box(render_box.top_left, self.width, self.height))
end
