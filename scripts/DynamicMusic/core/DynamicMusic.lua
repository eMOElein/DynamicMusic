local vfs = require('openmw.vfs')
local GameState = require('scripts.DynamicMusic.core.GameState')
local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local SoundBank = require('scripts.DynamicMusic.core.SoundBank')
local MusicPlayer = require('scripts.DynamicMusic.core.MusicPlayer')
local Settings = require('scripts.DynamicMusic.core.Settings')
local Property = require('scripts.DynamicMusic.core.Property')
local ambient = require('openmw.ambient')

local DEFAULT_SOUNDBANK = require('scripts.DynamicMusic.core.DefaultSoundBank')

local SOUNDBANKDB_SECTIONS = {
    ALLOWED_CELLS = "allowed_cells",
    ALLOWED_REGIONIDS = "allowed_regionids",
    ALLOWED_ENEMIES = "allowed_enemies"
}

local DynamicMusic = {}
DynamicMusic.sounbankdb = {}
DynamicMusic.playlistProperty = Property.Create()
DynamicMusic.initialized = false
DynamicMusic.soundBanks = {}
DynamicMusic.sondBanksPath = "scripts/DynamicMusic/soundBanks"
DynamicMusic.ignoreEnemies = {}
DynamicMusic.includeEnemies = {}

local _hostileActors = {}

local function split(string, separator)
    local t = {}
    for str in string.gmatch(string, "([^" .. separator .. "]+)") do
        table.insert(t, str)
    end
    return t
end

local function collectSoundBanks()
    print("collecting soundBanks from: " .. DynamicMusic.sondBanksPath)

    local soundBanks = {}
    for file in vfs.pathsWithPrefix(DynamicMusic.sondBanksPath) do
        file = file.gsub(file, ".lua", "")

        local soundBank = require(file)

        if not soundBank.id then
            soundBank.id = file
        end

        soundBank = SoundBank.CreateFromTable(soundBank)

        if soundBank:countAvailableTracks() > 0 then
            table.insert(soundBanks, soundBank)
            print("soundBank loaded: " .. file)
        else
            print('no tracks available: ' .. file)
        end
    end

    return soundBanks
end


local function _getFirstElement(table)
    for _, e in pairs(table) do
        return e
    end
end

function DynamicMusic._collectEnemyNames()
    local enemyNames = {}
    for _, sb in pairs(DynamicMusic.soundBanks) do
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

local function fetchSoundbank()
    local soundbank = nil

    for index = #DynamicMusic.soundBanks, 1, -1 do
        if DynamicMusic.isSoundBankAllowed(DynamicMusic.soundBanks[index]) then
            soundbank = DynamicMusic.soundBanks[index]
            break
        end
    end

    local useDefaultSoundbank = false
    useDefaultSoundbank = Settings.getValue(Settings.KEYS.GENERAL_USE_DEFAULT_SOUNDBANK)

    if not soundbank and useDefaultSoundbank then
        print("using DEFAULT soundbank")
        soundbank = DEFAULT_SOUNDBANK
    end

    return soundbank
end

function DynamicMusic.initialize(cellNames, regionNames, hostileActors)
    if DynamicMusic.initialized then
        return
    end

    _hostileActors = hostileActors
    DynamicMusic.soundBanks = collectSoundBanks()
    local enemyNames = DynamicMusic._collectEnemyNames()

    DynamicMusic.buildSoundbankDb(DynamicMusic.soundBanks, cellNames, regionNames, enemyNames)

    local ignoredEnemies = Settings.getValue(Settings.KEYS.COMBAT_ENEMIES_IGNORE)
    for _, enemyId in pairs(split(ignoredEnemies, ",")) do
        DynamicMusic.ignoreEnemies[enemyId] = enemyId
    end

    local includedEnemies = Settings.getValue(Settings.KEYS.COMBAT_ENEMIES_INCLUDE)
    for _, enemyId in pairs(split(includedEnemies, ",")) do
        DynamicMusic.includeEnemies[enemyId] = enemyId
    end

    DynamicMusic.initialized = true
end

function DynamicMusic.buildSoundbankDb(soundbanks, cellNames, regionNames, enemyNames)
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

        DynamicMusic.sounbankdb[soundbank] = dbEntry
    end
end

function DynamicMusic.isSoundBankAllowed(soundBank)
    if not soundBank then
        return false
    end

    if not soundBank:isAllowedForHourOfDay(GameState.hourOfDay.current) then
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

    local firstHostile = _getFirstElement(_hostileActors)

    local dbEntry = DynamicMusic.sounbankdb[soundBank]
    if soundBank.regionNames and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_REGIONIDS][GameState.regionName.current] then
        return false
    end

    if (soundBank.cellNames or soundBank.cellNamePatterns) and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_CELLS][GameState.cellName.current] then
        return false
    end

    if soundBank.enemyNames and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_ENEMIES][firstHostile.name] then --DynamicMusic.isSoundBankAllowedForEnemyName(firstHostile.name, soundBank) then
        return false
    end

    if soundBank.id == "DEFAULT" then
        return false
    end

    return true
end

function DynamicMusic.newMusic(options)
    print("new music requested")

    local force = options and options.force or not ambient.isMusicPlaying()
    local soundBank = fetchSoundbank()
    local newPlaylist = nil

    if not soundBank then
        print("no matching soundbank found")
        ambient.streamMusic('')
        return
    end

    if GameState.playerState.current == PlayerStates.explore and soundBank.explorePlaylist then
        newPlaylist = soundBank.explorePlaylist
    end

    if GameState.playerState.current == PlayerStates.combat and soundBank.combatPlaylist then
        newPlaylist = soundBank.combatPlaylist
    end

    if not force and newPlaylist == DynamicMusic.playlistProperty:getValue() then
        print("playlist already playing so continue with current")
        return
    end

    if newPlaylist then
        print("activating playlist: " .. newPlaylist.id)
        MusicPlayer.playPlaylist(newPlaylist, { force = force })
        GameState.soundBank.current = soundBank
        DynamicMusic.playlistProperty:setValue(newPlaylist)
        return
    end
end

function DynamicMusic.update(deltaTime)
    MusicPlayer.update(deltaTime)
end

return DynamicMusic
