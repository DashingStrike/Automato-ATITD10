dofile("lime_janitor/util/class.inc")
dofile("lime_janitor/util/vector.inc")
dofile("lime_janitor/util/box.inc")
dofile("lime_janitor/util/type_check.inc")
dofile("lime_janitor/ui/render_result.inc")
dofile("lime_janitor/ui/colours.inc")

Dropdown = class{class_name="Dropdown",
attributes = {
    key = "string",
    initial_index = "number",
    values = "table",
    on_value = {type = "function", optional=true}
} }
Dropdown.cached_indexes = {}

function Dropdown:init(o)
    self.key = o.key
    self.index = Dropdown.cached_indexes[o.key] or o.initial_index
    self.values = o.values
    self.on_value = o.on_value
end

function Dropdown:render(render_box)
    if render_box.height < 16 then
        error("Dropdown overflowed height")
    end
    self.index = lsDropdown(self.key, render_box.x, render_box.y, render_box.z+1, render_box.width, self.index, self.values)
    self.value = self.values[self.index]
    if self.value and self.on_value then
        self.on_value(self.value)
    end
    Dropdown.cached_indexes[self.key] = self.index
    return RenderResult(Box(render_box.top_left, render_box.width, 16))
end

