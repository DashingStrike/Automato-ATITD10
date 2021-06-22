dofile("lime_janitor/util/type_check.inc")
-- Simple immutable vector class
Vector = class{class_name="Vector"}

function Vector:init(x,y,z)
    check(x, "number")
    check(y, "number")
    check(z, "number")
    self.x = x
    self.y = y
    self.z = z
end

function Vector:__add(vector)
    return Vector( self.x + vector.x, self.y + vector.y, self.z + vector.z )
end

function Vector:__sub(vector)
    return Vector(self.x - vector.x, self.y - vector.y, self.z - vector.z)
end

function Vector:__div(divisor)
    return Vector(self.x / divisor, self.y / divisor, self.z / divisor)
end

function Vector:__mul(multiplicand)
    return Vector(self.x * multiplicand, self.y * multiplicand, self.z * multiplicand)
end


function Vector:length()
    return math.sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2)
end

function Vector:normalize()
    return self / self:length()
end

function Vector:__tostring()
    return "Vector(" .. self.x .. ", " .. self.y .. ", " .. self.z .. ")"
end

