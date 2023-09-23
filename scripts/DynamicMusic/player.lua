local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local core = require('openmw.core')
local self = require('openmw.self')
local ambient = require('openmw.ambient')

local hostiles = {}

local previousCellName = nil
local previousCombatState = nil
local previousGameTime = 0


local currentCell = nil
local currentTrackPath = nil
local currentTrackLength = nil
local currentPlaytime = 0
local currentSoundBank = nil
local currentCombatState = nil

local gameTime = os.time()

local soundBanks = {
  {
    cellNamePatterns = {
      'Guild of Mages',
      'Mage\'s Guild'
    },
    tracks = {
      {
        path='Music/em_dynamicMusic/Magic 3.mp3',
        length=61.5
      },
      'Music/em_dynamicMusic/Magic 2.mp3'
    }
  },
  {
    cellNamePatterns = {
      'Guild of Fighters'
    },
    tracks = {
      {
        path='Music/em_dynamicMusic/Theme 023 (Fighter Guild - Ship).mp3',
        length=62
      }
    }
  },
  {
    cellNamePatterns = {
      'Balmora, Eight Plates'
    },
    tracks = {
      {path='Music/em_dynamicMusic/Tavern.mp3',
        length=3
      }
    }
  }
}

local function isCombatState()
  local combat = false
  for id, npc in pairs(hostiles) do
    combat = true
    break
  end

  return combat
end

local function isSoundBankAllowed(soundBank)
  if not soundBank then
    return false
  end

  if currentCombatState then
    return false
  end

  local cell = self.cell.name

  if soundBank.cellNamePatterns then
    for  _, bankCell in ipairs(soundBank.cellNamePatterns) do
      if string.find(cell, bankCell) then
        return true
      end
    end
  end
end

local function fetchSoundBank()
  local cell = self.cell.name

  for _, soundBank in ipairs(soundBanks) do
    if isSoundBankAllowed(soundBank) then
      return soundBank
    end
  end

end

local function newMusic()
  local soundBank = fetchSoundBank()

  if not soundBank then
    if currentSoundBank then
      ambient.streamMusic('')
    end
    currentTrackPath = nil
    currentPlaytime = nil
    currentSoundBank = nil
    return
  end

  if soundBank == currentSoundBank then
  end

  currentSoundBank = soundBank

  local track = soundBank.tracks[1]
  local trackPath = nil

  if type(track) == "table" then
    trackPath = track.path
    if track.length then
      currentTrackLength = track.length
    end
  else
    currentTrackLength = nil
    trackPath = track
  end

  currentPlaytime = 0
  currentTrackPath = trackPath
  ambient.streamMusic(trackPath)
end

local function isSoundSwitchNeeded()
  if currentTrackLength and currentPlaytime and currentPlaytime >= currentTrackLength then
    return true
  end

  if not ambient.isMusicPlaying() then
    return true
  end

  if currentCell ~= previousCellName and not isSoundBankAllowed(currentSoundBank)then
    return true
  end

  if previousCombatState ~= currentCombatState then
    return true
  end

  return false
end

local function onFrame(dt)
  gameTime = os.time()
  currentCombatState = isCombatState()
  currentCell = self.cell.name

  if currentPlaytime then
    currentPlaytime = currentPlaytime + (gameTime - previousGameTime)
  end

  if isSoundSwitchNeeded() then
    newMusic()
  end

  previousCellName = currentCell
  previousGameTime = gameTime
  previousCombatState = currentCombatState
end

local function engaging(eventData)
  if (not eventData.actor) then return end;
  hostiles[eventData.actor.id] = eventData.actor;
end

local function disengaging(eventData)
  if (not eventData.actor) then return end;
  hostiles[eventData.actor.id] = nil;
end

return {
  engineHandlers = {
    onFrame = onFrame
  },
  eventHandlers = {
    engaging = engaging,
    disengaging = disengaging
  },
}
