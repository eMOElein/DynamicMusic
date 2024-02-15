local ambient = require('openmw.ambient')
local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local DynamicMusic = require('scripts.DynamicMusic.core.DynamicMusic')

local DEFAULT_SOUNDBANK = require('scripts.DynamicMusic.soundBanks.DEFAULT')

local Settings = {
  COMBAT_MIN_ENEMY_LEVEL = 'COMBAT_MIN_ENEMY_LEVEL',
  COMBAT_MIN_LEVEL_DIFFERENCE = 'COMBAT_MIN_LEVEL_DIFFERENCE',
  USE_DEFAULT_SOUNDBANK = 'USE_DEFAULT_SOUNDBANK'
}

local hostileActors = {}

local soundBanks = {}

local playerStates = {
  combat = 'combat',
  explore = 'explore'
}

local gameState = {
  exterior = {
    current = nil,
    previous = nil
  },
  cellName = {
    current = nil,
    previous = nil
  },
  playtime = {
    current = os.time(),
    previous = -1
  },
  playerState = {
    current = nil,
    previous = nil
  },
  regionName = {
    current = nil,
    previous = nil
  },
  soundBank = {
    current = nil,
    previous = nil
  },
  track = {
    curent = nil,
    previous = nil
  }
}

local SoundBank = {

  trackForPath = function(soundBank, playerState, trackPath)
    local tracks = {}

    if playerState == playerStates.explore then
      tracks = soundBank.tracks
    end

    if playerState == playerStates.combat then
      tracks = soundBank.combatTracks
    end

    for _, track in pairs(tracks) do
      if (track.path == trackPath) then
        return track
      end
    end
  end

}

I.Settings.registerPage {
  key = 'Dynamic_Music',
  l10n = 'Dynamic_Music',
  name = 'Dynamic Music',
  description = 'Dynamic Music Framework',
}
I.Settings.registerGroup {
  key = 'Dynamic_Music_Default_Settings',
  page = 'Dynamic_Music',
  l10n = 'Dynamic_Music',
  name = 'Combat',
  description = 'Combat related settings.',
  permanentStorage = true,
  settings = {
      {
          key = Settings.COMBAT_MIN_ENEMY_LEVEL,
          renderer = 'number',
          name = 'Min. Enemy Level',
          description = 'Minimum enemy level needed to play combat music. (Needs activated DEFAULT soundbank to work in areas where no soundbank matches)',
          default = 5,
      },
      {
        key = Settings.COMBAT_MIN_LEVEL_DIFFERENCE,
        renderer = 'number',
        name = 'Min. Level Difference',
        description = 'Ignore Min. Enemy Level if the player is not X levels above the enemy\'s level. (Needs activated DEFAULT soundbank to work in areas where no soundbank matches)',
        default = 2,
    },
  },
}

I.Settings.registerGroup {
  key = 'Dynamic_Music_Advanced_Settings',
  page = 'Dynamic_Music',
  l10n = 'Dynamic_Music',
  name = 'Advanced',
  description = 'Advanced Settings',
  permanentStorage = true,
  settings = {
      {
          key = Settings.USE_DEFAULT_SOUNDBANK,
          renderer = 'checkbox',
          name = 'Use DEFAULT Soundbank',
          description = 'Uses the DEFAULT soundbank if no other soundbank matches. If you have custom tracks in your vanilla playlist they will be ignored and need to be added to the DEFAULT soundbank manually.',
          default = true,
      }
  },
}

local playerSettings = storage.playerSection('Dynamic_Music_Default_Settings')
local advancedSettings = storage.playerSection('Dynamic_Music_Advanced_Settings')

local initialized = false

local currentPlaybacktime = -1
local currentTrackLength = -1

local function isCombatState()
  local playerLevel = types.Actor.stats.level(self).current
  local minLevelEnemy = playerSettings:get(Settings.COMBAT_MIN_ENEMY_LEVEL)
  local minLevelDifference = playerSettings:get(Settings.COMBAT_MIN_LEVEL_DIFFERENCE)

  for _, hostileActor in pairs(hostileActors) do
    if types.Actor.isInActorsProcessingRange(hostileActor) then
      local hostileLevel = types.Actor.stats.level(hostileActor).current
      local inProcessingRange = types.Actor.isInActorsProcessingRange(hostileActor)
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
    return playerStates.combat
  end

  return playerStates.explore
end

---Check if sound bank is allowed
-- Returns if the specified soundbank is allowed to play in the current ingame situation.
-- @param soundBank the soundbank that should be checked
-- @return true/false
local function isSoundBankAllowed(soundBank)
  if not soundBank then
    return false
  end

  if soundBank.interiorOnly and gameState.exterior.current then
    return false
  end

  if soundBank.exteriorOnly and not gameState.exterior.current then
    return false
  end

  if gameState.playerState.current == playerStates.explore then
    if not soundBank.tracks or #soundBank.tracks == 0 then
      return false
    end
  end

  if gameState.playerState.current == playerStates.combat then
    if not soundBank.combatTracks or #soundBank.combatTracks == 0 then
      return false
    end
  end

  if (soundBank.cellNames or soundBank.cellNamePatterns) and not DynamicMusic.isSoundBankAllowedForCellName(soundBank, gameState.cellName.current, true) then
    return false
  end

  if soundBank.regionNames and not DynamicMusic.isSoundBankAllowedForRegionName(soundBank, gameState.regionName.current, true) then
    return false
  end

  if soundBank.id == "DEFAULT" then
    return false
  end


  return true
end

local function contains(elements, element)
  for _, e in pairs(elements) do
    if (e == element) then
      return true
    end
  end
  return false
end

local function fetchRandomTrack(tracks, options)
  local allowedTracks = tracks

  if options and options.blacklist and #options.blacklist > 0 then
    allowedTracks = {}
    for _, t in pairs(tracks) do
      if not contains(options.blacklist, t) then
        table.insert(allowedTracks, t)
      end
    end
  end

  local rnd = math.random(1, #allowedTracks)
  local track = allowedTracks[rnd]

  return track
end

local function fetch_soundbank()
  local soundbank = nil

  for index = #soundBanks, 1, -1 do
    if isSoundBankAllowed(soundBanks[index]) then
      soundbank = soundBanks[index]
      break
    end
  end

  if not soundbank and advancedSettings:get(Settings.USE_DEFAULT_SOUNDBANK)then
    print("using DEFAULT soundbank")
    soundbank = DEFAULT_SOUNDBANK
  end

  return soundbank
end

local function fetchTrackFromSoundbank(soundBank)
  local track = nil
  local tracks = soundBank.tracks

  -- in case of combat situation use combat tracks
  if gameState.playerState.current == playerStates.combat and soundBank.combatTracks then
    tracks = soundBank.combatTracks
  end
  track = fetchRandomTrack(tracks)

  -- if new trackpath == previous trackpath try to fetch a different track
  if #tracks > 1 and (gameState.track.previous and track.path == gameState.track.previous.path or false) then
    print("searching for another track to avoid repeated playback of: " .. gameState.track.previous.path)
    track = fetchRandomTrack(tracks, { blacklist = { track } })
  end

  return track
end

---Plays another track from an allowed soundbank
-- Chooses a fitting soundbank and plays a track from it
-- If no soundbank could be found a vanilla track is played
local function newMusic()
  print("new music requested")

  local soundBank = fetch_soundbank()

  -- force new music when streammusic was used in the ingame console
  if not ambient.isMusicPlaying() then
    gameState.soundBank.current = nil
  end

  --if no playerState change happened and the same soundbank should be played again then continue playback
  if gameState.playerState.current == gameState.playerState.previous then
    if gameState.soundBank.current == soundBank and currentPlaybacktime < currentTrackLength then
      print("skipping new track and continue with current")
      return
    end
  end

  -- no matching soundbank available - switching to default music and return
  if not soundBank then
    print("no matching soundbank found")

    if gameState.soundBank.current then
      ambient.streamMusic('')
    end

    gameState.track.curent = nil
    currentPlaybacktime = -1
    gameState.soundBank.current = nil
    gameState.track.current = nil
    return
  end

  gameState.soundBank.current = soundBank

  print("fetch track from: " .. soundBank.id)


  -- reusing previous track if trackpath is available
  if gameState.track.previous and (gameState.soundBank.current ~= gameState.soundBank.previous or gameState.playerState.current ~= gameState.playerState.previous) then
    local tempTrack = SoundBank.trackForPath(
      gameState.soundBank.current,
      gameState.playerState.current,
      gameState.track.previous.path
    )

    if tempTrack then
      print("resuming existing track from previous " .. gameState.track.previous.path)
      gameState.track.current = tempTrack
      return
    end
  end

  local track = fetchTrackFromSoundbank(soundBank)

  -- hopefully avoids default music being played on track end sometimes
  if currentPlaybacktime >= currentTrackLength then
    ambient.stopMusic()
  end

  currentPlaybacktime = 0

  gameState.track.current = track
  if track.length then
    currentTrackLength = track.length
  end

  print("playing track: " .. track.path)
  ambient.streamMusic(track.path)
end

local function hasGameStateChanged()
  if gameState.playerState.previous ~= gameState.playerState.current then
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

  if gameState.regionName.current ~= gameState.regionName.previous then
    -- print("change regionName")
    return true
  end

  if gameState.cellName.current ~= gameState.cellName.previous then
    -- print("change celName")
    return true
  end

  return false
end

local function onFrame(dt)
  if not DynamicMusic.initialized then
    return
  end

  gameState.exterior.current = self.cell and self.cell.isExterior
  gameState.cellName.current = self.cell and self.cell.name or ""
  gameState.playtime.current = os.time()
  gameState.regionName.current = self.cell and self.cell.region or ""
  gameState.playerState.current = getPlayerState()

  if currentPlaybacktime > -1 then
    currentPlaybacktime = currentPlaybacktime + (gameState.playtime.current - gameState.playtime.previous)
  end

  if hasGameStateChanged() then
    newMusic()
  end

  gameState.exterior.previous = gameState.exterior.current
  gameState.cellName.previous = gameState.cellName.current
  gameState.playtime.previous = gameState.playtime.current
  gameState.playerState.previous = gameState.playerState.current
  gameState.regionName.previous = gameState.regionName.current
  gameState.soundBank.previous = gameState.soundBank.current
  gameState.track.previous = gameState.track.current
end

local function engaging(eventData)
  if (not eventData.actor) then return end;
  hostileActors[eventData.actor.id] = eventData.actor;
  print("engaging: " ..eventData.actor.recordId)
end

local function disengaging(eventData)
  if (not eventData.actor) then return end;
  hostileActors[eventData.actor.id] = nil;
end

local function globalDataCollected(eventData)
  print("COLLECTING GLOBAL DATA!!!!")
  local data = eventData.data

  DynamicMusic.initialize(data.cellNames, data.regionNames)
  soundBanks = DynamicMusic.soundBanks

  data = nil
end

local function initialize()
  if not initialized then
    print('initializing playerscript')
--    collectSoundBanks()
    initialized = true
  end
end

local function onInit(initData)
  initialize()
end

local function onLoad(initData)
  initialize()
end

return {
  engineHandlers = {
    onFrame = onFrame,
    onInit = onInit,
    onLoad = onLoad
  },
  eventHandlers = {
    engaging = engaging,
    disengaging = disengaging,
    globalDataCollected = globalDataCollected
  },
}
