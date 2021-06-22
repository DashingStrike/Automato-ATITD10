cleanups = {}
dofile("lime_janitor/configuration.inc")

dofile("lime_janitor/util/table_printer.inc")
dofile("lime_janitor/util/string.inc")
dofile("lime_janitor/ui/widgets.inc")
dofile("lime_janitor/ui/pages_widget.inc")
dofile("lime_janitor/ui/colours.inc")

dofile("lime_janitor/job_manager.inc")
dofile("lime_janitor/window_manager.inc")
dofile("lime_janitor/click_manager.inc")
dofile("lime_janitor/firepit_macro.inc")
dofile("lime_janitor/firepit_macro_widget.inc")
dofile("lime_janitor/job_manager_widget.inc")
dofile("lime_janitor/run_viewer_widget.inc")
dofile("lime_janitor/carve_tinder.inc")

function doit()
    askForWindow("Press shift over the ATITD window to begin")
    local config = Configuration()
    local job_manager = JobManager()
    local click_manager = ClickManager()
    local window_manager = WindowManager(click_manager)
    local macro = FirepitMacro(window_manager)
    cleanupCallback = function()
        for i, c in ipairs(cleanups) do
            print("cleaning up " .. i)
            c:cleanup()
        end
    end

    local app = AppWidget(Padding {
        all = 10,
        child = PagesWidget({
            { name = "Instructions", widget = Text(
                    [[INSTRUCTIONS FOR USE:
- Set Shadow Quality, Time of Day lighting and Lighting intensity to minimum.
- Camera F8 F8 F8 and lock
- Don't standing over / in the firepits
- Make sure the red firepit outline is central and covers as much as the flame as possible
- Overload yourself so you don't accidentally move during the macro]]

            )},
            { name = "FirepitRunner", widget = FirepitMacroWidget(macro) },
            { name = "AutoTinderCarver", widget = {
                render = function()
                    return Button {
                        text = "Start auto carving",
                        on_pressed = function()
                            if not auto_carving then
                                auto_carving = true
                                job_manager:submit { name = "auto_carver", job = CarveTinder() }
                            end
                        end
                    }

                end
            } },
            { name = "JobStats", widget = JobManagerWidget(job_manager) },
            { name = "RunDebugger", widget = RunViewerWidget() }
        },
                "Instructions",
                {
                    Button {
                        text = "Exit",
                        on_pressed = function()
                            job_manager:should_exit()
                        end,
                        colour = RED
                    },
                    {
                        render = function(box)
                            local w = {}
                            for _, job in ipairs(job_manager.jobs) do
                                if job.lagging then
                                    table.insert(w, Text(job.name .. " is lagging", RED))
                                end
                            end
                            return Column(w, { child_padding = 5 })
                        end
                    },
                })
    }, config)

    job_manager:submit {
        job = macro,
        name = "macro"
    }
    job_manager:submit {
        job = app,
        name = "app"
    }

    job_manager:run()

end
