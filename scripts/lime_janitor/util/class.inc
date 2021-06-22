dofile("lime_janitor/util/type_check.inc")

classes = classes or {}


function subtypes(base_class)
    local subtypes = {}
    for class_name, klass in pairs(classes) do
        if klass._base and klass._base.class_name == base_class.class_name then
            table.insert(subtypes, klass.class_name)
        end
    end
    return subtypes
end

-- From http://lua-users.org/wiki/SimpleLuaClasses
function class(o)
    check_object(o, "class_name", "string")
    local base = o.base
    local c = {} -- a new class instance
    if type(base) == 'table' then
        -- our new class is a shallow copy of the base class!
        for i, v in pairs(base) do
            c[i] = v
        end
        c._base = base
    elseif base then
        error("Base type of class must be a table")
    end
    -- the class will be the metatable for all its objects,
    -- and they will look up their methods in it.
    c.__index = c

    -- expose a constructor which can be called by <classname>(<args>)
    local mt = {}
    mt.__call = function(class_tbl, ...)
        local obj = {}
        setmetatable(obj, c)
        class_tbl.wrapped_init(obj, ...)
        return obj
    end
    classes[o.class_name] = c
    c.class_name = o.class_name
    c.wrapped_init = function(self, arg_object, ...)
        check(self, "table")
        if o.attributes then
            check_attributes(o.attributes, arg_object)
        end
        if base and not self.init then
            base.wrapped_init(self, arg_object, ...)
        end
        if self.init then
            self:init(arg_object, ...)
        end
    end
    c.attributes = function(self)
        local attributes = {}
        if base then
            attributes = base.attributes(self)
        end
        if o.attributes then
            for k, v in pairs(o.attributes) do
                attributes[k] = v
            end
        end
        return attributes
    end
    c.is_a = function(self, klass)
        check(self, "table")
        check(klass, "table")
        local m = getmetatable(self)
        while m do
            if m == klass then return true end
            m = m._base
        end
        return false
    end
    c.__tostring = function(self)
        return "Instance of " .. (self.class_name or "Anonymous Class")
    end
    setmetatable(c, mt)
    return c
end

function makeReadOnly(table)
    local mt = getmetatable(table)
    if not mt then
        mt = {}
        if not table then print(debug.traceback()) end
        setmetatable(table, mt)
    end
    mt.__newindex = function(t, k, v)
        error("Attempt to update a read-only table", 2)
    end
    return table
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = deepcopy(orig_value)
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
