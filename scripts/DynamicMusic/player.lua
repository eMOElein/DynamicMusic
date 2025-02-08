local Globals = require('scripts.DynamicMusic.core.Globals')
local core = require('openmw.core')

if core.API_REVISION < Globals.LUA_API_REVISION_MIN then
  return nil
end

local ambient = require('openmw.ambient')
local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')

local GlobalData = require('scripts.DynamicMusic.core.GlobalData')
local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local GameState = require('scripts.DynamicMusic.core.GameState')
local Context = require('scripts.DynamicMusic.core.Context')
local DynamicMusic = require('scripts.DynamicMusic.core.DynamicMusic')
local Settings = require('scripts.DynamicMusic.core.Settings')

local dynamicMusic = {}
local initialized = false
local musicDelayTimer = nil

local function isCombatState()
  if not Settings.getValue(Settings.KEYS.COMBAT_PLAY_COMBAT_MUSIC) then
    return false
  end

  local playerLevel = types.Actor.stats.level(self).current
  local minLevelEnemy = Settings.getValue(Settings.KEYS.COMBAT_MIN_ENEMY_LEVEL)
  local minLevelDifference = Settings.getValue(Settings.KEYS.COMBAT_MIN_LEVEL_DIFFERENCE)
  local respectMinLevelDifference = Settings.getValue(Settings.KEYS.COMBAT_ENEMIES_IGNORE_RESPECT_LEVEL_DIFFERENCE)

  for _, hostile in pairs(GlobalData.hostileActors) do
    local actor = hostile.actor
    local hostileLevel = types.Actor.stats.level(actor).current
    local playerLevelAdvantage = playerLevel - hostileLevel
    local inProcessingRange = types.Actor.isInActorsProcessingRange(actor)

    if not inProcessingRange then
      goto continue
    end

    if dynamicMusic.includeEnemies[hostile.id] then
      return true
    end

    if dynamicMusic.ignoreEnemies[hostile.id] then
      if respectMinLevelDifference and playerLevelAdvantage < minLevelDifference then
        return true
      end

      goto continue
    end

    if playerLevelAdvantage < minLevelDifference then
      return true
    end

    if hostileLevel >= minLevelEnemy then
      return true
    end

    ::continue::
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
    return true
  end

  if GameState.regionName.current ~= GameState.regionName.previous then
    --print("change regionName ")
    if GameState.exterior.current and GameState.exterior.previous then
      musicDelayTimer = Settings.getValue(Settings.KEYS.GENERAL_EXTERIOR_DELAY)
      return false
    else
      return true
    end
  end

  if GameState.cellName.current ~= GameState.cellName.previous then
    --print("change celName")
    if GameState.exterior.current and GameState.exterior.previous then
      musicDelayTimer = Settings.getValue(Settings.KEYS.GENERAL_EXTERIOR_DELAY)
      return false
    else
      return true
    end
  end

  if musicDelayTimer and musicDelayTimer <= 0 then
    --print("change delayTimer")
    musicDelayTimer = nil
    return true
  end

  if GameState.hourOfDay.current ~= GameState.hourOfDay.previous then
    --    print(string.format("hour of day changed from %i to %i", GameState.hourOfDay.previous, GameState.hourOfDay.current))
    return true
  end

  return false
end

local function initialize()
  if not initialized then
    local context = Context.Create()
    context.player = self

    dynamicMusic = DynamicMusic.Create(context)
    dynamicMusic:initialize()
    initialized = true

    local omwMusicSettings = storage.playerSection('SettingsOMWMusic')
    if omwMusicSettings then
      print("changing built in openmw combat music setting to false")
      omwMusicSettings:set("CombatMusicEnabled", false)
    end
  end
end

local function onFrame(dt)
  if not initialized then
    return
  end

  local hourOfDay = math.floor((core.getGameTime() / 3600) % 24)
  if musicDelayTimer and musicDelayTimer > 0 then
    musicDelayTimer = musicDelayTimer - dt
  end

  GameState.exterior.current = self.cell and self.cell.isExterior
  GameState.cellName.current = self.cell and self.cell.name or ""
  GameState.playtime.current = os.time()
  GameState.regionName.current = self.cell and self.cell.region or ""
  GameState.playerState.current = getPlayerState()
  GameState.hourOfDay.current = hourOfDay

  if hasGameStateChanged() then
    musicDelayTimer = nil
    dynamicMusic:newMusic()
  end

  dynamicMusic:update(dt)

  GameState.exterior.previous = GameState.exterior.current
  GameState.cellName.previous = GameState.cellName.current
  GameState.playtime.previous = GameState.playtime.current
  GameState.playerState.previous = GameState.playerState.current
  GameState.regionName.previous = GameState.regionName.current
  GameState.soundbank.previous = GameState.soundbank.current
  GameState.hourOfDay.previous = GameState.hourOfDay.current
end

local function engaging(eventData)
  if (not eventData.actor) then
    return
  end

  if not eventData.targetActor or eventData.targetActor.id ~= self.id then
    return
  end

  GlobalData.hostileActors[eventData.actor.id] = eventData;
  --  print("engaging: " ..eventData.actor.id .." - " ..eventData.actor.recordId ..eventData.name)
end

local function disengaging(eventData)
  if (not eventData.actor) then return end;

  GlobalData.hostileActors[eventData.actor.id] = nil;
end

local function globalDataCollected(eventData)
  local data = eventData.data

  GlobalData.cellNames = data.cellNames
  GlobalData.regionNames = data.regionNames

  initialize()
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
