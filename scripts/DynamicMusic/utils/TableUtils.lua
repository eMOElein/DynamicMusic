local TableUtils = {}

function TableUtils.getFirstElement(table)
    for _, e in pairs(table) do
        return e
    end
end

return TableUtils