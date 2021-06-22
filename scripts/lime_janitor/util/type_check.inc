
function check_attributes(attributes, o)
    if o == nil then
        print(debug.traceback())
        error("Must pass an argument object")
    end

    for name, spec in pairs(attributes) do
        if type(spec) == "string" then
            check_object(o, name, spec, false)
        elseif type(spec) == "table" then
            if spec.is_a then
               check_object(o, name, spec, false)
            elseif spec.type then
                check_object(o, name, spec.type, spec.optional)
            elseif not spec.optional or o[name] then
                check_attributes(spec, o[name])
            end
        end
    end
end

function check_object(o, attribute, argument_type, optional)
    if o == nil then
        if not optional then
            print(debug.traceback())
            error("Must pass an argument object")
        end
    elseif o[attribute] == nil then
        if not optional then
            print("Missing parameter " .. attribute)
            print(debug.traceback())
            print_table(o)
            error("Missing parameter " .. attribute)
        end
    elseif argument_type and type(argument_type) == "table" then
        if not o[attribute]:is_a(argument_type) then
            print("Parameter " .. attribute .. " must of argument_type " .. argument_type.class_name .. " instead it is " .. (o[attribute].class_name or type(argument_type)) .. " - " .. tostring(o[attribute]))
            print(debug.traceback())
            error("Parameter " .. attribute .. " must of argument_type " .. argument_type.class_name .. " instead it is " .. (o[attribute].class_name or type(argument_type)) .. " - " .. tostring(o[attribute]))
        end
    elseif argument_type and type(o[attribute]) ~= argument_type then
        print(debug.traceback())
        error("Parameter " .. attribute .. " must of argument_type " .. argument_type .. " instead it is " .. tostring(o[attribute]) .. " and of argument_type " .. type(o[attribute]))
    end
end
function check(argument, argument_type)
    if argument == nil then
        print(debug.traceback())
        error("Missing parameter " .. tostring(argument))
    elseif argument_type and type(argument_type) == "table"  then
        if not argument.is_a or not argument:is_a(argument_type) then
            print(debug.traceback())
            error("Parameter must be of type " .. argument_type.class_name .. " instead it is " .. (argument.class_name or type(argument)) .. " - " .. tostring(argument))
        end
    elseif argument_type and type(argument) ~= argument_type then
        print(debug.traceback())
        error("Parameter " .. tostring(argument) .. " must of argument_type " .. argument_type .. " instead it is " .. tostring(argument) .. " and of argument_type " .. type(argument))
    end
end
