local ambient = require('openmw.ambient')
local core = require('openmw.core')
local self = require('openmw.self')
local vfs = require('openmw.vfs')

local soundBanks = {}
local cellNameDictionary = nil

local hostilesActors = {}
local initialized = false

local currentGameTime = os.time()
local currentCell = nil
local currentTrackPath = nil
local currentTrackLength = nil
local currentPlaytime = 0
local currentSoundBank = nil
local currentCombatState = nil

local previousCellName = nil
local previousCombatState = nil
local previousGameTime = 0

local function contains(elements, element)
  if not elements then
    return false
  end

  for _, tableElement in pairs(elements) do
    if tableElement == element then
      return true
    end
  end

  return false
end

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
        print('no tracks available soundbank will not be added: '..file)
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
  for id, npc in pairs(hostilesActors) do
    combat = true
    break
  end

  return combat
end

--- Returns if the given sondBank is allowed for the given cellname
-- Performs raw checks and does not use the dictionary
-- @param soundBank a soundBank
-- @paran cellName a cellName of type string
-- @returns true/false
local function isSoundBankAllowedForCellName(soundBank, cellName, useDictionary)
  if useDictionary and cellNameDictionary then
    return contains(cellNameDictionary[cellName], soundBank)
  end

  if soundBank.cellNamePatternsExclude then
    for  _, cellNameExcludePattern in ipairs(soundBank.cellNamePatternsExclude) do
      if string.find(cellName, cellNameExcludePattern) then
        return false
      end
    end
  end

  if soundBank.cellNamePatterns then
    for  _, cellNamePattern in ipairs(soundBank.cellNamePatterns) do
      if string.find(cellName, cellNamePattern) then
        return true
      end
    end
  end
end

---Check if sound bank is allowed
-- Returns if the specified soundbank is allowed to play in the current ingame situation.
-- @param soundBank the soundbank that should be checked
-- @return true/false
local function isSoundBankAllowed(soundBank)
  if not soundBank then
    return false
  end

  if  isSoundBankAllowedForCellName(soundBank, currentCell, true) then
    if currentCombatState then
      if soundBank.combatTracks and #soundBank.combatTracks > 0 then
        return true
      else
        return false
      end
    end
    return true
  end
end

---Fetche appropriate soundbank.
-- Chooses a soundbank that is allowed for the current ingame situation
-- @return a soundbank
local function fetchSoundBank()
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
  print("newmusic")
  local soundBank = fetchSoundBank()

  if not soundBank then
    print("no soundbank")
    if currentSoundBank then
      ambient.streamMusic('')
    end
    currentTrackPath = nil
    currentPlaytime = nil
    currentSoundBank = nil
    return
  end

  currentSoundBank = soundBank
  print("fetch track")
  local tracks = soundBank.tracks

  if currentCombatState and soundBank.combatTracks then
    tracks = soundBank.combatTracks
  end

  local rnd = math.random(1,#tracks)
  local track = tracks[rnd]
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

--- Prefetches dictionary.cells
-- Every sondBank is checked agains each cellName and the dictionary is populated if the soundBank is allowed for that cell
-- @param cellNames all cellNames of the game
local function prefetchCells(cellNames)
  local dictionary = {}

  print("prefetching cells")
  for _, cellName in ipairs(cellNames) do
    for _, soundBank in ipairs(soundBanks) do
      if isSoundBankAllowedForCellName(soundBank, cellName, false) then
        local dict = dictionary[cellName]
        if not dict then
          dict = {}
          dictionary[cellName] = dict
        end
        --       print("adding: " ..tostring(soundBank.id) .." to " ..cellName)
        table.insert(dict, soundBank)
      end
    end
  end

  cellNameDictionary = dictionary
end

local function onFrame(dt)
  currentGameTime = os.time()
  currentCombatState = isCombatState()
  currentCell = self.cell and self.cell.name or ""

  if currentPlaytime then
    currentPlaytime = currentPlaytime + (currentGameTime - previousGameTime)
  end

  if isSoundSwitchNeeded() then
    newMusic()
  end

  previousCellName = currentCell
  previousGameTime = currentGameTime
  previousCombatState = currentCombatState
end

local function engaging(eventData)
  if (not eventData.actor) then return end;
  hostilesActors[eventData.actor.id] = eventData.actor;
end

local function disengaging(eventData)
  if (not eventData.actor) then return end;
  hostilesActors[eventData.actor.id] = nil;
end

local function globalDataCollected(eventData)
  print("collecting global data")
  local data = eventData.data

  if data.cellNames then
    prefetchCells(data.cellNames)
  end
end

local function initialize()
  if not initialized then
    print('initializing playerscript')
    collectSoundBanks()
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
