local vfs = require('openmw.vfs')
local GameState = require('scripts.DynamicMusic.core.GameState')
local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local SoundBank = require('scripts.DynamicMusic.models.SoundBank')
local MusicPlayer = require('scripts.DynamicMusic.core.MusicPlayer')
local Settings = require('scripts.DynamicMusic.core.Settings')
local Property = require('scripts.DynamicMusic.core.Property')
local TableUtils = require('scripts.DynamicMusic.utils.TableUtils')
local SoundbankManager = require('scripts.DynamicMusic.core.SoundbankManager')
local ambient = require('openmw.ambient')

local DEFAULT_SOUNDBANK = require('scripts.DynamicMusic.core.DefaultSoundBank')

local DynamicMusic = {}
DynamicMusic.sounbankdb = {}
DynamicMusic.playlistProperty = Property.Create()
DynamicMusic.initialized = false
DynamicMusic.soundBanks = {}
DynamicMusic.sondBanksPath = "scripts/DynamicMusic/soundBanks"
DynamicMusic.ignoreEnemies = {}
DynamicMusic.includeEnemies = {}

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

        if not soundBank.id or soundBank.id ~= "DEFAULT" then
            soundBank.id = file.gsub(file, DynamicMusic.sondBanksPath, "")

            soundBank = SoundBank.Decoder.fromTable(soundBank)

            if soundBank:countAvailableTracks() > 0 then
                table.insert(soundBanks, soundBank)
                print("soundBank loaded: " .. file)
            else
                print('no tracks available: ' .. file)
            end
        end
    end

    return soundBanks
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

    DynamicMusic.soundBanks = collectSoundBanks()
    DynamicMusic.soundbankManager = SoundbankManager.Create(DynamicMusic.soundBanks, cellNames, regionNames,  hostileActors)

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

function DynamicMusic.isSoundBankAllowed(soundBank)
    return DynamicMusic.soundbankManager:isSoundbankAllowed(soundBank)
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

function DynamicMusic.info()
    local soundbanks = 0
    if DynamicMusic.soundBanks then
        soundbanks = #DynamicMusic.soundBanks
    end

    print("=== DynamicMusic Info ===")
    print("soundbanks: " .. soundbanks)
    for _, sb in ipairs(DynamicMusic.soundBanks) do
        print("sb: " .. tostring(sb.id))
        if sb.combatTracks then
            print("combat tracks: " .. #sb.combatTracks)
        end

        if (sb.cellNamePatterns) then
            print("cellNamePatterns: " .. TableUtils.countKeys(sb.cellNamePatterns))
        end
    end
end

function DynamicMusic.update(deltaTime)
    MusicPlayer.update(deltaTime)
end

return DynamicMusic
