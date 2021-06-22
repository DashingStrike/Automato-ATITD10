function string:trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function table.join(table, joiner)
    local result = false
    for _, value in ipairs(table) do
        if not result then
        result = value
        else
            result = result .. joiner .. value
        end
    end
    return result
end
function string:split(inSplitPattern, outResults)
    if not outResults then
        outResults = { }
    end
    local theStart = 1
    local theSplitStart, theSplitEnd = string.find(self, inSplitPattern, theStart)
    while theSplitStart do
        table.insert(outResults, string.sub(self, theStart, theSplitStart - 1))
        theStart = theSplitEnd + 1
        theSplitStart, theSplitEnd = string.find(self, inSplitPattern, theStart)
    end
    table.insert(outResults, string.sub(self, theStart))
    return outResults
end