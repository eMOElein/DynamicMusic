local TableUtils = {}

function TableUtils.getFirstElement(table)
    for _, e in pairs(table) do
        return e
    end
end

function TableUtils.countKeys(table)
    local counter = 0

    for _, e in pairs(table) do
        counter = counter +1
    end

    return counter
end

return TableUtils