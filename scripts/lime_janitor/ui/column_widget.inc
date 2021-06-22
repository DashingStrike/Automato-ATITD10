dofile("lime_janitor/util/class.inc")
dofile("lime_janitor/util/vector.inc")
dofile("lime_janitor/ui/render_result.inc")
dofile("lime_janitor/util/box.inc")

Column = class{class_name="Column"}

function Column:init(children, o)
    self.children = children
    self.child_padding = o and o.child_padding
end

function Column:render(render_box)
    local next_render_box = render_box
    local max_width = 0
    local i = 1
    while i <= #self.children do
        local child=self.children[i]
        local child_render_result
        if self.child_padding then
            child_render_result = Padding { all = self.child_padding, child = child }:render(next_render_box)
        else
            child_render_result = child:render(next_render_box)
        end
        local child_height = child_render_result.box_taken_by_child.height
        local child_width = child_render_result.box_taken_by_child.width
        if child_width > max_width then
            max_width = child_width
        end
        next_render_box = Box(next_render_box.top_left + Vector(0, child_height, 0), render_box.width, render_box.height - child_height)
        i = i + 1
    end
    local height = next_render_box.y - render_box.y
    return RenderResult(Box(render_box.top_left, max_width, height))
end

