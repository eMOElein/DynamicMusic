local vfs = require('openmw.vfs')
local GameState = require('scripts.DynamicMusic.core.GameState')
local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local Music = require('openmw.interfaces').Music

local SoundBank = {}

local function buildPlaylist(id, tracks)
    local playlistTracks = {}

    for _, track in pairs(tracks) do
        table.insert(playlistTracks, track.path)
    end

    local playlist = {
        id = id,
        priority = 1,
        tracks = playlistTracks
    }

    return playlist
end

local function contains(elements, element)
    for _, e in pairs(elements) do
        if (e == element) then
            return true
        end
    end

    return false
end

local function fetchRandomTrack(tracks, options)
    local allowedTracks = tracks

    if options and options.blacklist and #options.blacklist > 0 then
        allowedTracks = {}
        for _, t in pairs(tracks) do
            if not contains(options.blacklist, t) then
                table.insert(allowedTracks, t)
            end
        end
    end

    local rnd = math.random(1, #allowedTracks)
    local track = allowedTracks[rnd]

    return track
end

function SoundBank.CreateFromTable(data)
    local soundBank = data
    soundBank.countAvailableTracks = SoundBank.countAvailableTracks

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

    if soundBank.tracks and soundBank.tracks then
        local explorePlaylist = buildPlaylist(soundBank.id .. "_explore", soundBank.tracks)
        soundBank.explorePlaylist = explorePlaylist
        Music.registerPlaylist(explorePlaylist)
    end

    if soundBank.combatTracks and soundBank.combatTracks then
        local combatPlaylist = buildPlaylist(soundBank.id .. "_combat", soundBank.combatTracks)
        soundBank.combatPlaylist = combatPlaylist
        Music.registerPlaylist(combatPlaylist)
    end

    return soundBank
end

function SoundBank.countAvailableTracks(self)
    local availableTracks = 0

    if self.tracks then
        for _, track in ipairs(self.tracks) do
            if type(track) == "table" then
                track = track.path
            end

            if vfs.fileExists(track) then
                availableTracks = availableTracks + 1
            end
        end
    end

    if self.combatTracks then
        for _, track in ipairs(self.combatTracks) do
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

function SoundBank.fetchTrack(self)
    local track = nil
    local tracks = self.tracks

    -- in case of combat situation use combat tracks
    if GameState.playerState.current == PlayerStates.combat and self.combatTracks then
        tracks = self.combatTracks
    end
    track = fetchRandomTrack(tracks)

    -- if new trackpath == previous trackpath try to fetch a different track
    if #tracks > 1 and (GameState.track.previous and track.path == GameState.track.previous.path or false) then
        print("searching for another track to avoid repeated playback of: " .. GameState.track.previous.path)
        track = fetchRandomTrack(tracks, { blacklist = { track } })
    end

    return track
end

function SoundBank.trackForPath(self, playerState, trackPath)
    local tracks = {}

    if playerState == PlayerStates.explore then
        tracks = self.tracks
    end

    if playerState == PlayerStates.combat then
        tracks = self.combatTracks
    end

    for _, track in pairs(tracks) do
        if (track.path == trackPath) then
            return track
        end
    end
end

return SoundBank
