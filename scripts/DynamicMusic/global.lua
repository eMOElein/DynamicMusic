local world = require('openmw.world')

local cellDict = {}

local initialized = false

local function globalDataCollected(data)
  for _,player in ipairs(world.players) do
    player:sendEvent("globalDataCollected", { data = data });
  end
end

local function initialize()
  if initialized then
    return
  end

  print("initializing global script")
  local cellNames = {}

  for _,cell in ipairs(world.cells) do
    if cell.name ~= '' then
      --   print("addingCell: " ..cell.name)
      table.insert(cellNames,cell.name)
    end
  end

  globalDataCollected({cellNames = cellNames})

  initialized = true
end

local function onLoad()
  initialize()
end

local function onInit()
  initialize()
end

return {
  engineHandlers = {
    onInit = onInit,
    onLoad = onLoad
  }
}
