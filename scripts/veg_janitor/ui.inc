dofile("veg_janitor/io.inc")
dofile("veg_janitor/logger.inc")
dofile("screen_reader_common.inc")
-- Used to place gui elements sucessively.
current_y = 0
-- How far off the left hand side to place gui elements.
X_PADDING = 5
CONFIG_FILE_VERSION = "v2_2_"
DEFAULT_CONFIG_FILENAME_VEG = CONFIG_FILE_VERSION .. "default_veg_janitor_config.txt"
TYPES = {
  "Cabbages",
  "Carrots",
  "Cucumbers",
  "Eggplant",
  "Garlic",
  "Leeks",
  "Onions",
  "Peppers",
  "Watermelon",
}
TYPES_WITH_DEFAULT = {
  "Default",
  "Cabbages",
  "Carrots",
  "Cucumbers",
  "Eggplant",
  "Garlic",
  "Leeks",
  "Onions",
  "Peppers",
  "Watermelon",
}
function sub_screen(o, config)
  local done = false
  local open = true
  if o.open_button then
    open = button(o.open_button or "Open")
  end
  config = config or o.config

  if open then
    while not done do
      current_y = 0
      done = o.draw_screen(config)
      if type(done) == "table" then
        config = done
        done = false
      end
      done = done or drawBottomButton(lsScreenX - 5, o.done_button_text or "Done")
      if drawBottomButton(110, "Exit Script", RED) then
        error "Script exited by user"
      end
      write_config(config)
      lsDoFrame()
      lsSleep(10)
    end
  end
end
function single_attribute_edit_screen(config, title, descriptive_name, name, default, thing_type, width)
  sub_screen {
    config = config,
    done_button_text = "Back",
    open_button = title,
    draw_screen = function()
      if not thing_type then
        thing_type = type(default)
      end

      local before = config[name]
      if before == nil then
        before = default
      end

      config[name] = drawEditBox(name .. config.name, descriptive_name, before, thing_type, width)
    end
  }

end

function attribute_edit_screen(config, title, descriptive_name, name, default)
  sub_screen {
    config = config,
    done_button_text = "Back",
    open_button = title,
    draw_screen = function()
      local types_with_values = {}
      for i, type in ipairs(TYPES_WITH_DEFAULT) do
        local v = config[name][type]
        table.insert(types_with_values, type .. (v and (" (" .. v .. ")") or ""))

      end
      local k = dropdown(name .. config.name, 1, types_with_values, "Type", TYPES_WITH_DEFAULT)
      if config[name][k] == nil then
        local create = button("Create " .. descriptive_name .. " for " .. k)
        if create then
          config[name][k] = default
        end
      else
        config[name][k] = drawEditBox(name .. config.name .. k, descriptive_name .. "for " .. k, config[name][k], type(default) == "number")
        if k ~= "Default" then
          local unset = button("Unset for " .. k .. " to use default again")
          if unset then
            config[name][k] = nil
          end
        end
      end
    end
  }

end

function stage_water_timings_display_string(v)
  local display = ""
  for k, timing in pairs(v or {}) do
    if k == "calibrated" then
      if timing then
        display = display .. "calibrated,"
      end
    elseif k == "data_points" then
      if timing > 0 then
        display = display .. k .. "=" .. timing .. ","
      end
    else
      if timing then
        display = display .. k .. "=" .. (timing / 1000) .. "s,"
      end
    end
  end
  return display
end

function drawCalibrationModeSettingsScreen(config)
  current_y = 10
  drawWrappedText([[CALIBRATION MODE SETTINGS:]],
    GREEN,
    X_PADDING,
    current_y)
  local plant_types = {}
  for plant_type, _ in pairs(config.plants) do
    table.insert(plant_types, plant_type)
  end
  local plant_type = dropdown("calibration_plant_type_select_" .. config.name, findIndex(plant_types, config.selected_seed_type, 1), plant_types, "Plant type:")
  local seed_names = {}
  for seed_name, _ in pairs(config.plants[plant_type]) do
    table.insert(seed_names, seed_name)
  end
  local seed_name = dropdown("calibration_seed_select_" .. config.name, findIndex(seed_names, config.seed_name, 1), seed_names, "Seed Name:")
  drawWrappedText([[The settings below adjust how the many recorded calibration stage timings are converted into a single stage time to store and use in normal mode.]],
    WHITE,
    X_PADDING,
    current_y)
  current_y = current_y + 15
  config.calibration_mode_percentile = drawEditBox("calibration_mode_percentile",
    "Calibration Mode Target Percentile? ", config.calibration_mode_percentile or 95, "percentage")
  drawWrappedText([[The above sets the percentile value to use when converting the many recorded times to a single time to save.
e.g. 50 will save the average recorded stage time, 100 will save the maximum recorded stage time, 95 will save the stage time which covers 95% of recorded stage times etc.]],
    GREY,
    X_PADDING,
    current_y)
  current_y = current_y + 15
  config.calibration_mode_buffer_ms = drawNumberEditBox("calibration_mode_buffer_ms",
    "Calibration Mode Buffer Milliseconds? ", config.calibration_mode_buffer_ms or 1000)
  drawWrappedText([[After calibrating and calculating the percentile these extra milliseconds will be added
on to any growth times calculated as an extra buffer to prevent watering too soon.]],
    GREY,
    X_PADDING,
    current_y)

  local invalid_key = config_is_invalid(config)

  if not invalid_key then
    local timings = config.plants[plant_type][seed_name]['stage_advance_timings']
    if timings and timings.calibrated then
      current_y = current_y + 10
      local data_points = timings.data_points or 0
      local timing_string = stage_water_timings_display_string(timings)
      drawWrappedText("Using " .. data_points .. " previous calibration runs to calc: ", GREEN, X_PADDING, current_y)
      drawWrappedText(timing_string, GREEN, X_PADDING, current_y)
      drawWrappedText([[Veg Janitor keeps track of old calibration runs for each config and plant type and includes these in the calculation.
]],
        GREY,
        X_PADDING,
        current_y)
      local reset = lsButtonText(X_PADDING, current_y, z, 300, RED, "Reset calibration data")
      current_y = current_y + 30
      if reset then
        timings.calibrated = false
        timings.data_points = 0
        calibration_insert_reset_row(config.name, plant_type, seed_name)
      end

    else
      local timing_string = stage_water_timings_display_string(timings)
      drawWrappedText("Using manually set config values: ", RED, X_PADDING, current_y)
      drawWrappedText(timing_string, RED, X_PADDING, current_y)
    end
    local recalc = lsButtonText(X_PADDING, current_y, z, 250, WHITE, "Recalculate Percentile")
    if recalc then
      config = calculate_and_update_calibration_settings(config, plant_type, seed_name)
    end
  else
    drawWrappedText("Config value " .. invalid_key .. " is invalid, please edit config and fix it.", RED, X_PADDING, lsScreenY - 60)
  end
  return config
end

function drawPlantDetectionSettingsScreen(config)
  current_y = 10
  drawWrappedText([[PLANT DETECTION SETTINGS:]],
    GREEN,
    X_PADDING,
    current_y)
  drawWrappedText([[Veg Janitor will only click a newly planted plant if it sees more than a fixed number of pixels change
  where it is watching. Below you can set the number of pixels required to change before veg janitor will see and click them per plant type.
  For example, carrots are much smaller than onions so by default onions has a larger value by default.
  ]],
    WHITE,
    X_PADDING,
    current_y)
  for key, value in pairsByKeys(config.required_number_of_changed_pixels_before_clicking) do
    config.required_number_of_changed_pixels_before_clicking[key] = drawNumberEditBox("pds_" .. key,
      key, value)
  end
  return config

end
function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do
    table.insert(a, n)
  end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function()
    -- iterator function
    i = i + 1
    if a[i] == nil then
      return nil
    else
      return a[i], t[a[i]]
    end
  end
  return iter
end

function edit_config_screen(config)
  sub_screen {
    config = config,
    done_button_text = "Back",
    draw_screen = function()
      current_y = 10
      drawTextUsingCurrent("Veg Janitor Settings - preset = " .. config.name .. " :", GREEN)
      sub_screen {
        config = config,
        done_button_text = "Back",
        open_button = "Edit Plant Run Settings",
        draw_screen = function()
          drawTextUsingCurrent('Plant run settings:', GREEN)
          attribute_edit_screen(config, "Edit Plant Batch Size", "Planting Batch Size", "planting_batch_size", 4)
          single_attribute_edit_screen(config, "Edit Harvest Click Delay", "The number of milli seconds between harvest clicks.", "harvest_delay_time", 2500)
          single_attribute_edit_screen(config, "Edit Num Plant Snapshots", "The number of plant snapshots taken at the start of each run.", "num_plant_snaps", 10)
          single_attribute_edit_screen(config, "Edit Num Character Snapshots", "The number of character snapshots taken at the start of each run.", "num_char_snaps", 10)
          single_attribute_edit_screen(config, "Edit Num Calibration Runs", "The number runs done in a calibration session.", "num_calibration_runs", 10)
          single_attribute_edit_screen(config, "Edit Calibration Mode Onion Threshold", "The percentage pixels required to change at once for the calibration mode to think an onion has grown a stage.", "onion_calibration_mode_change_threshold", 4.5, "percentage", 200)
          single_attribute_edit_screen(config, "Edit Calibration Mode Non Onion Threshold",
            "The percentage of pixels required to change at once for the calibration mode to think an non onion has grown a stage.",
            "non_onion_calibration_mode_change_threshold", 1, "percentage", 200)
          config.plant_search_uses_equality = CheckBox(X_PADDING, current_y, 10, WHITE, " Exact pixel change detection for plants?", config.plant_search_uses_equality)
          current_y = current_y + 30
          config.only_click_when_pixel_changes_mode = CheckBox(X_PADDING, current_y, 10, WHITE, " Wait for pixel to change before opening plant?", config.only_click_when_pixel_changes_mode)
          current_y = current_y + 30
          config.check_for_water_button = CheckBox(X_PADDING, current_y, 10, WHITE, " Error if the water button can't be seen at start?", config.check_for_water_button)
          current_y = current_y + 30
          config.search_for_seed_bags = CheckBox(X_PADDING, current_y, 10, WHITE, " Pickup dead plant seed bags after each run?", config.search_for_seed_bags)

        end
      }
      sub_screen {
        config = config,
        done_button_text = "Back",
        open_button = "Edit Calibration Mode Settings",
        draw_screen = drawCalibrationModeSettingsScreen
      }
      sub_screen {
        config = config,
        done_button_text = "Back",
        open_button = "Edit Plant Order and Locations",
        draw_screen = function()
          drawTextUsingCurrent("PLANT ORDER AND LOCATION CONFIG:", GREEN)
          drawWrappedTextUsingCurrent("This menu lets you change where veg janitor puts each plant using the build menu.", WHITE)
          drawWrappedTextUsingCurrent("Testing out different orders and locations can help find more stable arrangements of plants where there is less likelyhood of clashes/miss clicks.", WHITE)
          current_y = current_y + 30
          local plant_types = { 'Default' }
          for plant_type, plant_config in pairs(config.plants) do
            table.insert(plant_types, plant_type)
          end
          local seed_names = {}
          local plant_type = dropdown("plant_loc_" .. config.name, findIndex(plant_types, config.selected_seed_type, 1), plant_types, "Plant type:")
          local seed_name = ''
          local loc_conf
          if plant_type == 'Default' then
            loc_conf = config.default_plant_location_order
          else
            for seed_name, seed_config in pairs(config.plants[plant_type]) do
              table.insert(seed_names, seed_name)
            end
            seed_name = dropdown("plant_loc_" .. plant_type .. config.name, findIndex(seed_names, config.seed_name, 1), seed_names, "Seed name:")
            local seed_config = config.plants[plant_type][seed_name]
            loc_conf = seed_config.plant_location_order
          end
          local dropdown_key = seed_name .. plant_type .. config.name
          local selected_step = 1
          if loc_conf and #loc_conf > 0 then
            local steps = {}
            local step_displays = {}
            for i = 1, #loc_conf do
              table.insert(step_displays, 'Plant ' .. i .. ' = ' .. loc_conf[i].direction .. ', ' .. loc_conf[i].number_of_moves)
              table.insert(steps, i)
            end
            selected_step = dropdown("plant_step_" .. dropdown_key, 1, step_displays, "Plant Number (1 is first plant placed, 2 is second etc):", steps)
            loc_conf[selected_step].direction = dropdown("plant_dir_" .. (selected_step) .. dropdown_key, findIndex(DIRECTION_NAMES, loc_conf[selected_step].direction, 1), DIRECTION_NAMES, "Direction :")
            local new_moves = drawPosNumberEditBox("plant_moves_" .. (selected_step) .. dropdown_key, 'Number of Moves:', loc_conf[selected_step].number_of_moves or 1)
            if new_moves and new_moves > 0 then
              loc_conf[selected_step].number_of_moves = new_moves
            end
          else
            drawWrappedTextUsingCurrent("Using default plant locations for " .. plant_type .. ' - ' .. seed_name .. '. Click add below to create a custom location config for this seed.', WHITE)
          end
          local add_new = lsButtonText(X_PADDING, current_y, 2, 250, GREEN, "Add Step")
          current_y = current_y + 30
          local remove_last = false
          if loc_conf and #loc_conf > 0 then
            remove_last = lsButtonText(X_PADDING, current_y, 2, 250, RED, "Delete Step")
          end
          current_y = current_y + 30
          if add_new then
            if not loc_conf then
              loc_conf = {}
              if plant_type == 'Default' then
                config.default_plant_location_order = loc_conf
              else
                config.plants[plant_type][seed_name].plant_location_order = loc_conf
              end
            end
            table.insert(loc_conf,
              {
                ["direction"] = "NORTH",
                ["number_of_moves"] = 1,
              }
            )
            selected_step = #loc_conf
          end
          if remove_last then
            local new_conf = {}
            for i = 1, #loc_conf do
              if i ~= selected_step then
                table.insert(new_conf, loc_conf[i])
              end
            end
            if plant_type == 'Default' then
              config.default_plant_location_order = new_conf
            else
              config.plants[plant_type][seed_name].plant_location_order = new_conf
            end
            if #loc_conf == 0 and plant_type ~= 'Default' then
              config.plants[plant_type][seed_name].plant_location_order = nil
            end
          end
          if loc_conf and #loc_conf > 1 then
            local duplicates = false
            local seen_keys = {}
            for i = 1, #loc_conf do
              local key = loc_conf[i].direction .. '-' .. loc_conf[i].number_of_moves
              if seen_keys[key] then
                duplicates = true
              else
                seen_keys[key] = true
              end
            end
            if duplicates then
              drawWrappedTextUsingCurrent("WARNING: YOU HAVE ENTERED TWO OR MORE STEPS WITH THE SAME LOCATION, THIS WILL NOT WORK.", RED)
            end
          end

        end
      }
      sub_screen {
        config = config,
        done_button_text = "Back",
        open_button = "Edit Stage Water Timings",
        draw_screen = function()
          drawTextUsingCurrent("STAGE WATER TIMINGS CONFIG:", GREEN)
          drawWrappedTextUsingCurrent("This menu lets you change how long veg janitor waits between watering each growth stage of a plant.", WHITE)
          drawWrappedTextUsingCurrent("For example, a value of 16000 for stage 1 means veg janitor will wait 16000 milliseconds after the plant is first watered until watering again.", WHITE)
          current_y = current_y + 30
          local plant_types = {}
          for plant_type, plant_config in pairs(config.plants) do
            table.insert(plant_types, plant_type)
          end
          local seed_names = {}
          local plant_type = dropdown("stage_advance_timings_plant_type_" .. config.name, findIndex(plant_types, config.selected_seed_type, 1), plant_types, "Plant type:")
          for seed_name, seed_config in pairs(config.plants[plant_type]) do
            table.insert(seed_names, seed_name)
          end
          local seed_name = dropdown("stage_advance_timings_seed_name_" .. plant_type .. config.name, findIndex(seed_names, config.seed_name, 1), seed_names, "Seed name:")
          local seed_config = config.plants[plant_type][seed_name]
          local dropdown_key = seed_name .. plant_type .. config.name
          local stage_dropdown_values = {}
          local timings = config.plants[plant_type][seed_name].stage_advance_timings
          local stages_list = {}
          for i = 1, seed_config.stages do
            table.insert(stages_list, i)
          end
          if timings.calibrated then
            drawWrappedTextUsingCurrent("This seed's timings have been calibrated automatically. See Edit Current Config->Edit Calibration Mode Settings for more", GREEN)
          end
          for i, stage in ipairs(stages_list) do
            local stage_value = timings[stage]
            table.insert(stage_dropdown_values, stage .. (stage_value and (" (" .. stage_value .. ")") or ""))
          end
          local stage = dropdown("stage" .. dropdown_key, 1, stage_dropdown_values, "Stage:", stages_list)

          if timings[stage] == nil then
            local create = button("Create timing for " .. seed_name .. " in stage " .. stage)
            if create then
              timings[stage] = 14000
            end
          else
            timings[stage] = drawEditBox("stage_edit" .. dropdown_key .. stage .. (timings[stage]), "Timing for stage" .. stage, timings[stage], true)
          end


        end
      }
      sub_screen {
        config = config,
        done_button_text = "Back",
        open_button = "Edit or Create Plants",
        draw_screen = function()
          plant_creator(config)
        end
      }
      config.click_delay = drawNumberEditBox("click_delay", "What should the click delay be? ", 100)
      current_y = current_y + 30
      config.show_debug_images = CheckBox(X_PADDING, current_y, 10, WHITE, " Show Debug Images?", config.show_debug_images)
      current_y = current_y + 100
      config.debug_log_level = dropdown("debug_log_level", config.debug_log_level or INFO, LOG_LEVEL_TO_NAME, "Debug Log Level:", LOG_LEVEL_TO_LEVEL)
      local copy_log_to_clipboard = button("Copy last runs debug log to clipboard", YELLOW)
      if copy_log_to_clipboard then
        lsClipboardSet(get_veg_log())
      end
      local copy_to_clipboard = button("Copy config to clipboard")
      if copy_to_clipboard then
        lsClipboardSet(serializeToString(config))
      end
      local set_from_clipboard = button("Set config from clipboard")
      if set_from_clipboard then
        local config_string = lsClipboardGet()
        local success, new_config = deserializeFromString(config_string)
        assert(success, "Failed to load config from clipboard")
        assert(new_config.filename, "Invalid config string, no filename found")
        assert(new_config.name, "Invalid config string, no name found")
        for k, v in pairs(config) do
          config[k] = nil
        end
        for k, v in pairs(new_config) do
          config[k] = v
        end
        update_configs(new_config)
        return true
      end
    end
  }
end

function update_configs(new_config)
  writeSetting(CONFIG_FILE_VERSION .. "current_config", new_config.name)
  local config_string = readSetting(CONFIG_FILE_VERSION .. "config_names") or "default"
  local configs = config_string:split(",")
  local config_set = {}
  for _, c in ipairs(configs) do
    config_set[c] = true
  end
  if not config_set[new_config.name] then
    local new_config_string = config_string .. "," .. new_config.name
    writeSetting(CONFIG_FILE_VERSION .. "config_names", new_config_string)
  end
  write_config(new_config)

end

unique_edit_index = 1

button_widths = {}
function button(text, colour, right_align)
  if not button_widths[text] then
    button_widths[text] = lsPrint(-100, -100, 10, 1.2, 1.2, colour or WHITE, text)
  end
  if right_align then
    current_y = current_y - 30
  end
  local x = right_align and (lsScreenX - (button_widths[text] + 10)) or 5
  local result = lsButtonText(x, current_y, 1, button_widths[text], colour or WHITE, text)
  current_y = current_y + 30
  return result
end

function config_attribute_setter(config)

end

function config_selector(starting_config)
  drawTextUsingCurrent("Select configuration to use:", GREEN)
  local config_string = readSetting(CONFIG_FILE_VERSION .. "config_names") or CONFIG_FILE_VERSION .. "default"
  local setting_config = readSetting(CONFIG_FILE_VERSION .. "current_config") or CONFIG_FILE_VERSION .. "default"
  local configs = config_string:split(",")
  local current_config, changed = dropdown("config_selector" .. setting_config, setting_config, configs, "Configuration Preset")
  if changed then
    writeSetting(CONFIG_FILE_VERSION .. "current_config", current_config)
    local success, config = deserialize(current_config .. "_veg_janitor_config.txt")
    starting_config = config
    starting_config.filename = current_config .. "_veg_janitor_config.txt"
    starting_config.name = current_config
    if not success then
      writeSetting(CONFIG_FILE_VERSION .. "current_config", CONFIG_FILE_VERSION .. "default")
      error("Failed to open config file " .. current_config)
    end
  end
  local add = button("Create New Config", YELLOW)
  if add then
    sub_screen {
      config = starting_config,
      done_button_text = "Back",
      draw_screen = function()
        local new_config_name = drawEditBox("config_name", "Name", "", false)
        local valid = new_config_name and new_config_name ~= ""
        for _, c in ipairs(configs) do
          valid = valid and c ~= new_config_name
        end
        local create = button(new_config_name and ("Create with name: " .. new_config_name) or "Enter a valid config name", valid and GREEN or RED)
        if valid and create then
          config_string = config_string .. "," .. new_config_name
          writeSetting(CONFIG_FILE_VERSION .. "config_names", config_string)
          writeSetting(CONFIG_FILE_VERSION .. "current_config", new_config_name)
          local success, default_config = deserialize(DEFAULT_CONFIG_FILENAME_VEG)
          if not success then
            error("Failed to load default config to copy when making new config, it should be found in default_veg_janitor_config.txt")
          end
          starting_config = default_config
          starting_config.filename = new_config_name .. "_veg_janitor_config.txt"
          starting_config.name = new_config_name
          write_config(starting_config)
          return true
        end
      end
    }
  end

  return starting_config
end

function load_current_config()
  local success, default_config = deserialize(DEFAULT_CONFIG_FILENAME_VEG)
  if not success then
    serialize(default_deep_config(), DEFAULT_CONFIG_FILENAME_VEG)
  end
  local current_config = readSetting(CONFIG_FILE_VERSION .. "current_config") or CONFIG_FILE_VERSION .. "default"
  local success, config = deserialize(current_config .. "_veg_janitor_config.txt")
  starting_config = config
  if not success then
    writeSetting(CONFIG_FILE_VERSION .. "current_config", CONFIG_FILE_VERSION .. "default")
    error("Failed to open config file " .. current_config)
  end
  config.filename = current_config .. "_veg_janitor_config.txt"
  config.name = current_config
  return config
end
function findIndex(list, value, default)
  if not default then
    default = 1
  end
  for i, ivalue in ipairs(list) do
    if ivalue == value then
      return i
    end
  end
  return default
end

function default_seed_config()
  return {
    ["stage_advance_timings"] = {
      [1] = 16000,
      ["calibrated"] = false
    }
  }
end

dropdown_index = 1
starting_plant_type = 'Onions'
starting_seed_name = 'Tears of Sinai'
function plant_creator(config)
  local existing_plant_types = { "Create New" }
  config.plants = config.plants or {}
  for plant_type, seeds in pairs(config.plants) do
    table.insert(existing_plant_types, plant_type)
  end
  drawTextUsingCurrent("Select plant type to edit or 'Create New':", WHITE)
  local plant_type = dropdown("existing_plant_types" .. (dropdown_index),
    findIndex(existing_plant_types, starting_plant_type, 2),
    existing_plant_types)
  local new_plant_type = plant_type == "Create New"
  local plant_type_config = {}
  local seed_names = { "Create New" }
  if not new_plant_type then
    plant_type_config = config.plants[plant_type]
    for seed_name, seed_config in pairs(config.plants[plant_type]) do
      table.insert(seed_names, seed_name)
    end
  end

  local seed_name = dropdown("seed_name_" .. plant_type .. (dropdown_index), findIndex(seed_names, starting_seed_name, 2),
    seed_names, "Seed or 'Create New':")
  local new_seed = seed_name == 'Create New'
  local seed_config = {}
  if not new_seed then
    seed_config = plant_type_config[seed_name]
  end
  local seed_type_and_name = plant_type .. ' - ' .. seed_name
  local org_plant_type = plant_type
  local org_seed_name = seed_name
  local seed_key = seed_name .. (dropdown_index)
  local plant_type_key = plant_type .. (dropdown_index)
  if new_seed then
    seed_name = ''
  end
  if new_plant_type then
    plant_type = ''
  end
  plant_type = drawEditBox("new_plant_type_name" .. plant_type_key, "Plant Type Name", plant_type, false, 250) or ""
  seed_name = drawEditBox("new_seed_name" .. seed_key, "Seed Name", seed_name, false, 250) or ""
  local stages = drawEditBox("watering_stages" .. seed_type_and_name,
    "Number of  watering stages", seed_config.stages or 3, true)
  local waters = drawEditBox("number_of_waters_per_stage" .. seed_type_and_name,
    "Number of waters per stage", seed_config.waters or 2, true)
  local yield = drawEditBox("yield" .. seed_type_and_name, "Yield",
    seed_config.yield or 2, true)
  local valid = (seed_name and seed_name ~= "") and plant_type and plant_type ~= "" and stages and waters and yield and (not new_plant or not config.plants[plant_name])
  if new_plant_type and config.plants[plant_type] then
    drawTextUsingCurrent("Plant Type with name " .. plant_type .. " already exists, please change the name.", RED)
  end
  if new_seed and plant_type_config[seed_name] then
    drawTextUsingCurrent("Seed with name " .. seed_name .. " already exists, please change the name.", RED)
  end
  local text = 'Edit'
  if new_plant_type or new_seed then
    text = 'Create'
  end
  local add = false
  local changes = new_plant_type or new_seed
  if plant_type ~= org_plant_type then
    changes = true
  end
  if seed_name ~= org_seed_name then
    changes = true
  end
  local new_config = { type = plant_type, stages = stages, waters = waters, yield = yield }
  for key, value in pairs(new_config) do
    if config.plants[org_plant_type] and config.plants[org_plant_type][org_seed_name] and config.plants[org_plant_type][org_seed_name][key] ~= value then
      changes = true
    end
  end
  if valid and changes then
    add = button('Click to ' .. text, text == 'Edit' and ORANGE or GREEN)
  end
  if not valid then
    drawTextUsingCurrent('You have entered an invalid plant type name, seed name or numerical values. Please fix.', RED)
  end
  if not changes then
    drawTextUsingCurrent('No changes to the plant config made...', WHITE)
  end
  if valid and add then
    if text == 'Edit' then
      local org = config.plants[org_plant_type]
      config.plants[org_plant_type] = nil
      config.plants[plant_type] = org
      for seed_name, seed_config in pairs(config.plants[plant_type]) do
        seed_config['type'] = plant_type
      end
      local org_seed = org[org_seed_name]
      config.plants[plant_type][org_seed_name] = nil
      config.plants[plant_type][seed_name] = org_seed
    end
    config.plants[plant_type] = config.plants[plant_type] or {}
    if not config.plants[plant_type][seed_name] then
      config.plants[plant_type][seed_name] = default_seed_config(plant_type)
    end
    for key, value in pairs(new_config) do
      config.plants[plant_type][seed_name][key] = value
    end
    local conf = config.plants[plant_type][seed_name]
    if #conf.stage_advance_timings < conf.stages then
      for i = #conf.stage_advance_timings + 1, conf.stages do
        conf.stage_advance_timings[i] = 16000
      end
    end
    write_config(config)
    dropdown_index = dropdown_index + 1
    starting_plant_type = plant_type
    starting_seed_name = seed_name
  end
  if not new_seed then
    local delete = button("Delete Seed", RED)
    if delete then
      config.plants[plant_type][seed_name] = nil
      write_config(config)
    end
  end
end

function update_config_with_missing_keys(config)
  local default_config = default_deep_config()
  local changed_config = false
  for k, v in pairs(default_config) do
    if config[k] == nil then
      config[k] = v
      changed_config = true
    end
  end

  if changed_config then
    write_config(config)
  end

end

function write_config(config)
  serialize(config, config.filename, false, true)
end

dropdown_indexs = {}
function dropdown(key, starting_index, values, text, return_values)
  lsSetCamera(0, 0, lsScreenX * 1.2, lsScreenY * 1.2);
  if text then
    drawTextUsingCurrent(text)
  end
  if type(starting_index) == "string" then
    for i, v in ipairs(values) do
      if v == starting_index then
        starting_index = i
        break
      end
    end
  end
  local before = dropdown_indexs[key]
  dropdown_indexs[key] = lsDropdown(key, X_PADDING, current_y, 10, lsScreenX - 10, dropdown_indexs[key] or starting_index, values)
  current_y = current_y + 30
  return_values = return_values or values
  return return_values[dropdown_indexs[key]], before ~= dropdown_indexs[key]
end

function is_boolean_config_key(key)
  local boolean_config_keys = {
    ['record_plant_animation'] = true,
    ["alternate_drag"] = true,
    ["pre_look"] = true,
    ["reposition_avatar"] = true,
    ["sorting_mode"] = true,
    ["search_for_seed_bags"] = true,
    ["check_for_water_button"] = true,
    ["show_debug_images"] = true,
    ["only_click_when_pixel_changes_mode"] = true,
    ["plant_search_uses_equality"] = true
  }
  return boolean_config_keys[key]
end

function config_is_invalid(config)
  local invalid_key = false
  for k, v in pairs(config) do
    if not v and not is_boolean_config_key(k) then
      invalid_key = k
      break
    end
  end
  for plant_type, v in pairs(config.plants) do
    if not v then
      invalid_key = 'plants.' .. plant_type
      break
    end
    for seed_name, seed_config in pairs(config.plants[plant_type]) do
      for seed_key, seed_config_value in pairs(seed_config) do
        if not seed_config_value and not is_boolean_config_key(seed_key) then
          invalid_key = 'plants.' .. plant_type .. '.' .. seed_name
          break
        end
      end
    end
    return invalid_key
  end
end

function getUserParams()
  local is_done = false
  local got_user_params = false
  local calibration_mode = false

  local config = load_current_config()
  if config.num_plant_snaps == nil then
    config.num_plant_snaps = 10
  end
  if config.num_char_snaps == nil then
    config.num_char_snaps = 10
  end
  local edit_config = false
  while not is_done and not calibration_mode do
    current_y = 10
    if edit_config then
      edit_config_screen(config)
      edit_config = false
    elseif not got_user_params then
      config = config_selector(config)
      edit_config = button("Edit Current Config", ORANGE, true)
      current_y = current_y + 20
      drawTextUsingCurrent("Run Options:", GREEN)
      config.selected_seed_type = dropdown("seed_type_selector", config.selected_seed_type or 1, TYPES, "Plant type")
      local plants = {}
      for n, plant in pairs(config.plants[config.selected_seed_type]) do
        table.insert(plants, n)
      end
      table.sort(plants, function(a, b)
        local type_a = config.plants[config.selected_seed_type][a].type
        local type_b = config.plants[config.selected_seed_type][b].type
        if type_a ~= type_b then
          return type_a < type_b
        else
          return a < b
        end
      end)
      local display_seed_names = {}
      local filtered_plants = {}
      local starting_index = 1
      local i = 1
      for _, name in ipairs(plants) do
        local plant = config.plants[config.selected_seed_type][name]
        if name == config.seed_name then
          starting_index = i
        end
        table.insert(filtered_plants, name)
        local width = lsPrint(-100, -100, 10, 1, 1, colour or WHITE, name)
        local padded_name = string.lpad(name, math.floor((180 - width) / 5))
        table.insert(display_seed_names, padded_name .. " (" .. plant.type .. ",Yield:" .. plant.yield .. ")")
        i = i + 1
      end
      if #display_seed_names > 0 then
        config.seed_name = dropdown("seed_name", starting_index, display_seed_names, "Seed name", filtered_plants)
      end
      config.num_plants = drawNumberEditBox("num_plants", "How many to plant per run? ", 4)
      config.num_runs = drawNumberEditBox("num_runs", "How many runs? ", 20)
      local invalid_key = config_is_invalid(config)

      if not invalid_key then
        got_user_params = drawBottomButton(lsScreenX - 5, "Next step", GREEN)
      else
        drawWrappedText("Config value " .. invalid_key .. " is invalid, please edit config and fix it.", RED, X_PADDING, lsScreenY - 20)
      end
    else
      local invalid_key = config_is_invalid(config)

      if not invalid_key then
        drawWrappedText("IN-GAME SETUP INSTRUCTIONS:", RED, X_PADDING, current_y)
        if not flashing_colour then
          flashing_colour = RED
          last_flash = lsGetTimer()
        end
        drawWrappedText("Please re-read these instructions, they have changed as of 21/06/2021", flashing_colour, X_PADDING, current_y)
        if lsGetTimer() - last_flash > 500 then
          if flashing_colour == RED then
            flashing_colour = WHITE
          elseif flashing_colour == WHITE then
            flashing_colour = GREEN
          else
            flashing_colour = RED
          end
          last_flash = lsGetTimer()
        end
        drawWrappedText(WARNING, WHITE, X_PADDING, current_y)
        local seed_type = config.selected_seed_type
        local seed_name = config.seed_name
        local timings = config.plants[seed_type][seed_name].stage_advance_timings
        local plant_is_calibrated = timings and timings.calibrated
        if not plant_is_calibrated then
          drawWrappedText("Please click calibrate first to " .. seed_type .. " to calculate stage water times automatically. If you instead want to use the timings manually set in your config just click start.", GREEN, X_PADDING, lsScreenY - 100)
          calibration_mode = lsButtonText(0, lsScreenY - 30, z, 200, GREEN, "Calibrate " .. seed_name)
          is_done = lsButtonText(210, lsScreenY - 30, z, 100, ORANGE, "Start")
          if lsButtonText(320, lsScreenY - 30, z, 100, WHITE, "Back") then
            got_user_params = false
          end
        else
          drawWrappedText("Please re-run the calibration often especially if the macro is miss-timing often and over or under watering.", GREEN, X_PADDING, lsScreenY - 100)
          is_done = lsButtonText(0, lsScreenY - 30, z, 100, GREEN, "Start")
          calibration_mode = lsButtonText(110, lsScreenY - 30, z, 200, YELLOW, "Calibrate More")
          if lsButtonText(320, lsScreenY - 30, z, 100, WHITE, "Back") then
            got_user_params = false
          end
        end
      else
        drawWrappedText("Config value " .. invalid_key .. " is invalid, please edit config and fix it.", RED, X_PADDING, lsScreenY - 60)
        if lsButtonText(0, lsScreenY - 30, z, 100, WHITE, "Back") then
          got_user_params = false
        end
      end
    end
    if drawBottomButton(110, "Exit Script", RED) then
      error "Script exited by user"
    end

    if config.onion_calibration_mode_change_threshold == 4 and not config.fudged_onion then
      config.onion_calibration_mode_change_threshold = 4.5
      config.fudged_onion = true
      veg_log(INFO, config.debug_log_level, 'ui.inc', "Fudging onion to be a better number from previous default config value.")
    elseif not config.onion_calibration_mode_change_threshold then
      config.onion_calibration_mode_change_threshold = 4.5
      config.fudged_onion = true
    end
    if not config.non_onion_calibration_mode_change_threshold then
      config.non_onion_calibration_mode_change_threshold = 1
    end
    if config.debug_log_level == nil then
      config.debug_log_level = INFO
    end
    if config.only_click_when_pixel_changes_mode == nil then
      config.only_click_when_pixel_changes_mode = true
    end

    write_config(config)
    lsDoFrame()
    lsSleep(10)
  end
  config.calibration_mode = calibration_mode
  config.num_stages = config.plants[config.selected_seed_type][config.seed_name].stages
  config.num_waterings = config.plants[config.selected_seed_type][config.seed_name].waters
  config.seed_type = config.selected_seed_type
  config.pre_look = true
  config.record_plant_animation = config.seed_type == 'Onions'
  config.reposition_avatar = true
  config.sorting_mode = true
  config.alternate_drag = true
  click_delay = config.click_delay
  return config
end

string.lpad = function(str, len, char)
  if char == nil then
    char = ' '
  end
  if len <= 0 then
    return str
  else
    return str .. string.rep(char, len - 1)
  end
end

function seed_list(config)

end

function default_deep_config()
  return {
    ["plants"] = {
      ['Cabbages'] = {
        ["Mut's Fruiton"] = {
          ["type"] = "Cabbages",
          ["waters"] = 1,
          ["stages"] = 3,
          ["yield"] = 1,
          ["stage_advance_timings"] = {
            [1] = 16000,
            [2] = 15000,
            [3] = 15000,
          }
        },
        ["Bastet's Yielding"] = {
          ["type"] = "Cabbages",
          ["waters"] = 2,
          ["stages"] = 3,
          ["yield"] = 2,
          ["stage_advance_timings"] = {
            [1] = 16000,
            [2] = 15000,
            [3] = 15000,
          }
        },
      },
      ["Carrots"] = {
        ["Green Leaf"] = {
          ["type"] = "Carrots",
          ["waters"] = 2,
          ["stages"] = 3,
          ["yield"] = 2,
          ["stage_advance_timings"] = {
            [1] = 16500,
            [2] = 16000,
            [3] = 16000,
          }
        },
        ["Osiris' Orange"] = {
          ["type"] = "Carrots",
          ["waters"] = 1,
          ["stages"] = 3,
          ["yield"] = 1,
          ["stage_advance_timings"] = {
            [1] = 16500,
            [2] = 16000,
            [3] = 16000,
          }
        },
      },
      ["Cucumbers"] = {
        ["Wadjet's Garden"] = {
          ["type"] = "Cucumbers",
          ["waters"] = 2,
          ["stages"] = 3,
          ["yield"] = 2,
          ["stage_advance_timings"] = {
            [1] = 16000,
            [2] = 13000,
            [3] = 13000,
          }
        },
        ["Ma'ats Plow"] = {
          ["type"] = "Cucumbers",
          ["waters"] = 1,
          ["stages"] = 3,
          ["yield"] = 1,
          ["stage_advance_timings"] = {
            [1] = 16000,
            [2] = 13000,
            [3] = 13000,
          }
        },
        ["Isis' Bounty"] = {
          ["type"] = "Cucumbers",
          ["waters"] = 3,
          ["stages"] = 4,
          ["yield"] = 4,
          ["stage_advance_timings"] = {
            [1] = 16000,
            [2] = 13000,
            [3] = 13000,
            [4] = 13000,
          }
        },
      },
      ['Garlic'] = {
        ["Apep's Crop"] = {
          ["type"] = "Garlic",
          ["waters"] = 2,
          ["stages"] = 3,
          ["yield"] = 2,
          ["stage_advance_timings"] = {
            [1] = 17000,
            [2] = 16000,
            [3] = 16000,
          }
        },
        ["Heket's Reaping"] = {
          ["type"] = "Garlic",
          ["waters"] = 1,
          ["stages"] = 3,
          ["yield"] = 1,
          ["stage_advance_timings"] = {
            [1] = 17000,
            [2] = 16000,
            [3] = 16000,
          }
        },
      },
      ['Leeks'] = {
        ["Hapi's Harvest"] = {
          ["type"] = "Leeks",
          ["waters"] = 1,
          ["stages"] = 3,
          ["yield"] = 1,
          ["stage_advance_timings"] = {
            [1] = 15000,
            [2] = 13500,
            [3] = 13500,
          }
        },
        ["Horus' Grain"] = {
          ["type"] = "Leeks",
          ["waters"] = 3,
          ["stages"] = 3,
          ["yield"] = 2,
          ["stage_advance_timings"] = {
            [1] = 15000,
            [2] = 13500,
            [3] = 13500,
          }
        },
      },
      ['Onions'] = {
        ["Tears of Sinai"] = {
          ["type"] = "Onions",
          ["waters"] = 2,
          ["stages"] = 3,
          ["yield"] = 2,
          ["stage_advance_timings"] = {
            [1] = 15768.55,
            [2] = 15065.37,
            [3] = 15749.1,
          }
        },
        ["Amun's Bounty"] = {
          ["type"] = "Onions",
          ["waters"] = 1,
          ["stages"] = 3,
          ["yield"] = 1,
          ["stage_advance_timings"] = {
            [1] = 11872.1,
            [2] = 11372.2,
            [3] = 11397.6,
          }
        },
      },
      ["Peppers"] = {
        ["Isis' Bounty"] = {
          ["type"] = "Peppers",
          ["waters"] = 3,
          ["stages"] = 4,
          ["yield"] = 4,
          ["stage_advance_timings"] = {
            [1] = 16000,
            [2] = 13000,
            [3] = 13000,
            [4] = 13000,
          }
        },
        ["Ptah's Breed"] = {
          ["type"] = "Peppers",
          ["waters"] = 2,
          ["stages"] = 3,
          ["yield"] = 2,
          ["stage_advance_timings"] = {
            [1] = 16000,
            [2] = 13000,
            [3] = 13000,
          }
        },
        ["Ra's Fire"] = {
          ["type"] = "Peppers",
          ["waters"] = 1,
          ["stages"] = 3,
          ["yield"] = 1,
          ["stage_advance_timings"] = {
            [1] = 16000,
            [2] = 13000,
            [3] = 13000,
          }
        },
      },
      ["Watermelon"] = {
        ["Isis' Bounty"] = {
          ["type"] = "Watermelon",
          ["waters"] = 3,
          ["stages"] = 4,
          ["yield"] = 4,
          ["stage_advance_timings"] = {
            [1] = 16000,
            [2] = 13000,
            [3] = 13000,
            [4] = 13000,
          }
        },
        ["Set's Vintage"] = {
          ["type"] = "Watermelon",
          ["waters"] = 2,
          ["stages"] = 3,
          ["yield"] = 2,
          ["stage_advance_timings"] = {
            [1] = 16000,
            [2] = 13000,
            [3] = 13000,
          }
        },
        ["Geb's Produce"] = {
          ["type"] = "Watermelon",
          ["waters"] = 1,
          ["stages"] = 3,
          ["yield"] = 1,
          ["stage_advance_timings"] = {
            [1] = 16000,
            [2] = 13000,
            [3] = 13000,
          }
        },
      },
      ["Eggplant"] = {
        ["Stranger's Solana"] = {
          ["type"] = "Eggplant",
          ["waters"] = 2,
          ["stages"] = 4,
          ["yield"] = 2,
          ["stage_advance_timings"] = {
            [1] = 16000,
            [2] = 13000,
            [3] = 13000,
            [4] = 13000,
          }
        },
        ["Qetesh's Soil"] = {
          ["type"] = "Eggplant",
          ["waters"] = 2,
          ["stages"] = 3,
          ["yield"] = 2,
          ["stage_advance_timings"] = {
            [1] = 16000,
            [2] = 13000,
            [3] = 13000,
          }
        },
        ["Isis' Bounty"] = {
          ["type"] = "Eggplant",
          ["waters"] = 3,
          ["stages"] = 4,
          ["yield"] = 4,
          ["stage_advance_timings"] = {
            [1] = 16000,
            [2] = 13000,
            [3] = 13000,
            [4] = 13000,
          }
        },
        ["Isis Seed"] = {
          ["type"] = "Eggplant",
          ["waters"] = 1,
          ["stages"] = 1,
          ["yield"] = 1,
          ["stage_advance_timings"] = {
            [1] = 16000,
          }
        },

      },
    },
    ["required_number_of_changed_pixels_before_clicking"] = {
      ["Leeks"] = 75,
      ["Cabbages"] = 25,
      ["Garlic"] = 25,
      ["Carrots"] = 50,
      ["Onions"] = 100,
      ["Default"] = 100,
    },
    ["plant_yield_bonus"] = 0,
    ["click_delay"] = 100,
    ["alternate_drag"] = true,
    ["pre_look"] = true,
    ["debug_log_level"] = NAME_TO_LOG_LEVEL['INFO'],
    ["num_calibration_runs"] = 10,
    ["record_plant_animation"] = true,
    ["reposition_avatar"] = true,
    ["sorting_mode"] = true,
    ["search_for_seed_bags"] = true,
    ["check_for_water_button"] = false,
    ["show_debug_images"] = false,
    ["only_click_when_pixel_changes_mode"] = false,
    ["plant_search_uses_equality"] = false,
    ["end_of_run_wait"] = 3000,
    ["onion_calibration_mode_change_threshold"] = 4.5,
    ["non_onion_calibration_mode_change_threshold"] = 1,
    ["num_char_snaps"] = 10,
    ["num_plant_snaps"] = 10,
    ["planting_batch_size"] = {
      ["Default"] = 1,
    },
    ["default_plant_location_order"] = {
      { direction = "SOUTH", number_of_moves = 2 },
      { direction = "NORTH", number_of_moves = 2 },
      { direction = "EAST", number_of_moves = 2 },
      { direction = "WEST", number_of_moves = 2 },
      { direction = "SOUTH_EAST", number_of_moves = 1 },
      { direction = "NORTH_WEST", number_of_moves = 1 },
      { direction = "NORTH_EAST", number_of_moves = 1 },
      { direction = "SOUTH_WEST", number_of_moves = 1 },
      { direction = "SOUTH_EAST", number_of_moves = 2 },
      { direction = "NORTH_WEST", number_of_moves = 2 },
      { direction = "NORTH_EAST", number_of_moves = 2 },
      { direction = "SOUTH_WEST", number_of_moves = 2 },
    },
    ["harvest_delay_time"] = 2500,
    ["calibration_mode_percentile"] = 99,
    ["calibration_mode_buffer_ms"] = 1000,
  }
end

function drawNumberEditBox(key, text, default)
  return drawEditBox(key, text, default, "number")
end

function drawPosNumberEditBox(key, text, default)
  return drawEditBox(key, text, default, "pos_number")
end

function drawEditBox(key, text, default, validation_type, width)
  drawWrappedTextUsingCurrent(text, WHITE)
  if not width then
    width = lsPrint(-100, -100, 10, 0.7, 0.7, WHITE, text)
  end
  local height = 30
  local done, result = lsEditBox(key, X_PADDING, current_y, 0, width, height, 1.0, 1.0, BLACK, default)
  local error = false
  if validation_type == "number" or validation_type == true then
    result = tonumber(result)
    if not result then
      error = "Please enter a valid number!"
    end
  elseif validation_type == "pos_number" then
    result = tonumber(result)
    if not result or result < 1 then
      error = "Please enter a valid number greater than 0!"
    end
  elseif validation_type == "percentage" then
    result = tonumber(result)
    if not result then
      error = "Please enter a valid number!"
    else
      if result <= 0 or result > 100 then
        result = false
        error = "Please enter a valid percentage (1-100)!"
      end
    end
  elseif result == "" then
    error = "Enter text!"
    result = false
  end
  if not result then
    drawText(error, RED, X_PADDING + width + 5, current_y + 5)
    result = false
  end
  current_y = current_y + 35
  return result
end

function drawTextUsingCurrent(text, colour)
  if not colour then
    colour = WHITE
  end
  drawText(text, colour, X_PADDING, current_y)
  current_y = current_y + 25
end
function drawWrappedTextUsingCurrent(text, colour)
  current_y = current_y + lsPrintWrapped(X_PADDING, current_y, 10, lsGetWindowSize()[0] - 10, 0.6, 0.6, colour, text)
end

function drawText(text, colour, x, y)
  lsPrint(x, y, 10, 0.7, 0.7, colour, text)
end

function drawWrappedText(text, colour, x, y)
  current_y = current_y + lsPrintWrapped(x, y, 10, lsGetWindowSize()[0] - 10, 0.6, 0.6, colour, text)
end

function drawBottomButton(xOffset, text, colour)
  return lsButtonText(lsScreenX - xOffset, lsGetWindowSize()[1] - 30, z, 100, colour or WHITE, text)
end

function string:split(inSplitPattern, outResults)
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find(self, inSplitPattern, theStart)
  while theSplitStart do
    table.insert(outResults, string.sub(self, theStart, theSplitStart - 1))
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find(self, inSplitPattern, theStart)
  end
  table.insert(outResults, string.sub(self, theStart))
  return outResults
end

function drawBoxOfPixelsTurningRedWhereDiff(box, pixels, new_pixels)
  local done = false
  while not done do
    for y = 0, box.height, 1 do
      for x = 0, box.width do
        local pixel = pixels[y][x]
        local new_pixel = new_pixels[y][x]
        local same = compareColorEx(pixel, new_pixel, 1000, 1000)
        if not same then
          lsDisplaySystemSprite(1, x, y, 1, 1, 1, RED)
        else
          lsDisplaySystemSprite(1, x, y, 1, 1, 1, pixel)
        end
      end
    end
    lsDoFrame()
    lsSleep(100)
    done = done or drawBottomButton(lsScreenX - 5, o.done_button_text or "Done")
    if drawBottomButton(110, "Exit Script", RED) then
      error "Script exited by user"
    end
  end
end

function readScreenDrawBox(box)
  srReadScreen()
  for y = box.top, box.top + box.height, 1 do
    for x = box.left, box.left + box.width do
      local pixel = srReadPixelFromBuffer(box.left + x, box.top + y)
      lsDisplaySystemSprite(1, x - box.left, y - box.top, 1, 1, 1, pixel)
    end
  end
  lsDoFrame()
end
