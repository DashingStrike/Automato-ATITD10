
dofile("lime_janitor/util/ordered_pairs.inc")

function writeCsvFileTo(filename, table)
    local csv = createCSV(table)
    serialize(csv, filename .. ".txt", true)
    serialize(table, filename .. "_lua_table.txt")
end


function createCSV(table)
    local csv = ""
    for index, row in ipairs(table) do
        for index, cell in ipairs(row) do
            csv = csv .. cell .. ","
        end
        csv = csv .. "\n"
    end
    return csv
end

-- Hacky modified serialize.inc
function serialize(o, filename, append)
    local outputFile = io.open("data/" .. filename, append and "a" or "w");
    if type(o) == "table" then outputFile:write("return\n"); end
    serializeInternal(o, outputFile);
    outputFile:close();
end

function deserialize(filename)
    filename = "data/" .. filename

    if (pcall(dofile, filename)) then
        return true, dofile(filename);
    else
        return false, nil;
    end
end


function serializeInternal(o, outputFile, indentStr, format_string)
    if (not indentStr) then
        indentStr = "";
    end
    if type(o) == "number" then
        outputFile:write(o);
    elseif type(o) == "string" then
        if format_string then
            o = string.format("%q", o)
        end
        outputFile:write(o);
    elseif type(o) == "boolean" then
        if (o) then
            outputFile:write("true");
        else
            outputFile:write("false");
        end
    elseif type(o) == "table" then
        outputFile:write(indentStr .. "{\n");
        if o.serialize then
            o = o.serialize(o)
        end
        if o.class_name then
            serializeKeyValue(outputFile, indentStr, "class_name", o.class_name)
        end

        local ignore = o.ignore_for_serialization or {}

        for k, v in pairs(o) do
            if not ignore[k] then
                serializeKeyValue(outputFile, indentStr, k, v)
            end
        end
        outputFile:write(indentStr .. "}\n");
    else
        print(debug.traceback())
        error("cannot serialize a " .. type(o));
    end
    end

function serializeKeyValue(outputFile, indentStr, k,v)
    if (type(k) == "number") then
        outputFile:write(indentStr .. "\t[" .. k .. "] = ");
    else
        outputFile:write(indentStr .. "\t[" .. string.format("%q", k) .. "] = ");
    end
    if (type(v) == "table") then
        outputFile:write("\n");
    end
    serializeInternal(v, outputFile, indentStr .. "\t", true);
    if (type(v) == "table") then
        outputFile:write(indentStr .. "\t,\n");
    else
        outputFile:write(",\n");
    end
end

