dofile("lime_janitor/util/class.inc")
dofile("lime_janitor/util/vector.inc")
dofile("lime_janitor/util/box.inc")
dofile("lime_janitor/util/type_check.inc")
dofile("lime_janitor/ui/render_result.inc")
dofile("lime_janitor/ui/colours.inc")

Button = class{class_name="Button"}
function Button:init(o)
    check_object(o , "on_pressed" , "function")
    check_object(o , "text" , "string")
    check_object(o , "colour" , "number", true)
    self.on_pressed = o.on_pressed
    self.text = o.text
    self.colour = o.colour or WHITE
end

function Button:render(render_box)
    if render_box.height < 20 then
--        lsPrintln("Button will cause overflow in height")
    end
    if not self.size then
        self.size = Text(self.text):render(render_box).box_taken_by_child.width + 20
    end
    if render_box.width < self.size then
        self.size = self.size - 20
--        lsPrintln("Button will cause overflow in width")
    end
    local pressed = lsButtonText(render_box.x, render_box.y, render_box.z, self.size, self.colour, self.text)
    if pressed then
        self.on_pressed()
    end
    return RenderResult(Box(render_box.top_left, self.size, 20))
end
