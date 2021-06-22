dofile("lime_janitor/util/class.inc")
dofile("lime_janitor/util/vector.inc")
dofile("lime_janitor/util/box.inc")
dofile("lime_janitor/ui/render_result.inc")
dofile("lime_janitor/ui/colours.inc")

Divider = class{class_name="Divider"}

function Divider:init()
end

function Divider:render(render_box)
    lsDisplaySystemSprite(1, render_box.x, render_box.y, render_box.z, render_box.width, 5, WHITE)
    return RenderResult(Box(render_box.top_left, render_box.width, 5))
end

