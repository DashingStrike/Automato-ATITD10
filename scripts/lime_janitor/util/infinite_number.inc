dofile("lime_janitor/util/type_check.inc")
InfiniteNumber = class{class_name="InfiniteNumber"}

function InfiniteNumber:init(o)
    self.number = o.number
    self.infinite = o.infinite
end

function InfiniteNumber:__add(o)
    if type(o) == "number" then
        if not self.infinite then
            return InfiniteNumber { number = self.number + o }
        else
            return InfiniteNumber { infinite = true }
        end
    elseif o:is_a(InfiniteNumber) then
        if self.infinite or o.infinite then
            return InfiniteNumber { infinite = true }
        else
            return InfiniteNumber { number = self.number + o.number }
        end
    else
        error("Cannot add " .. type(o) .. " to an infinite number")
    end
end

function InfiniteNumber:__sub(o)
    if type(o) == "number" then
        if not self.infinite then
            return InfiniteNumber { number = self.number - o }
        else
            return InfiniteNumber { infinite = true }
        end
    elseif o:is_a(InfiniteNumber) then
        if self.infinite or o.infinite then
            return InfiniteNumber { infinite = true }
        else
            return InfiniteNumber { number = self.number - o.number }
        end
    else
        error("Cannot sub " .. type(o) .. " to an infinite number")
    end
end

function InfiniteNumber:__div(o)
    if type(o) == "number" then
        if not self.infinite then
            return InfiniteNumber { number = self.number / o }
        else
            return InfiniteNumber { infinite = true }
        end
    elseif o:is_a(InfiniteNumber) then
        if self.infinite or o.infinite then
            return InfiniteNumber { infinite = true }
        else
            return InfiniteNumber { number = self.number / o.number }
        end
    else
        error("Cannot div " .. type(o) .. " to an infinite number")
    end
end

function InfiniteNumber:__mul(o)
    if type(o) == "number" then
        if not self.infinite then
            return InfiniteNumber { number = self.number * o }
        else
            return InfiniteNumber { infinite = true }
        end
    elseif o:is_a(InfiniteNumber) then
        if self.infinite or o.infinite then
            return InfiniteNumber { infinite = true }
        else
            return InfiniteNumber { number = self.number * o.number }
        end
    else
        error("Cannot mul " .. type(o) .. " to an infinite number")
    end
end

function InfiniteNumber:__eq(o)
    if type(o) == "number" then
        if not self.infinite then
            return  self.number == o
        else
            return false
        end
    elseif o:is_a(InfiniteNumber) then
        if self.infinite and o.infinite then
            return true
        elseif self.infinte or o.infinite then
            return false
        else
            return self.number == o.number
        end
    else
        error("Cannot eq " .. type(o) .. " to an infinite number")
    end
end

function InfiniteNumber:__lt(o)
    if type(o) == "number" then
        if not self.infinite then
            return  self.number < o
        else
            return false
        end
    elseif o:is_a(InfiniteNumber) then
        print(debug.traceback())
        if self.infinite and o.infinite then
            return false
        elseif self.infinte and not o.infinite then
            return false
        elseif not self.infinte and o.infinite then
            return true
        else
            return self.number < o.number
        end
    else
        error("Cannot lt " .. type(o) .. " to an infinite number")
    end
end

function InfiniteNumber:__le(o)
    if type(o) == "number" then
        if not self.infinite then
            return  self.number <= o
        else
            return false
        end
    elseif o:is_a(InfiniteNumber) then
        if self.infinite and o.infinite then
            return true
        elseif self.infinte and not o.infinite then
            return false
        elseif not self.infinte and o.infinite then
            return true
        else
            return self.number <= o.number
        end
    else
        error("Cannot le " .. type(o) .. " to an infinite number")
    end
end

function InfiniteNumber:__tostring()
    return "InfiniteNumber(infinite=" .. tostring(self.infinite) .. ", number=" .. tostring(self.number) .. ")"
end

