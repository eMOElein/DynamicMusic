local LogLevel = require('scripts.DynamicMusic.core.LogLevel')

--- @class Logger
--- @field _printerDB [LogLevel, function]
local Logging = {}

local _printerDB = {}
_printerDB[LogLevel.DEBUG] = Logging.debug
_printerDB[LogLevel.INFO] = Logging.info
_printerDB[LogLevel.ERROR] = Logging.info
_printerDB[LogLevel.WARN] = Logging.info

--- @param message string
--- @param logLevel LogLevel
function Logging.log(message, logLevel)
    _printerDB[logLevel](message)
end

function Logging.info(message)
    print(message)
end

function Logging.debug(message)
    print(message)
end

function Logging.warn(message)
    print(message)
end

function Logging.error(message)
    print(message)
end

return Logging