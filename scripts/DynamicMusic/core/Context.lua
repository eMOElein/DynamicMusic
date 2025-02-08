---@class Context
---@field player any The player object for this context.
local Context = {

}

---@return Context context A context instance
---@param player any the OpenMW player object for this context.
function Context.Create(player)
    local context = {}

    context.player = player

    return context
end

return Context