FirepitWindow = class { class_name = "FirepitWindow" }
function FirepitWindow:init(click_location, window_manager, config)
    self.click_location = click_location
    self.initial_width = 400
    self.initial_height = 200
    self.open_verification_image = "lime_janitor/this_is_a_firepit.png"
    self.window_manager = window_manager
    self.config = config
    self.added_limestone = false
end
function FirepitWindow:set_location(loc)
    self.x = loc.x
    self.y = loc.y
end
function FirepitWindow:fuel_and_check_ready_to_light()
    if self.config.load_limestone and not self.added_limestone then
        local adding_limestone = self.window_manager:click_button_if_present(self, "lime_janitor/add_some_limestone.png")
        if adding_limestone then
            srKeyEvent(9);
            lsSleep(200)
            srKeyEvent(6);
            lsSleep(200)
            local found = false
            for i = 1, 5 do
                found = self.window_manager:click_button_if_present("lime_janitor/ok_add_limestone.png")
                if found then
                    self.added_limestone = true
                    break
                end
            end
            if not found then
                return false
            end
        end
    end
    self.window_manager:click_button_if_present(self, "lime_janitor/place_wood.png")
    self.window_manager:click_button_if_present(self, "lime_janitor/place_tinder.png")
    self:refresh()
    return self.window_manager:wait_for_button(self, "lime_janitor/strike_flint.png")
end

function FirepitWindow:light_fire()
    return self.window_manager:retry_clicking_popup_triggering_button(self, "lime_janitor/strike_flint.png")
end

function FirepitWindow:close()
    return self.window_manager:close(self)
end
function FirepitWindow:verify_lit()
    return self.window_manager:verify_window_has_image {
        window = self,
        image = "lime_janitor/stoke.png"
    }
end
function FirepitWindow:smouldering()
    return self.window_manager:verify_window_has_image {
        window = self,
        image = "lime_janitor/smouldering.png"
    }
end
function FirepitWindow:stoke()
    self.added_limestone = false
    return self.window_manager:click_button_if_present(self, "lime_janitor/stoke.png")
end
function FirepitWindow:refresh()
    return self.window_manager:click_button_if_present(self, "lime_janitor/this_is_a_firepit.png")
end
