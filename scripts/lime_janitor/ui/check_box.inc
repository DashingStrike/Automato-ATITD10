dofile("lime_janitor/util/class.inc")
dofile("lime_janitor/util/vector.inc")
dofile("lime_janitor/util/box.inc")
dofile("lime_janitor/util/type_check.inc")
dofile("lime_janitor/ui/render_result.inc")
dofile("lime_janitor/ui/colours.inc")

CheckBox = class{class_name="CheckBox"}

function CheckBox:init(o)
    self.text = o.text
    self.colour = WHITE
    self.key = o.key
    self.value = readSetting(self.key, o.value)
end

function CheckBox:render(render_box)
    if render_box.height < 16 then
        error("CheckBox overflowed height")
    end
    self.value = lsCheckBox(render_box.x, render_box.y, render_box.z, self.colour, self.text, self.value);
    writeSetting(self.key, self.value)
    return RenderResult(Box(render_box.top_left, render_box.width, 16))
end

