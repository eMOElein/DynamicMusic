local GameState = require('scripts.DynamicMusic.core.GameState')
local GlobalData = require('scripts.DynamicMusic.core.GlobalData')
local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local TableUtils = require('scripts.DynamicMusic.utils.TableUtils')

local SOUNDBANKDB_SECTIONS = {
    ALLOWED_CELLS = "allowed_cells",
    ALLOWED_REGIONS = "ALLOWED_REGIONS",
    ALLOWED_ENEMIES = "allowed_enemies"
}

---@class SoundbankManager
---@field soundbanks [Soundbank]
---@field _soundbankDatabase any
local SoundbankManager = {}

---Creates a new SoundbankManager.
---@param soundbanks table<Soundbank>
---@return SoundbankManager
function SoundbankManager.Create(soundbanks)
    local soundbankManager = {}
    soundbankManager.addSoundbank = SoundbankManager.addSoundbank
    soundbankManager.isSoundbankAllowed = SoundbankManager.isSoundbankAllowed

    soundbankManager.soundbanks = soundbanks
    soundbankManager._soundbankDatabase = {}

    for _, soundbank in pairs(soundbanks) do
        soundbankManager:addSoundbank(soundbank)
    end

    return soundbankManager
end

---Adds a new soundbank to the manager.
---@param soundbank Soundbank
function SoundbankManager.addSoundbank(self, soundbank)
    local allowedCells = {}
    for _, cellName in pairs(GlobalData.cellNames) do
        if soundbank:isAllowedForCellName(cellName) then
            allowedCells[cellName] = true
        end
    end

    local allowedRegions = {}
    for _, region in pairs(GlobalData.regionNames) do
        if soundbank:isAllowedForRegion(region) then
            allowedRegions[region] = true
        end
    end

    local allowedEnemies = {}
    for _, enemyName in pairs(soundbank.enemyNames) do
        allowedEnemies[enemyName] = true
    end

    local dbEntry = {}
    dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_ENEMIES] = allowedEnemies
    dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_CELLS] = allowedCells
    dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_REGIONS] = allowedRegions

    self._soundbankDatabase[soundbank] = dbEntry
end

---Checks if the soundbank is allowed to play for the current gamestate.
---@param self SoundbankManager
---@param soundbank Soundbank
---@return boolean
function SoundbankManager.isSoundbankAllowed(self, soundbank)
    if not soundbank then
        return false
    end

    if not soundbank:isAllowedForHourOfDay(GameState.hourOfDay.current) then
        return false
    end

    if soundbank.interiorOnly and GameState.exterior.current then
        return false
    end

    if soundbank.exteriorOnly and not GameState.exterior.current then
        return false
    end

    if GameState.playerState.current == PlayerStates.explore then
        if #soundbank.tracks == 0 then
            return false
        end
    end

    if GameState.playerState.current == PlayerStates.combat then
        if #soundbank.combatTracks == 0 then
            return false
        end
    end

    local dbEntry = self._soundbankDatabase[soundbank]
    if #soundbank.regions > 0 and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_REGIONS][GameState.regionName.current] then
        return false
    end

    if (#soundbank.cellNames > 0 or #soundbank.cellNamePatterns > 0) and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_CELLS][GameState.cellName.current] then
        return false
    end

    local firstHostile = TableUtils.getFirstElement(GlobalData.hostileActors)
    if #soundbank.enemyNames > 0 and firstHostile and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_ENEMIES][firstHostile.name] then
        return false
    end

    if soundbank.id == "DEFAULT" then
        return false
    end

    return true
end

return SoundbankManager
