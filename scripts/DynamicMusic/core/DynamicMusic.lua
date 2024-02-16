local vfs = require('openmw.vfs')
local GameState = require('scripts.DynamicMusic.core.GameState')
local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local CardIndex = require('scripts.DynamicMusic.core.CardIndex')

local DynamicMusic = {}

local function countAvailableTracks(soundBank)
    if not soundBank.tracks or #soundBank.tracks == 0 then
        return 0
    end

    local availableTracks = 0

    if soundBank.tracks then
        for _, track in ipairs(soundBank.tracks) do
            if type(track) == "table" then
                track = track.path
            end

            if vfs.fileExists(track) then
                availableTracks = availableTracks + 1
            end
        end
    end

    if soundBank.combatTracks then
        for _, track in ipairs(soundBank.combatTracks) do
            if type(track) == "table" then
                track = track.path
            end

            if vfs.fileExists(track) then
                availableTracks = availableTracks + 1
            end
        end
    end

    return availableTracks
end

--- Collect sound banks.
-- Collects the user defined soundbanks that are stored inside the soundBanks folder
local function collectSoundBanks()
    local soundBanks = {}

    print("collecting soundBanks from: " .. DynamicMusic.sondBanksPath)

    for file in vfs.pathsWithPrefix(DynamicMusic.sondBanksPath) do
        file = file.gsub(file, ".lua", "")
        print("requiring soundBank: " .. file)
        local soundBank = require(file)

        if type(soundBank) == 'table' then
            local availableTracks = countAvailableTracks(soundBank)

            if (availableTracks > 0) then
                if soundBank.tracks then
                    for _, t in ipairs(soundBank.tracks) do
                        t.path = string.lower(t.path)
                    end
                end

                if soundBank.combatTracks then
                    for _, t in ipairs(soundBank.combatTracks) do
                        t.path = string.lower(t.path)
                    end
                end

                table.insert(soundBanks, soundBank)
            else
                print('no tracks available: ' .. file)
            end
        else
            print("not a lua table: " .. file)
        end
    end

    return soundBanks
end

DynamicMusic.initialized = false
DynamicMusic.soundBanks = {}
DynamicMusic.sondBanksPath = "scripts/DynamicMusic/soundBanks"

local _cellNameIndex = nil
local _regionNameIndex = nil

function DynamicMusic.initialize(cellNames, regionNames)
    if DynamicMusic.initialized then
        return
    end

    DynamicMusic.soundBanks = collectSoundBanks()

    _cellNameIndex = CardIndex.Create(cellNames, DynamicMusic.soundBanks, DynamicMusic.isSoundBankAllowedForCellName)
    _regionNameIndex = CardIndex.Create(regionNames, DynamicMusic.soundBanks,
        DynamicMusic.isSoundBankAllowedForRegionName)

    DynamicMusic.initialized = true
end

function DynamicMusic.isSoundBankAllowed(soundBank)
    if not soundBank then
        return false
    end

    if soundBank.interiorOnly and GameState.exterior.current then
        return false
    end

    if soundBank.exteriorOnly and not GameState.exterior.current then
        return false
    end

    if GameState.playerState.current == PlayerStates.explore then
        if not soundBank.tracks or #soundBank.tracks == 0 then
            return false
        end
    end

    if GameState.playerState.current == PlayerStates.combat then
        if not soundBank.combatTracks or #soundBank.combatTracks == 0 then
            return false
        end
    end

    if (soundBank.cellNames or soundBank.cellNamePatterns) and not DynamicMusic.isSoundBankAllowedForCellName(GameState.cellName.current, soundBank) then
        return false
    end

    if soundBank.regionNames and not DynamicMusic.isSoundBankAllowedForRegionName(GameState.regionName.current, soundBank) then
        return false
    end

    if soundBank.id == "DEFAULT" then
        return false
    end


    return true
end

function DynamicMusic.isSoundBankAllowedForCellName(cellName, soundBank)
    if _cellNameIndex then
        return _cellNameIndex:contains(cellName, soundBank) --_cellNameIndex[cellName] and _cellNameIndex[cellName][soundBank]
    end

    if soundBank.cellNamePatternsExclude then
        for _, cellNameExcludePattern in ipairs(soundBank.cellNamePatternsExclude) do
            if string.find(cellName, cellNameExcludePattern) then
                return false
            end
        end
    end

    if soundBank.cellNames then
        for _, allowedCellName in ipairs(soundBank.cellNames) do
            if cellName == allowedCellName then
                return true
            end
        end
    end

    if soundBank.cellNamePatterns then
        for _, cellNamePattern in ipairs(soundBank.cellNamePatterns) do
            if string.find(cellName, cellNamePattern) then
                return true
            end
        end
    end
end

function DynamicMusic.isSoundBankAllowedForRegionName(regionName, soundBank)
    if not soundBank.regionNames then
        return false
    end

    if _regionNameIndex then
        return _regionNameIndex:contains(regionName, soundBank) -- [regionName] and _regionNameIndex[regionName][soundBank]
    end

    for _, allowedRegionName in ipairs(soundBank.regionNames) do
        if regionName == allowedRegionName then
            return true
        end
    end

    return false
end

return DynamicMusic
