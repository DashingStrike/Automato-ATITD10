dofile("lime_janitor/util/class.inc")
dofile("lime_janitor/util/vector.inc")
dofile("lime_janitor/ui/render_result.inc")
dofile("lime_janitor/util/box.inc")

Grid = class{class_name="Grid"}

function Grid:init(children, o)
    self.children = children
    self.child_padding = o and o.child_padding
end

function Grid:render(render_box)
    local next_render_box = render_box
    local i = 1
    local grid_size = 0
    local grid_width = 0
    local grid_height = 0
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
        if grid_size == 0 then
            grid_size = math.floor(render_box.width / child_width)
            grid_width = child_width
            grid_height = child_height
        end
        local row = math.floor(i / grid_size)
        local position = i % grid_size
        next_render_box = Box(render_box.top_left + Vector(position*grid_width, row*grid_height, 0), grid_width, grid_height)
        i = i + 1
    end
    local height = next_render_box.y - render_box.y
    return RenderResult(Box(render_box.top_left, grid_width*grid_size, height))
end

