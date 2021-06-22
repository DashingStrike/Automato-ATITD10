dofile("common.inc")
dofile("settings.inc")
dofile("screen_reader_common.inc")
dofile("lime_janitor/util/io.inc");

FireWatcherLogger = class { class_name = "FireWatcherLogger" }
function FireWatcherLogger:init(id, config)
    self.id = id
    self.events = {}
    self.last_update = lsGetTimer()
    self.start_date_time = self.last_update
    self.last_output = 0
    self.config = config
    table.insert(cleanups, self)
end

function FireWatcherLogger:log_event(e)
    local now = lsGetTimer()
    e.time = now
    local current_event = #self.events > 0 and self.events[#self.events]

    local latency = now - self.last_update
    self.last_update = now
    if e.name == "read_hue" then
        local range
        local middle_hue = math.floor(self.config.stoke_hue / 2)
        if e.hue >= 0 and e.hue <= middle_hue then
            range = "0-" .. middle_hue
        elseif e.hue > middle_hue and e.hue <= self.config.stoke_hue then
            range = middle_hue .. "-" .. self.config.stoke_hue
        elseif e.hue > self.config.stoke_hue then
            range = self.config.stoke_hue .. "+"
        elseif e.hue == 0 then
            range = "0"
        else
            range = "error"
        end

        local start_new_range = not current_event
        if current_event then
            if current_event.range == range then
                current_event.total_hue = current_event.total_hue + e.hue
                if current_event.max_hue < e.hue then
                    current_event.max_hue = e.hue
                end
            else
                current_event.end_time = e.time
                start_new_range = true
            end
        end
        if start_new_range then
            table.insert(self.events, { max_hue=e.hue, max_lat=0, died = false, complete = false, merries = {}, stokes = {}, range = range, start_time = e.time, count = 0, total_hue = e.hue, total_latency = 0 })
        end
    end
    current_event = #self.events > 0 and self.events[#self.events]
    if current_event then
        current_event.count = current_event.count + 1
        current_event.total_latency = current_event.total_latency + latency
        if current_event.max_lat > latency then
            current_event.max_lat = latency
        end
        if e.name == "stoke" then
            table.insert(current_event.stokes, e)
        elseif e.name == "died" then
            current_event.end_time = e.time
            current_event.died_time = e.time
            current_event.died = true
        elseif e.name == "complete" then
            current_event.complete_time = e.time
            current_event.complete = true
        elseif e.name == "merry" then
            table.insert(current_event.merries, e)
        end
    end
    self.last_output = self.last_output + 1
    if self.last_output < 50 then
        self:cleanup()
        self.last_output = 0
    end
end
function FireWatcherLogger:cleanup()
    if #self.events > 0 and self.config.output_logs then
        local previous_runs = readSetting("previous_runs", ""):split(",")
        local name = "firepit_ " .. self.id  .. "_log_" .. self.start_date_time .. ".txt"
        print("Outputting log for " .. name)
        table.insert(previous_runs, name)
        local found = false
        for _, p in ipairs(previous_runs) do
            if p == name then
                found = true
                break
            end

        end
        if not found then
            writeSetting("previous_runs", table.join(previous_runs, ","))
        end
        serialize(self.events, name)
    end
end

FireWatcher = class { class_name = "FireWatcher" }
function FireWatcher:init(position_to_watch, size, config, logger)
    self.logger = logger
    self.position_to_watch = position_to_watch
    self.size = size
    self.moving_averages = {}
    self.stoke_time = 0
    self.can_stoke = false
    self.start_time = 0
    self.stokes = 0
    self.events = {}
    self.config = config
    self.time_to_run = config.time_to_run or 1000 * 60 * 65
end
function FireWatcher:watch()
    if self.start_time == 0 then
        self.start_time = lsGetTimer()
        self.stoke_time = self.start_time - math.floor(self.config.stoke_time / 2)
        self.logger:log_event { name = "start" }
    end
    local total_time = (lsGetTimer() - self.start_time)
    if total_time > self.time_to_run then
        self.logger:log_event { name = "complete" }
        return "complete"
    end
    self.avg = self:getAverageHue(self.position_to_watch)
    self.logger:log_event { name = "read_hue", hue = self.avg }
    local time_since_last_stoke = lsGetTimer() - self.stoke_time
    local stoke_time_passed = (time_since_last_stoke) > self.config.stoke_time

    if self.avg > self.config.stoke_hue and self.can_stoke and stoke_time_passed then
        self.logger:log_event { name = "stoke" }
        self.stoke_time = lsGetTimer()
        self.stokes = self.stokes + 1
        self.can_stoke = false
        return "stoke"
    elseif self.avg < self.config.merry_hue and not self.can_stoke and stoke_time_passed then
        self.logger:log_event { name = "merry" }
        self.can_stoke = true
        return "merry"
    end
    if time_since_last_stoke > 1000 * 60 * 2 then
        self.logger:log_event { name = "died" }
        return "died"
    end
    return "continue"
end

function FireWatcher:getAverageHue()
    local search_size = self.config.firepit_box_size
    local total_bottom = 0
    for x = -search_size, search_size do
        for y = -search_size, search_size do
            local pixel = srReadPixelFromBuffer(self.position_to_watch.x + x, self.position_to_watch.y + y)
            local hue = getHue(pixel)
            if hue <= 2 then
                total_bottom = total_bottom + 1
            end
        end
    end
    local total_pixels = (search_size * 2 + 1) ^ 2
    return self:average((total_bottom / total_pixels) * 100)
end

table.sum = function(list)
    return table.reduce(
            list,
            function(a, b)
                return a + b
            end,
            0
    )
end
function FireWatcher:average(n)
    local t = self.moving_averages
    if #t == self.config.moving_average_size then
        table.remove(t, 1)
    end
    t[#t + 1] = n
    return table.sum(t) / #t
end

table.reduce = function(list, fn, initial)
    local acc = initial
    for k, v in ipairs(list) do
        if 1 == k then
            acc = v
        else
            acc = fn(acc, v)
        end
    end
    return acc
end

function getHue(color)
    local rgb = parseColor(color)
    local hue, max, min = 0, 0, 10
    local max_i = -1
    for i = 0, 2 do
        rgb[i] = rgb[i] / 255
        if rgb[i] > max then
            max = rgb[i]
            max_i = i
        end
        if rgb[i] < min then
            min = rgb[i]
        end
    end

    local div = max - min
    if max_i == 0 then
        hue = calcHue(0, rgb[1], rgb[2], div)
    elseif max_i == 1 then
        hue = calcHue(2, rgb[2], rgb[0], div)
    else
        hue = calcHue(4, rgb[0], rgb[1], div)
    end

    return math.floor(hue + 0.5)
end

function calcHue(off, a, b, div)
    local sub = a - b
    local hue = off + ((sub == 0 and div == 0) and 0 or sub / div)
    hue = (hue * 60)
    if hue < 0 then
        hue = hue + 360
    end
    return hue
end
