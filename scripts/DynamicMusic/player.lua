local ui = require('openmw.ui')
local core = require('openmw.core')
local self = require('openmw.self')
local ambient = require('openmw.ambient')
local vfs = require('openmw.vfs')

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

local soundBanks = {}

local function countAvailableTracks(soundBank)
  if not soundBank.tracks or #soundBank.tracks == 0 then
    return 0
  end

  local availableTracks = 0

  for _, track in ipairs(soundBank.tracks) do
    if type(track) == "table" then
      track = track.path
    end

    if vfs.fileExists(track) then
      availableTracks = availableTracks + 1
    end
  end

  return availableTracks
end

--- Collect sound banks.
-- Collects the user defined soundbanks that are stored inside the soundBanks folder
local function collectSoundBanks()
  local soundBanksPath = "scripts/DynamicMusic/soundBanks"
  print("collecting soundBanks from: " ..soundBanksPath)

  for file in vfs.pathsWithPrefix(soundBanksPath) do
    file = file.gsub(file, ".lua", "")
    print("requiring soundBank: " ..file)
    local soundBank = require(file)

    if type(soundBank) == 'table' then
      local availableTracks = countAvailableTracks(soundBank)

      if(availableTracks > 0) then
        table.insert(soundBanks,soundBank)
      else
        print('no tracks available soundbank will note be added: '..file)
      end
    else
      print("soundBank returned no table: " ..file)
    end
  end
end

---Check combat state.
-- Checks if the game is currently in combat state or not.
-- @return true/false
local function isCombatState()
  local combat = false
  for id, npc in pairs(hostiles) do
    combat = true
    break
  end

  return combat
end

---Check if sound bank is allowed
-- Returns if the specified soundbank is allowed to play in the current ingame situation.
-- @param soundBank the soundbank that should be checked
-- @return true/false
local function isSoundBankAllowed(soundBank)
  if not soundBank then
    return false
  end

  if currentCombatState then
    return false
  end

  local cell = self.cell.name

  if soundBank.cellNamePatternsExclude then
    if soundBank.cellNamePatternsExclude then
      for  _, bankCell in ipairs(soundBank.cellNamePatternsExclude) do
        if string.find(cell, bankCell) then
          return false
        end
      end
    end
  end

  if soundBank.cellNamePatterns then
    for  _, bankCell in ipairs(soundBank.cellNamePatterns) do
      if string.find(cell, bankCell) then
        return true
      end
    end
  end
end

---Fetche appropriate soundbank.
-- Chooses a soundbank that is allowed for the current ingame situation
-- @return a soundbank
local function fetchSoundBank()
  local cell = self.cell.name

  for _, soundBank in ipairs(soundBanks) do
    if isSoundBankAllowed(soundBank) then
      return soundBank
    end
  end

end

---Plays another track from an allowed soundbank
-- Chooses a fitting soundbank and plays a track from it
-- If no soundbank could be found a vanilla track is played
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

  local rnd = math.random(1,#soundBank.tracks)
  local track = soundBank.tracks[rnd]
  local trackPath = nil

  if type(track) == 'table' then
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

local function onInit(initData)

end

collectSoundBanks()

return {
  engineHandlers = {
    onFrame = onFrame,
    onInit = onInit
  },
  eventHandlers = {
    engaging = engaging,
    disengaging = disengaging
  },
}
