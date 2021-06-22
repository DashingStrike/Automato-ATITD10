dofile("lime_janitor/util/class.inc")
dofile("lime_janitor/util/vector.inc")
dofile("lime_janitor/util/box.inc")
dofile("lime_janitor/util/type_check.inc")
dofile("lime_janitor/ui/render_result.inc")
dofile("lime_janitor/ui/colours.inc")

EditBox = class{class_name="EditBox"}

function EditBox:init(o)
    check_object(o, "key", "string")
    self.key = o.key
    self.initial_text = o.initial_text
    self.on_text = o.on_text
    self.type = o.type
    self.colour = BLACK
    self.use_settings = o.use_settings
    if self.use_settings then
        self.initial_text = readSetting(self.key, self.initial_text)
    end
    if self.type and self.type == "number" then
        self.text = tonumber(self.initial_text)
    else
        self.text = self.initial_text
    end
end

function EditBox:render(render_box)
    if render_box.height < 16 then
        error("EditBox overflowed height")
    end
    local enter_pressed, text=  lsEditBox(self.key, render_box.x, render_box.y, render_box.z+1, render_box.width, 0, 1, 1, self.colour, self.initial_text or "")
    if self.use_settings then
        writeSetting(self.key, text)
    end
    if self.type and self.type == "number" then
        self.text = tonumber(text)
    else
        self.text = text
    end
    if self.on_text then
        self.on_text(enter_pressed, text)
    end
    if not self.text then
        self.colour = RED
    else
        self.colour = BLACK
    end
    return RenderResult(Box(render_box.top_left, render_box.width, 16))
end

