
dofile("lime_janitor/util/class.inc")

RenderResult = class{class_name="RenderResult"}
function RenderResult:init(box_taken_by_child)
    assert(box_taken_by_child:is_a(Box), "box_taken_by_child RenderResult constructor parameter must be a Box")
    self.box_taken_by_child = box_taken_by_child
end

function RenderResult:__tostring()
    return "RenderResult{box_taken_by_child=" .. tostring(self.box_taken_by_child) .. "}"
end

