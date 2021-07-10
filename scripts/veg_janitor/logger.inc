dofile("veg_janitor/io.inc")
VEG_JANITOR_LOG_FILE_NAME = 'v2_2_veg_janitor_debug_log.txt'

LOG_LEVEL_TO_NAME = {
  [1] = 'NONE',
  [2] = 'INFO',
  [3] = 'DEBUG',
  [4] = 'TRACE',
}
LOG_LEVEL_TO_LEVEL = {
  [1] = 1,
  [2] = 2,
  [3] = 3,
  [4] = 4,
}
NAME_TO_LOG_LEVEL = {
  ['NONE'] = 1,
  ['INFO'] = 2,
  ['DEBUG'] = 3,
  ['TRACE'] = 4,
}
NONE = NAME_TO_LOG_LEVEL['NONE']
INFO = NAME_TO_LOG_LEVEL['INFO']
DEBUG = NAME_TO_LOG_LEVEL['DEBUG']
TRACE = NAME_TO_LOG_LEVEL['TRACE']


function reset_log()
  serialize('', VEG_JANITOR_LOG_FILE_NAME, false, false)
end

function get_veg_log()
  return read_file_into_string("data/" .. VEG_JANITOR_LOG_FILE_NAME)
end

function veg_log(level, setLogLevel, file, message)
  if not message then
    message = 'BAD LOG LINE AT'
    print(message)
    print(debug.traceback())
    return
  end
  if not file then
    file = ''
  end
  message = '$' .. lsGetTimer() .. '-' .. file .. '-' .. LOG_LEVEL_TO_NAME[level] .. ': ' .. message
  if not setLogLevel then
    print(message)
  elseif setLogLevel >= level then
    print(message)
    serialize(message .. '\n', VEG_JANITOR_LOG_FILE_NAME, true, false)
  end
end
