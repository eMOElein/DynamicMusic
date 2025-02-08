--- @class LogLevel
--- @field INFO LogLevel
--- @field DEBUG LogLevel
--- @field WARN LogLevel
--- @field ERROR LogLevel
--- @field severity integer
local LogLevel = {}

function LogLevel.Create(name, severity)
    local level = {}

    level.name = name
    level.severity = severity

    return level
end

LogLevel.DEBUG = LogLevel.Create("DEBUG", 1)
LogLevel.INFO = LogLevel.Create("INFO",2)
LogLevel.WARN = LogLevel.Create("WARN", 3)
LogLevel.ERROR = LogLevel.Create("ERROR", 4)

return LogLevel
