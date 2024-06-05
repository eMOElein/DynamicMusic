local ambient = require('openmw.ambient')
local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')

local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local GameState = require('scripts.DynamicMusic.core.GameState')
local DynamicMusic = require('scripts.DynamicMusic.core.DynamicMusic')
local Settings = require('scripts.DynamicMusic.core.Settings')

local hostileActors = {}
local initialized = false

local function isCombatState()
  if not Settings.getValue(Settings.KEYS.COMBAT_PLAY_COMBAT_MUSIC) then
    return false
  end

  local playerLevel = types.Actor.stats.level(self).current
  local minLevelEnemy = Settings.getValue(Settings.KEYS.COMBAT_MIN_ENEMY_LEVEL)
  local minLevelDifference = Settings.getValue(Settings.KEYS.COMBAT_MIN_LEVEL_DIFFERENCE)

  for _, hostile in pairs(hostileActors) do
    local actor = hostile.actor
    if types.Actor.isInActorsProcessingRange(actor) then
      local hostileLevel = types.Actor.stats.level(actor).current
      local inProcessingRange = types.Actor.isInActorsProcessingRange(actor)
      local playerLevelAdvantage = playerLevel - hostileLevel

      if inProcessingRange and (hostileLevel >= minLevelEnemy or playerLevelAdvantage < minLevelDifference) then
        return true
      end
    end
  end

  return false
end

local function getPlayerState()
  if isCombatState() then
    return PlayerStates.combat
  end

  return PlayerStates.explore
end

local function hasGameStateChanged()
  if GameState.playerState.previous ~= GameState.playerState.current then
    -- print("change playerState: " ..gameState.playerState.current)
    return true
  end

  if not ambient.isMusicPlaying() then
    -- print("change music not playing")
    return true
  end

  if GameState.regionName.current ~= GameState.regionName.previous then
    -- print("change regionName")
    return true
  end

  if GameState.cellName.current ~= GameState.cellName.previous then
    -- print("change celName")
    return true
  end

  return false
end

local function initialize()
  if not initialized then
    initialized = true

    local omwMusicSettings = storage.playerSection('SettingsOMWMusic')
    if omwMusicSettings then
      print("changing built in openmw combat music setting to false")
      omwMusicSettings:set("CombatMusicEnabled", false)
    end
  end
end

local function onFrame(dt)
  if not DynamicMusic.initialized then
    return
  end

  if not initialized then
    initialize()
  end

  GameState.exterior.current = self.cell and self.cell.isExterior
  GameState.cellName.current = self.cell and self.cell.name or ""
  GameState.playtime.current = os.time()
  GameState.regionName.current = self.cell and self.cell.region or ""
  GameState.playerState.current = getPlayerState()

  if hasGameStateChanged() then
    DynamicMusic.newMusic()
  end

  DynamicMusic.update(dt)

  GameState.exterior.previous = GameState.exterior.current
  GameState.cellName.previous = GameState.cellName.current
  GameState.playtime.previous = GameState.playtime.current
  GameState.playerState.previous = GameState.playerState.current
  GameState.regionName.previous = GameState.regionName.current
  GameState.soundBank.previous = GameState.soundBank.current
  GameState.track.previous = GameState.track.current
end

local function engaging(eventData)
  if (not eventData.actor) then
    return
  end

  if not eventData.targetActor or eventData.targetActor.id ~= self.id then
    return
  end

  hostileActors[eventData.actor.id] = eventData;
  --  print("engaging: " ..eventData.actor.id .." - " ..eventData.actor.recordId ..eventData.name)
end

local function disengaging(eventData)
  if (not eventData.actor) then return end;

  hostileActors[eventData.actor.id] = nil;
end

local function globalDataCollected(eventData)
  local data = eventData.data

  DynamicMusic.initialize(data.cellNames, data.regionNames, hostileActors)

  data = nil
end

return {
  engineHandlers = {
    onFrame = onFrame
  },
  eventHandlers = {
    engaging = engaging,
    disengaging = disengaging,
    globalDataCollected = globalDataCollected
  },
}
