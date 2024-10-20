local GameState = require('scripts.DynamicMusic.core.GameState')
local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local TableUtils = require('scripts.DynamicMusic.utils.TableUtils')

local SOUNDBANKDB_SECTIONS = {
    ALLOWED_CELLS = "allowed_cells",
    ALLOWED_REGIONIDS = "allowed_regionids",
    ALLOWED_ENEMIES = "allowed_enemies"
}

local SoundbankManager = {}

function SoundbankManager.Create(soundbanks, cellNames, regionNames, enemyNames, hostileActors)
    local soundbankManager = {}
    soundbankManager.isSoundbankAllowed = SoundbankManager.isSoundbankAllowed

    soundbankManager.soundbanks = soundbanks
    soundbankManager.cellNames = cellNames
    soundbankManager.enemyNames = enemyNames
    soundbankManager.regionNames = regionNames
    soundbankManager.hostileActors = hostileActors
    soundbankManager.sounbankdb = SoundbankManager.createSoundbankDb(soundbanks, cellNames, regionNames, enemyNames)

    return soundbankManager
end

function SoundbankManager.createSoundbankDb(soundbanks, cellNames, regionNames, enemyNames)
    local database = {}

    for _, soundbank in pairs(soundbanks) do
        local allowedCells = {}
        for _, cellName in pairs(cellNames) do
            if soundbank:isAllowedForCellName(cellName) then
                allowedCells[cellName] = true
            end
        end

        local allowedRegionIds = {}
        for _, regionId in pairs(regionNames) do
            if soundbank:isAllowedForRegionId(regionId) then
                allowedRegionIds[regionId] = true
            end
        end

        local allowedEnemies = {}
        for _, enemyName in pairs(enemyNames) do
            if soundbank:isAllowedForEnemyName(enemyName) then
                allowedEnemies[enemyName] = true
            end
        end

        local dbEntry = {}
        dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_ENEMIES] = allowedEnemies
        dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_CELLS] = allowedCells
        dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_REGIONIDS] = allowedRegionIds

        database[soundbank] = dbEntry
    end

    print("managerdb created: " ..tostring(database))
    return database
end

function SoundbankManager.isSoundbankAllowed(self, soundbank)
    print("check: " ..soundbank.id)
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
        if not soundbank.tracks or #soundbank.tracks == 0 then
            return false
        end
    end

    if GameState.playerState.current == PlayerStates.combat then
        if #soundbank.combatTracks == 0 then
            return false
        end
    end

    local firstHostile = TableUtils.getFirstElement(self.hostileActors)

    local dbEntry = self.sounbankdb[soundbank]
    if soundbank.regionNames and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_REGIONIDS][GameState.regionName.current] then
        return false
    end

    if (#soundbank.cellNames > 0 or #soundbank.cellNamePatterns > 0) and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_CELLS][GameState.cellName.current] then
        return false
    end

    if soundbank.enemyNames and firstHostile and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_ENEMIES][firstHostile.name] then
        return false
    end

    if soundbank.id == "DEFAULT" then
        return false
    end

    return true
end

return SoundbankManager