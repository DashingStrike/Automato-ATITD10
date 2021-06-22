dofile("lime_janitor/util/class.inc")
dofile("lime_janitor/util/vector.inc")
dofile("lime_janitor/util/box.inc")
dofile("lime_janitor/ui/render_result.inc")


Padding = class{class_name="Padding"}

function Padding:init(o)
    assert(type(o.all) == "number")
    assert(o.child ~= nil)
    self.all = o.all
    self.child = o.child
end

function Padding:render(render_box)
    local inner_box = Box(render_box.top_left + Vector(self.all, self.all, 0), render_box.width - self.all*2, render_box.height - self.all*2)
    if not self.child.render then
        print(debug.traceback())
    end
    local child_result = self.child:render(inner_box)
    while not child_result.box_taken_by_child do
        child_result = child_result:render(inner_box)
    end
    local box = child_result.box_taken_by_child
    return RenderResult(Box(render_box.top_left, box.width + self.all * 2, box.height + self.all * 2))
end

