dofile("lime_janitor/util/class.inc")
dofile("lime_janitor/util/vector.inc")
dofile("lime_janitor/ui/render_result.inc")
dofile("lime_janitor/util/box.inc")

Row = class{class_name="Row"}

function Row:init(children, o)
    assert(#children > 0, "Zero length children list or nil passed to Row constructor")
    self.children = children
    self.child_padding = o and o.child_padding
end

function Row:render(render_box)
    local next_render_box = render_box
    local max_height = 0
    for i, child in ipairs(self.children) do
        local child_render_result
        if self.child_padding then
            child_render_result = Padding { all = self.child_padding, child = child }:render(next_render_box)
        else
            child_render_result = child:render(next_render_box)
        end
        local child_width = child_render_result.box_taken_by_child.width
        local child_height = child_render_result.box_taken_by_child.height
        if child_height > max_height then
            max_height = child_height
        end
        next_render_box = Box(next_render_box.top_left + Vector(child_width, 0, 0), render_box.width - child_width, render_box.height)
    end
    local width = next_render_box.x - render_box.x
    return RenderResult(Box(render_box.top_left, width, max_height))
end

