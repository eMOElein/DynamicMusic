local world = require('openmw.world')

local initialized = false
local players = {}

local function sendGlobalData(player)
  print("send global data to player: " ..player.id)
  local cellNames = {}
  local regionNames = {}
  local regionNamesSet = {}

  for _, cell in ipairs(world.cells) do
    if cell.name ~= '' then
      --   print("addingCell: " ..cell.name)
      table.insert(cellNames, cell.name)
      regionNamesSet[cell.region] = true
    end
  end

  for regionName, _ in pairs(regionNamesSet) do
    table.insert(regionNames, regionName)
  end

  local data = {
    cellNames = cellNames,
    regionNames = regionNames
  }

  player:sendEvent("globalDataCollected", { data = data });
end

local function initialize()
end

local function onLoad()
end

local function onInit()
end

local function onUpdate()
  for _, player in ipairs(world.players) do
    if not players[player.id] then
      sendGlobalData(player)
      players[player.id] = true
    end
  end
end

return {
  engineHandlers = {
    onInit = onInit,
    onLoad = onLoad,
    onUpdate = onUpdate
  }
}
