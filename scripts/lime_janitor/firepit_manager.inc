dofile("lime_janitor/firepit_window.inc")
dofile("lime_janitor/fire_watcher.inc")

FirepitManager = class { class_name = "FirepitManager" }
function FirepitManager:init(o)
    self.state = "initial"
    self.refuel_attempts = 0
    self.id = o.id
    self.screen_location = o.firepit_screen_location
    self.window_manager = o.window_manager
    self.config = o.config
end

function FirepitManager:open()
    if self.state == "initial" then
        self.window = FirepitWindow(self.screen_location, self.window_manager, self.config)
        if self.window_manager:open_verify_and_stash_window(self.window) then
            self.state = "window_opened"
        end
    end
    return self.state == "window_opened"
end

function FirepitManager:restart()
    local still_open = self.window_manager:verify_window_open_at_new_location {
        window = self.window,
        x = self.window.x,
        y = self.window.y }
    if still_open then
        self.error = nil
        self.state = "window_opened"
        self.played_error_sound = false
    else
        self.state = "missing_window"
    end
end

function FirepitManager:run(start_lighting)
    if self.state == "failed" then
        if not self.played_error_sound then
            lsPlaySound("fail.wav");
            self.played_error_sound = true
        end
    end
    if self.window:smouldering() then
        if self.fire_watcher then
            self.fire_watcher.logger:log_event{name="died"}
            self.fire_watcher.logger:cleanup()
        end
        self.error = "Firepit died"
        self.state = "failed"
    end
    if self.state == "window_opened" then
        if self.window:fuel_and_check_ready_to_light() then
            self.state = "ready_to_light"
            self.refuel_attempts = 0
        else
            if self.window:verify_lit() then
                print("Lit on first check!")
                self.refuel_attempts = 0
                self.state = "fire_lit"
            elseif self.refuel_attempts > 5 then
                self.refuel_attempts = 0
                self.state = "failed"
                print("Failed lit on first check!")
            else
                self.refuel_attempts = self.refuel_attempts + 1
            end
        end
    elseif self.state == "ready_to_light" then
        if start_lighting and self.config.light and self.window:light_fire() then
            print("Lit the fire!")
        end
        if start_lighting and self.window:verify_lit() then
            print("Fire lit!")
            self.state = "fire_lit"
        end
        if start_lighting and self.config.light and self.state ~= "fire_lit" then
            print("Failed to light fire")
            self.state = "window_opened"
            self.error = "refueling fire"
        end
    elseif self.state == "fire_lit" then
        if not self.fire_watcher then
            self.fire_watcher = FireWatcher(self.screen_location, 10, self.config, FireWatcherLogger(self.id, self.config))
        end
        local action = self.fire_watcher:watch()
        if action == "stoke" then
            self.window:stoke()
        elseif action == "merry" then
            self.window:refresh()
        elseif action == "complete" then
            lsPlaySound("Complete.wav");
            if self.config.restart then
                self.state = "window_opened"
            else
                self.state = "complete"
            end
        elseif action == "died" then
            self.error = "Firepit died"
            self.state = "failed"
        end
    end
    return JobRunning {}
end
