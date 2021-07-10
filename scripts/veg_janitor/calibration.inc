dofile("veg_janitor/io.inc")
dofile("veg_janitor/binsert.inc")
dofile("veg_janitor/logger.inc")

CALIBRATION_LOG_FILE_NAME = "calibration_data_log"

function calibration_log_header()
  local row = {}
  table.insert(row, "version")
  table.insert(row, "row_type")
  table.insert(row, "config_name")
  table.insert(row, "plant_number")
  table.insert(row, "plant_time")
  table.insert(row, "prev_stage")
  table.insert(row, "new_stage")
  table.insert(row, "now")
  table.insert(row, "time_since_plant")
  table.insert(row, "time_since_prev_stage")
  table.insert(row, "config_num_runs")
  table.insert(row, "config_num_plants")
  table.insert(row, "config_seed_type")
  table.insert(row, "config_seed_name")
  return row
end

function create_calibration_stage_time_log_row(config,
                                               plant_number,
                                               plant_time,
                                               prev_stage,
                                               new_stage,
                                               now,
                                               time_since_plant,
                                               time_since_prev_stage
)
  local row = {}
  table.insert(row, "v0.1")
  table.insert(row, "STAGE_TIME")
  table.insert(row, config.name)
  table.insert(row, plant_number)
  table.insert(row, plant_time)
  table.insert(row, prev_stage)
  table.insert(row, new_stage)
  table.insert(row, now)
  table.insert(row, time_since_plant)
  table.insert(row, time_since_prev_stage)
  table.insert(row, config.num_runs)
  table.insert(row, config.num_plants)
  table.insert(row, config.seed_type)
  table.insert(row, config.seed_name)
  return row
end
function calibration_stage_time_row_to_table(row)
  local table = {}
  for i, value in ipairs(calibration_log_header()) do
    local possibly_a_number = tonumber(row[i])
    if possibly_a_number == nil then
      table[value] = row[i]
    else
      table[value] = possibly_a_number
    end
  end
  return table
end

function filter_table_by_config_and_seed(csv_table, config, config_seed_type, config_seed_name)
  local rows_per_stage = {}
  for i = #csv_table, 1, -1 do
    if i == 1 then
      -- Ignore header row
      break
    end
    local row = csv_table[i]
    local row_table = calibration_stage_time_row_to_table(row)
    local config_name = row_table["config_name"]
    local seed_type = row_table["config_seed_type"]
    local seed_name = row_table["config_seed_name"]
    if config.name == config_name and config_seed_type == seed_type and config_seed_name == seed_name then
      local row_type = row_table["row_type"]
      if row_type == "RESET" then
        break
      end
      local new_stage = row_table["new_stage"]
      if not rows_per_stage[new_stage] then
        rows_per_stage[new_stage] = {}
      end
      local fcomp = function(a, b)
        return a["time_since_prev_stage"] < b["time_since_prev_stage"]
      end
      table.binsert(rows_per_stage[new_stage], row_table, fcomp)
    end
  end
  return rows_per_stage
end
function filter_stages_by_std_dev_from_mean(stages, num_of_std_devs_from_mean_for_max, config)
  local total = 0
  for i = 1, #stages do
    local stage = stages[i]
    local time_since_prev_stage = stage["time_since_prev_stage"]
    total = total + time_since_prev_stage
  end
  local mean = total / #stages
  local total_square_diffs = 0
  for i = 1, #stages do
    local stage = stages[i]
    local time_since_prev_stage = stage["time_since_prev_stage"]
    local diff = time_since_prev_stage - mean
    total_square_diffs = total_square_diffs + diff * diff
  end
  local mean_of_squared_diffs = total_square_diffs / #stages
  local std_dev = math.sqrt(mean_of_squared_diffs)

  local filtered_stages = {}
  local max_distance = std_dev * num_of_std_devs_from_mean_for_max
  _log(INFO, config, 'Mean is ' .. mean)
  _log(INFO, config, 'Std Dev is ' .. std_dev)
  _log(INFO, config, 'Only allowing values between ' .. mean - max_distance .. ' and ' .. mean + max_distance )
  for i = 1, #stages do
    local stage = stages[i]
    local time_since_prev_stage = stage["time_since_prev_stage"]
    if math.abs(time_since_prev_stage - mean) <= max_distance then
      table.insert(filtered_stages, stage)
    else
      _log(INFO, config, 'Filtering ' .. time_since_prev_stage)
    end
  end
  return filtered_stages
end

function quantile(t, key, q)
  local rank = (#t - 1) * (q / 100) + 1
  local floored_rank = math.floor(rank)
  local rem = rank - floored_rank
  if rem == 0 then
    return t[floored_rank][key]
  else
    return t[floored_rank][key] + rem * (t[floored_rank + 1][key] - t[floored_rank][key])
  end
end

function _log(level, config, message)
  veg_log(level, config.debug_log_level, 'calibration.inc', message)
end

function calculate_and_update_calibration_settings(config, seed_type, seed_name)
  -- Reload the config from file to ensure we dont write out any in-memory only config values

  local csv_table = readCsvFrom(CALIBRATION_LOG_FILE_NAME)
  local filtered_table_stages = filter_table_by_config_and_seed(csv_table, config, seed_type, seed_name)
  local stages = config.plants[seed_type][seed_name].stages + 1
  local timings = config.plants[seed_type][seed_name].stage_advance_timings or {}
  config.plants[seed_type][seed_name].stage_advance_timings = timings
  _log(INFO, config, 'Calibration Run Details for ' .. seed_type .. ' - ' .. seed_name)
  if not filtered_table_stages[2] then
    _log(INFO, config, 'No data points found')
    timings["calibrated"] = false
    timings["data_points"] = 0
  else
    for i = 2, stages do
      local data_points = filtered_table_stages[i]
      local data_points_with_2_std_dev_of_mean = filter_stages_by_std_dev_from_mean(data_points, 2, config)
      _log(INFO, config, 'Started with ' .. #data_points .. ' data points, filtered down to ' .. #data_points_with_2_std_dev_of_mean)
      local q = quantile(data_points_with_2_std_dev_of_mean, "time_since_prev_stage", config.calibration_mode_percentile)
      local timing = q + config.calibration_mode_buffer_ms
      timings[i - 1] = timing
    end
    timings["calibrated"] = true
    timings["data_points"] = #filtered_table_stages[2]
  end
  timings["calibration_version"] = 1
  write_config(config)
  return config
end

function calibration_insert_reset_row(config_name, seed_type, seed_name)
  local row = {}
  table.insert(row, "v0.1")
  table.insert(row, "RESET")
  table.insert(row, config_name)
  table.insert(row, "")
  table.insert(row, "")
  table.insert(row, "")
  table.insert(row, "")
  table.insert(row, "")
  table.insert(row, "")
  table.insert(row, "")
  table.insert(row, "")
  table.insert(row, "")
  table.insert(row, seed_type)
  table.insert(row, seed_name)
  writeCsvFileTo(CALIBRATION_LOG_FILE_NAME, { [1] = row }, true)
end


function apply_calibration_fix(config, change)
  if config.seed_type == 'Onions' then
    config.onion_calibration_mode_change_threshold = config.onion_calibration_mode_change_threshold + change
  else
    config.non_onion_calibration_mode_change_threshold = config.non_onion_calibration_mode_change_threshold + change
  end
  write_config(config)
end
