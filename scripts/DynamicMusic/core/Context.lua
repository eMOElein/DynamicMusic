---@class Context
---@field player any The player object for this context.
local Context = {

}

---@return Context context A context instance
function Context.Create()
    local context = {}

    context.player = nil

    return context
end

return Context