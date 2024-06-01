local ambient = require('openmw.ambient')
local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')

local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local GameState = require('scripts.DynamicMusic.core.GameState')
local DynamicMusic = require('scripts.DynamicMusic.core.DynamicMusic')
local SB = require('scripts.DynamicMusic.core.SoundBank')
local Settings = require('scripts.DynamicMusic.core.Settings')

local DEFAULT_SOUNDBANK = require('scripts.DynamicMusic.soundBanks.DEFAULT')

local hostileActors = {}
local currentPlaybacktime = -1
local currentTrackLength = -1
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

local function fetchSoundbank()
  local soundbank = nil

  for index = #DynamicMusic.soundBanks, 1, -1 do
    if DynamicMusic.isSoundBankAllowed(DynamicMusic.soundBanks[index]) then
      soundbank = DynamicMusic.soundBanks[index]
      break
    end
  end

  local useDefaultSoundbank = false
  --useDefaultSoundbank = advancedSettings:get(Settings.USE_DEFAULT_SOUNDBANK)
  useDefaultSoundbank = Settings.getValue(Settings.KEYS.GENERAL_USE_DEFAULT_SOUNDBANK)

  if not soundbank and useDefaultSoundbank then
    print("using DEFAULT soundbank")
    soundbank = DEFAULT_SOUNDBANK
  end

  return soundbank
end

---Plays another track from an allowed soundbank
-- Chooses a fitting soundbank and plays a track from it
-- If no soundbank could be found a vanilla track is played
--local function newMusic()
--  print("new music requested")

--  local soundBank = fetchSoundbank()

-- force new music when streammusic was used in the ingame console
--  if not ambient.isMusicPlaying() then
--    GameState.soundBank.current = nil
--  end

--if no playerState change happened and the same soundbank should be played again then continue playback
--  if GameState.playerState.current == GameState.playerState.previous then
--    if GameState.soundBank.current == soundBank and currentPlaybacktime < currentTrackLength then
--      print("skipping new track and continue with current")
--      return
--    end
--  end

-- no matching soundbank available - switching to default music and return
--  if not soundBank then
--    print("no matching soundbank found")

--    if GameState.soundBank.current then
--      ambient.streamMusic('')
--    end

--    GameState.track.curent = nil
--    currentPlaybacktime = -1
--    GameState.soundBank.current = nil
--    GameState.track.current = nil
--    return
--  end

--  GameState.soundBank.current = soundBank

--  print("fetch track from: " .. soundBank.id)

-- reusing previous track if trackpath is available
--  if GameState.track.previous and (GameState.soundBank.current ~= GameState.soundBank.previous or GameState.playerState.current ~= GameState.playerState.previous) then
--    local tempTrack = SB.trackForPath(
--      GameState.soundBank.current,
--      GameState.playerState.current,
--      GameState.track.previous.path
--    )

--    if tempTrack then
--      print("resuming existing track from previous " .. GameState.track.previous.path)
--      GameState.track.current = tempTrack
--      return
--    end
--  end

--  local track = SB.fetchTrack(soundBank)
-- hopefully avoids default music being played on track end sometimes
--  if currentPlaybacktime >= currentTrackLength then
--    ambient.stopMusic()
--  end

--  currentPlaybacktime = 0

--  GameState.track.current = track
--  if track.length then
--    currentTrackLength = track.length
--  end

--  print("playing track: " .. track.path)
--  ambient.streamMusic(track.path)
--end

local function hasGameStateChanged()
  if GameState.playerState.previous ~= GameState.playerState.current then
    -- print("change playerState: " ..gameState.playerState.current)
    return true
  end

  if not ambient.isMusicPlaying() then
    -- print("change music not playing")
    return true
  end

  if currentTrackLength > -1 and currentPlaybacktime > currentTrackLength then
    -- print("change trackLength")
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

  if currentPlaybacktime > -1 then
    currentPlaybacktime = currentPlaybacktime + (GameState.playtime.current - GameState.playtime.previous)
  end

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
  if (not eventData.actor) then return end;

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
