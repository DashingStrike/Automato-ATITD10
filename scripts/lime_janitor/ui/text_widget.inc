dofile("lime_janitor/util/class.inc")
dofile("lime_janitor/util/vector.inc")
dofile("lime_janitor/util/box.inc")
dofile("lime_janitor/ui/render_result.inc")
dofile("lime_janitor/ui/colours.inc")

Text = class { class_name = "Text" }

function Text:init(text, colour)
    assert(type(text) == "string", "Text must be a string and not null")
    self.text = text
    self.colour = colour or WHITE
end

function Text:render(render_box)
    local height = 16
    local text_width = lsPrint(0, -100, render_box.z, 1, 1, self.colour, self.text)
    if render_box.width < text_width then
        height = lsPrintWrapped(render_box.x, render_box.y, render_box.z, render_box.width, 0.6, 0.6, self.colour, self.text)
    else
        lsPrint(render_box.x, render_box.y, render_box.z, 1, 1, self.colour, self.text)
    end
    local width = math.min(text_width, render_box.width)
    if render_box.height < height then
        lsPrintln("Text overflowed height")
    end
    return RenderResult(Box(render_box.top_left, width, height))
end

