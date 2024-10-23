local GameState = require('scripts.DynamicMusic.core.GameState')
local GlobalData = require('scripts.DynamicMusic.core.GlobalData')
local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local TableUtils = require('scripts.DynamicMusic.utils.TableUtils')

local SOUNDBANKDB_SECTIONS = {
    ALLOWED_CELLS = "allowed_cells",
    ALLOWED_REGIONIDS = "allowed_regionids",
    ALLOWED_ENEMIES = "allowed_enemies"
}

---@class SoundbankManager
---@field soundbanks [Soundbank]
---@field _soundbankDatabase any
local SoundbankManager = {}

---Creates a new SoundbankManager.
---@param soundbanks [Soundbank]
---@return SoundbankManager
function SoundbankManager.Create(soundbanks)
    local soundbankManager = {}
    soundbankManager.addSoundbank = SoundbankManager.addSoundbank
    soundbankManager.isSoundbankAllowed = SoundbankManager.isSoundbankAllowed

    soundbankManager.soundbanks = soundbanks
    soundbankManager.enemyNames = SoundbankManager._collectEnemyNames(soundbankManager)
    soundbankManager.soundbankDatabase = {}

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

    local allowedRegionIds = {}
    for _, regionId in pairs(GlobalData.regionNames) do
        if soundbank:isAllowedForRegionId(regionId) then
            allowedRegionIds[regionId] = true
        end
    end

    local allowedEnemies = {}
    for _, enemyName in pairs(GlobalData.enemyNames) do
        if soundbank:isAllowedForEnemyName(enemyName) then
            allowedEnemies[enemyName] = true
        end
    end

    local dbEntry = {}
    dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_ENEMIES] = allowedEnemies
    dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_CELLS] = allowedCells
    dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_REGIONIDS] = allowedRegionIds

    self._soundbankDatabase[soundbank] = dbEntry
end

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

    local firstHostile = TableUtils.getFirstElement(GlobalData.hostileActors)

    local dbEntry = self._soundbankDatabase[soundbank]
    if soundbank.regionNames and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_REGIONIDS][GameState.regionName.current] then
        return false
    end

    if (#soundbank.cellNames > 0 or #soundbank.cellNamePatterns > 0) and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_CELLS][GameState.cellName.current] then
        return false
    end

    if #soundbank.enemyNames > 0 and firstHostile and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_ENEMIES][firstHostile.name] then
        return false
    end

    if soundbank.id == "DEFAULT" then
        return false
    end

    return true
end

function SoundbankManager._collectEnemyNames(self)
    local enemyNames = {}
    for _, sb in pairs(self.soundbanks) do
        if sb.enemyNames and #sb.enemyNames > 0 then
            for _, e in pairs(sb.enemyNames) do
                if not enemyNames[e] then
                    enemyNames[e] = e
                end
            end
        end
    end

    return enemyNames
end

return SoundbankManager
