dofile("lime_janitor/util/vector.inc")
-- Simple immutable box class
Box = class{class_name="Box"}
function Box:init(top_left, width, height)
    assert(top_left:is_a(Vector), "top_left given to Box must be a vector and not nill")
    assert(type(width) == "number" or width:is_a(InfiniteNumber), "width must be number and not nil")
    assert(type(height) == "number" or height:is_a(InfiniteNumber), "height must be number and not nil")
    self.top_left = top_left
    self.x = top_left.x
    self.y = top_left.y
    self.z = top_left.z
    self.width = width
    self.height = height
end


function Box:__tostring()
    return "Box{top_left=" .. tostring(self.top_left) .. ", width=" .. self.width .. ", height=" .. self.height .. "}"
end

