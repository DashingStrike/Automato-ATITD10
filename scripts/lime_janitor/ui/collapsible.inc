dofile("lime_janitor/util/class.inc")
dofile("lime_janitor/util/vector.inc")
dofile("lime_janitor/ui/colours.inc")
dofile("lime_janitor/util/ordered_pairs.inc")
dofile("common.inc")


Collapsible = class {
    class_name = "Collapsible",
    attributes = {
        key = "string",
        title = "string",
        expanded = "table"
    }
}

Collapsible.values = {}

function Collapsible:init(o)
    self.key = o.key
    self.title = o.title
    self.expanded = o.expanded
    self.open = Collapsible.values[self.key]
end

function Collapsible:render(render_box)
    if self.open then
        return Column({
            Row({
                Text(self.title, GREEN), Button {
                    text = "-",
                    on_pressed = function()
                        Collapsible.values[self.key] = false
                        self.open = false
                    end
                },
            }, { child_padding = 5 }),
            Divider(),
            self.expanded
        }, { child_padding = 5 })
    else
        return Column({
            Row({
                Text(self.title, GREEN), Button {
                    text = "+",
                    on_pressed = function()
                        Collapsible.values[self.key] = true
                        self.open = true
                    end
                },
            }, { child_padding = 5 }),
            Divider()
        }, { child_padding = 5 })
    end
end
