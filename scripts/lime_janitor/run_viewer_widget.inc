dofile("lime_janitor/ui/divider.inc")
dofile("lime_janitor/util/string.inc")
dofile("lime_janitor/ui/dropdown_widget.inc")
RunViewerWidget = class { class_name = "RunViewerWidget" }
function RunViewerWidget:init(manager)
    self.manager = manager
    self.event_log = false
end

function RunViewerWidget:render(render_box)
    if not self.filename then
        local previous_runs = readSetting("previous_runs", ""):split(",")
        local widgets = {
            Text("Enter filename :"),
            EditBox { key = "firepit_log_file_name", initial_text = "",
                      on_text = function(enter_pressed, text)
                          self.edit_filename = text
                      end
            },
            Button { text = "Open manually entered file", on_pressed = function()
                if self.edit_filename then
                    self.filename = self.edit_filename
                end

            end }
        }
        if #previous_runs > 0 then
            table.insert(widgets,
                    Dropdown {
                        key = "firepit_log_names_dropdown",
                        initial_index = 1,
                        values = previous_runs,
                        on_value = function(value)
                            self.dropdown_name = value
                        end
                    })
            table.insert(widgets,
                    Button { text = "Open dropdown file", on_pressed = function()
                        if self.dropdown_name then
                            self.filename = self.dropdown_name
                        end

                    end }

            )
        end
        return Column(widgets, { child_padding = 10 })
    else
        if not self.events then
            local success, new_events = deserialize(self.filename)
            local previous_runs = readSetting("previous_runs", ""):split(",")
            local found = false
            for _, prev in ipairs(previous_runs) do
                if prev == self.filename then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(previous_runs, self.filename)
                writeSetting("previous_runs", table.join(previous_runs,","))
            end
            if success then
                self.events = new_events
            else
                self.events = nil
            end
        end
        if self.events then
            if not self.cached_widgets then
                self.cached_widgets = {
                    Text("Events:"),
                    Button { text = "Reset", on_pressed = function()
                        self.filename = nil
                        self.cached_widgets = nil
                    end }
                }
                local first_start_time = self.events[1].start_time

                for _, e in ipairs(self.events) do
                    table.insert(self.cached_widgets, Divider{})
                    table.insert(self.cached_widgets, Text("Start: " .. round((e.start_time - first_start_time)/1000,0)))
                    table.insert(self.cached_widgets, Text("Range: " .. e.range))
                    table.insert(self.cached_widgets, Text(#e.stokes > 0 and "Stoked" or "Not Stoked", #e.stokes > 0 and GREEN and RED))
                    table.insert(self.cached_widgets, Text(#e.merries > 0 and "Merried" or "Not Merried"))
                    local avg_latency = e.total_latency / e.count
                    table.insert(self.cached_widgets, Text("Latency: " .. avg_latency))
                    local avg_hue = e.total_hue / e.count
                    table.insert(self.cached_widgets, Text("Hue: " .. avg_hue))
                    if e.died then
                        table.insert(self.cached_widgets, Text("DIED", RED))
                    end
                    if e.complete then
                        table.insert(self.cached_widgets, Text("COMPLETE", GREEN))
                    end
                    if e.end_time then
                        table.insert(self.cached_widgets, Text("End : " .. round((e.end_time-first_start_time)/1000, 0 )))
                    end
                end
            end
            return Column(self.cached_widgets, { child_padding = 5 })
        else
            local widgets = {
                Text("Failed to load event file " .. self.filename),
                Button { text = "Try again", on_pressed = function()
                    self.filename = nil
                end }
            }
            return Column(widgets, { child_padding = 5 })
        end
    end
end

