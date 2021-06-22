dofile("lime_janitor/util/class.inc")
dofile("lime_janitor/util/vector.inc")
dofile("lime_janitor/util/infinite_number.inc")
dofile("lime_janitor/util/box.inc")
dofile("lime_janitor/ui/render_result.inc")


ScrollArea = class{class_name="ScrollArea"}

function ScrollArea:init(o)
    assert(o.child ~= nil)
    self.child = o.child
    self.SCROLL_BAR_WIDTH = 30
end

function ScrollArea:render(render_box)
    -- Render under the plane to avoid visual glitches
    if self.show_scroll_next_frame then
        lsScrollAreaBegin("scroll_area", render_box.x, render_box.y, render_box.z-1, render_box.width, render_box.height)
    end
    local box = Box(render_box.top_left-{x=self.show_scroll_next_frame and render_box.x or 0,y=0,z=0}, render_box.width - self.SCROLL_BAR_WIDTH, InfiniteNumber{infinite = true})
    local result = self.child:render(box)
    while not result.box_taken_by_child do
        result = result:render(box)
    end
    local child_height = result.box_taken_by_child.height + 50
    if self.show_scroll_next_frame then
        lsScrollAreaEnd(child_height)
    end
    self.show_scroll_next_frame = child_height > render_box.height
    return result
end

