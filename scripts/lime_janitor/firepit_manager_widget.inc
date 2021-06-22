FirepitManagerWidget = class { class_name = "FirepitManagerWidget" }
function FirepitManagerWidget:init(manager)
    self.manager = manager
end

function FirepitManagerWidget:render(render_box)
    if self.manager.state == "fire_lit" and self.manager.fire_watcher then
        return self:fire_lit_overview()
    elseif self.manager.state == "failed" or self.manager.state == "complete" then
        return Button { text = "Restart Firepit " .. self.manager.id, on_pressed=function () self.manager:restart() end}
    else
        return Text("Firepit " .. self.manager.id .. " : " .. self.manager.state .. (self.manager.error and (": " .. self.manager.error) or ""), self.manager.error and RED or WHITE)
    end
end

function FirepitManagerWidget:fire_lit_overview()
    local total_time = round((lsGetTimer() - self.manager.fire_watcher.start_time) / 1000, 0)
    local average = round(self.manager.fire_watcher.avg or 0, 0)
    local stoke_time = round((lsGetTimer() - self.manager.fire_watcher.stoke_time) / 1000, 0)
    return Column({ Text("Firepit " .. self.manager.id, GREEN),
                    Text("H:" .. average .. ", S:" .. stoke_time .. "s" .. ", C:" .. self.manager.fire_watcher.stokes .. ", T:" .. total_time .. "s"),
    }, { child_padding = 5 })
end

