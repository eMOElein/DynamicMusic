local vfs = require('openmw.vfs')
local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local Playlist = require('scripts.DynamicMusic.core.Playlist')

local SoundBank = {}

local function buildPlaylist(id, tracks)
    local playlistTracks = {}

    for _, track in pairs(tracks) do
        table.insert(playlistTracks, track)
    end

    local playlistData = {
        id = id,
        --        priority = Settings.getValue(Settings.KEYS.GENERAL_PLAYLIST_PRIORITY),
        tracks = playlistTracks
    }

    return Playlist.Create(playlistData)
end

local function _countExistingTracks(tracks)
    if not tracks then
        return 0
    end

    local existingTracks = 0
    for _, track in pairs(tracks) do
        if vfs.fileExists(track.path) then
            existingTracks = existingTracks + 1
        end
    end

    return existingTracks
end

local function _initializeTracks(tracks)
    for _, t in ipairs(tracks) do
        if not t.path then
            error("trackpat not specified", 2)
        end

        if not t.length then
            error("tracklentgh not specified", 2)
        end
        t.path = string.lower(t.path)
    end
end

function SoundBank.CreateFromTable(data)
    if not data.id then
        error("id not specified", 2)
    end

    local soundBank = data
    soundBank.id = data.id
    soundBank.countAvailableTracks = SoundBank.countAvailableTracks
    soundBank.isAllowedForEnemyName = SoundBank.isAllowedForEnemyName
    soundBank.isAllowedForCellName = SoundBank.isAllowedForCellName
    soundBank.isAllowedForRegionId = SoundBank.isAllowedForRegionId
    soundBank.isAllowedForHourOfDay = SoundBank.isAllowedForHourOfDay

    if soundBank.tracks then
        _initializeTracks(soundBank.tracks)
    end

    if soundBank.combatTracks then
        _initializeTracks(soundBank.combatTracks)
    end

    if soundBank.tracks and #soundBank.tracks > 0 then
        soundBank.explorePlaylist = buildPlaylist(soundBank.id .. "_explore", soundBank.tracks)
        --       Music.registerPlaylist(explorePlaylist)
    end

    if soundBank.combatTracks and #soundBank.combatTracks > 0 then
        soundBank.combatPlaylist = buildPlaylist(soundBank.id .. "_combat", soundBank.combatTracks)
        --       Music.registerPlaylist(combatPlaylist)
    end

    if soundBank.hourOfDay then
        for _, hour in pairs(soundBank.hourOfDay) do
            soundBank.hourOfDay[hour] = hour
        end
    end

    return soundBank
end

function SoundBank.countAvailableTracks(self)
    local availableTracks = 0
    availableTracks = availableTracks + _countExistingTracks(self.tracks)
    availableTracks = availableTracks + _countExistingTracks(self.combatTracks)
    return availableTracks
end

function SoundBank.isAllowedForEnemyName(self, enemyName)
    if not self.enemyNames then
        return false
    end

    for _, e in pairs(self.enemyNames) do
        if e == enemyName then
            return true
        end
    end

    return false
end

function SoundBank.isAllowedForCellName(self, cellName)
    if self.cellNamePatternsExclude then
        for _, cellNameExcludePattern in ipairs(self.cellNamePatternsExclude) do
            if string.find(cellName, cellNameExcludePattern) then
                return false
            end
        end
    end

    if self.cellNames then
        for _, allowedCellName in ipairs(self.cellNames) do
            if cellName == allowedCellName then
                return true
            end
        end
    end

    if self.cellNamePatterns then
        for _, cellNamePattern in ipairs(self.cellNamePatterns) do
            if string.find(cellName, cellNamePattern) then
                return true
            end
        end
    end

    return false
end

function SoundBank.isAllowedForHourOfDay(self, hourOfDay)
    return not self.hourOfDay or self.hourOfDay[hourOfDay]
end

function SoundBank.isAllowedForRegionId(self, regionId)
    if not self.regionNames then
        return false
    end

    for _, sbRegionId in ipairs(self.regionNames) do
        if regionId == sbRegionId then
            return true
        end
    end

    return false
end

return SoundBank
