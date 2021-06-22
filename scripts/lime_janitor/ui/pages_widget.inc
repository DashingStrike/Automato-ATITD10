dofile("lime_janitor/util/class.inc")
dofile("lime_janitor/util/vector.inc")
dofile("lime_janitor/ui/colours.inc")
dofile("lime_janitor/util/ordered_pairs.inc")
dofile("common.inc")

PagesWidget = class { class_name = "PagesWidget" }

function PagesWidget:init(pages, starting_page, extra_buttons)
    self.pages = pages
    self.buttons = {}
    self.extra_buttons = extra_buttons
    for i, page_info in ipairs(self.pages) do
        local name = page_info.name
        table.insert(self.buttons, Button {
            text = name,
            on_pressed = function()
                self:set_current_page(name)
            end,
            colour = page_info.colour
        })
    end
    self:set_current_page(starting_page)
    self.rebuild = true
end

function PagesWidget:set_current_page(new_current_page)
    for i, button in ipairs(self.buttons) do
        if button.text == new_current_page then
            button.colour = GREEN
            self.current_page = i
        else
            button.colour = WHITE
        end
    end
    self.rebuild = true
end

function PagesWidget:render(render_box)
    if self.rebuild then
        self.widget = self:build()
        self.rebuild = false
    end
    return self.widget
end
function PagesWidget:build()
    return Row({
        Column({ Column(self.extra_buttons, { child_padding = 5 }), Column(self.buttons, { child_padding = 5 }) }),
        ScrollArea { child = self.pages[self.current_page].widget }
    }, { child_padding = 5 })
end


