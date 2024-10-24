local StringUtils = {}

--Splits a string by a separator and retruns the splitted strings in a new table.
---@param string string The string to split.
---@param separator string The separator that should be used for splitting.
---@return table<string> splitted The nwe table with the splittet substrings.
function StringUtils.split(string, separator)
    local t = {}
    for str in string.gmatch(string, "([^" .. separator .. "]+)") do
        table.insert(t, str)
    end
    return t
end

return StringUtils