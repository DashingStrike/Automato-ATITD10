
CarveTinder = class { class_name = "CarveTinder" }
function CarveTinder:init()
    self.last_run = 0
end


function CarveTinder:run()
    if (lsGetTimer() - self.last_run )>20000 then
        self.last_run = lsGetTimer()
        local stats = srFindImage("AllStats-Black.png");
        if stats then
            local carve = srFindImage("lime_janitor/carve_tinder.png");
            if carve then
                safeClick(carve[0], carve[1])
            end
            local carve_error = srFindImage("lime_janitor/carve_error.png");
            if carve_error then
                local carve_error_ok = srFindImage("lime_janitor/carve_error_ok.png");
                if carve_error_ok then
                    lsSleep(100)
                    safeClick(carve_error_ok[0], carve_error_ok[1])
                    lsSleep(100)
                end
                return JobFailed{}
            end
        end
    end
    return JobRunning{}
end
