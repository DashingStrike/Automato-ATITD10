DiskCache = class { class_name = "DiskCache" }

function DiskCache:init(name)
    self.name = name
    local success, result = deserialize(name)
    self.memory = success and result or {}
end

function DiskCache:get(key, miss)
    local redownload = {
        ["https://atitd.wiki/tale9/Pyrolysis"] = true,
    }
    if not self.memory[key] or redownload[key] then
        self.memory[key] = miss()
        serialize(self.memory, self.name)
    end
    return self.memory[key]
end
