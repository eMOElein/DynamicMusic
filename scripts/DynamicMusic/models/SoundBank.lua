local vfs = require('openmw.vfs')
local Playlist = require('scripts.DynamicMusic.core.Playlist')
local Track = require('scripts.DynamicMusic.models.Track')
local TableUtils = require('scripts.DynamicMusic.utils.TableUtils')

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

function SoundBank.Create(id)
    if not id then
        error("id not specified", 2)
    end

    local soundBank = {}
    soundBank.id = id
    soundBank._hourOfDayDB = nil

    soundBank.countAvailableTracks = SoundBank.countAvailableTracks
    soundBank.isAllowedForEnemyName = SoundBank.isAllowedForEnemyName
    soundBank.isAllowedForCellName = SoundBank.isAllowedForCellName
    soundBank.isAllowedForRegionId = SoundBank.isAllowedForRegionId
    soundBank.isAllowedForHourOfDay = SoundBank.isAllowedForHourOfDay
    soundBank.setCellNames = SoundBank.setCellNames
    soundBank.setCellNamePatterns = SoundBank.setCellNamePatterns
    soundBank.setEnemyNames = SoundBank.setEnemyNames
    soundBank.setCombatTracks = SoundBank.setCombatTracks
    soundBank.setHours = SoundBank.setHours
    soundBank.setRegionNames = SoundBank.setReionNames
    soundBank.setTracks = SoundBank.setTracks

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

    if self.cellNamePatterns and TableUtils.countKeys(self.cellNamePatterns) > 0 then
        for _, cellNamePattern in ipairs(self.cellNamePatterns) do
            if string.find(cellName, cellNamePattern) then
                return true
            end
        end
    end

    return false
end

function SoundBank.isAllowedForHourOfDay(self, hourOfDay)
    local bool = not self._hourOfDayDB or self._hourOfDayDB[hourOfDay]
    return bool
end

function SoundBank.isAllowedForRegionId(self, regionId)
    if not self.regionNames or TableUtils.countKeys(self.regionNames) == 0 then
        return true
    end

    for _, sbRegionId in ipairs(self.regionNames) do
        if regionId == sbRegionId then
            return true
        end
    end

    return false
end

function SoundBank.setTracks(self, tracks)
    self.tracks = tracks
    self.explorePlaylist = buildPlaylist(self.id .. "_explore", self.tracks)
end

function SoundBank.setCombatTracks(self, tracks)
    self.combatTracks = tracks
    self.combatPlaylist = buildPlaylist(self.id .. "_combat", self.combatTracks)
end

function SoundBank.setCellNames(self, cellNames)
    self.cellNames = {}
    for _, cn in ipairs(cellNames) do
        table.insert(self.cellNames, cn)
    end
end

function SoundBank.setCellNamePatterns(self, cellNamePatterns)
    self.cellNamePatterns = {}
    for _, cn in ipairs(cellNamePatterns) do
        table.insert(self.cellNamePatterns, cn)
    end
end

function SoundBank.setEnemyNames(self, enemyNames)
    self.enemyNames = {}
    for _, en in ipairs(enemyNames) do
        table.insert(self.enemyNames, en)
    end
end

function SoundBank.setHours(self, hours)
    self.hourOfDay = {}
    self._hourOfDayDB = nil

    if not hours or TableUtils.countKeys(hours) == 0 then
        return
    end

    for _, h in ipairs(hours) do
        table.insert(self.hourOfDay, h)
    end

    self._hourOfDayDB = {}
    for _, hour in pairs(self.hourOfDay) do
        self._hourOfDayDB[hour] = true
    end
end

function SoundBank.setReionNames(self, regionNames)
    self.regionNames = {}
    for _, rn in ipairs(regionNames) do
        table.insert(self.regionNames, rn)
    end
end

SoundBank.Decoder = {
    fromTable = function(soundbankData)
        local exploreTracks = {}
        if soundbankData.tracks then
            for _, trackData in ipairs(soundbankData.tracks) do
                local track = Track.Decoder.fromTable(trackData)
                table.insert(exploreTracks, track)
            end
        end

        local combatTracks = {}
        if soundbankData.combatTracks then
            for _, trackData in ipairs(soundbankData.combatTracks) do
                local track = Track.Decoder.fromTable(trackData)
                table.insert(combatTracks, track)
            end
        end

        local soundbank = SoundBank.Create(soundbankData.id)

        soundbank:setTracks(exploreTracks)
        soundbank:setCombatTracks(combatTracks)

        if soundbankData.cellNames then
            soundbank:setCellNames(soundbankData.cellNames)
        end

        if soundbankData.cellNamePatterns then
            soundbank:setCellNamePatterns(soundbankData.cellNamePatterns or {})
        end

        soundbank:setEnemyNames(soundbankData.enemyNames or {})
        soundbank:setHours(soundbankData.hourOfDay or {})
        soundbank:setRegionNames(soundbankData.regionNames or {})

        return soundbank
    end
}

return SoundBank
