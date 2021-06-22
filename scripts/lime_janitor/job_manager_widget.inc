JobManagerWidget = class { class_name = "JobManagerWidget" }
function JobManagerWidget:init(job_manager)
    self.job_manager = job_manager
end

function JobManagerWidget:render(render_box)
    local jobs = { Text("Running " .. #self.job_manager.jobs.. " jobs:") }
    for i, job in ipairs(self.job_manager.jobs) do
        local name = job.name or tostring(job)
        local times = self.job_manager.job_times[job]
        local average = times.time / times.count
        local average_latency = round(times.total_latency / times.count,2)
        table.insert(jobs, Text(name .. " running for: ", GREEN))
        table.insert(jobs, Text("avg: " .. round(average,2).. "ms, total: " .. (times.time/1000).. "s, count: " .. times.count .. ", lat: " .. average_latency))
    end
    return Column(jobs, { child_padding = 5 })
end



function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end


