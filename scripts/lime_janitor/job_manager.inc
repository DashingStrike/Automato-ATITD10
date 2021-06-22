JobManager = class { class_name = "JobManager" }
function JobManager:init()
    self.jobs = {}
    self.job_times = {}
    self.exit = false
end

function JobManager:submit(o)
    table.insert(self.jobs, o)
end

function JobManager:run()
    while not self.exit do
        srReadScreen()
        checkBreak()
        local i = 1
        local length = #self.jobs
        local to_delete = {}
        local any_deleted = false
        while i <= length do
            local job = self.jobs[i]
            local start = lsGetTimer()
            local result = job.job:run()
            local time_taken = (lsGetTimer() - start)
            self.job_times[job] = self.job_times[job] or {time=0, count=0, last_run = start, total_latency = 0}
            self.job_times[job].count = self.job_times[job].count + 1
            self.job_times[job].time = self.job_times[job].time + time_taken
            self.job_times[job].total_latency = self.job_times[job].total_latency + (start - self.job_times[job].last_run)
            self.job_times[job].last_run = lsGetTimer()
            if time_taken > 450 then
                self.jobs[i].lagging = true
            else
                self.jobs[i].lagging = false
            end
            if not result then
                print(debug.traceback())
                error("Job failed to return a result")
            end
            if result:is_a(JobSucceeded) then
                to_delete[job] = true
                any_deleted = true
            elseif result:is_a(JobFailed) then
                to_delete[job] = true
                any_deleted = true
            elseif not result then
                error("Should have returned a job status code?")
            end
            i = i + 1
        end
        if any_deleted then
            local new_jobs = {}
            for k, v in pairs(self.jobs) do
                if not to_delete[v] then
                    table.insert(new_jobs, v)
                end
            end
            self.jobs = new_jobs
        end
    end
end

function JobManager:should_exit()
    self.exit = true
end

JobStatus = class { class_name = "JobStatus" }

JobSucceeded = class { class_name = "JobSucceeded", base = JobStatus }
function JobSucceeded:init(values)
    self.values = values
end
JobFailed = class { class_name = "JobSucceeded", base = JobStatus }
JobRunning = class { class_name = "JobRunning", base = JobStatus }

