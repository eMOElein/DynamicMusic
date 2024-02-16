local vfs = require('openmw.vfs')

local SoundBank = {}

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

    return soundBank
end

function SoundBank.countAvailableTracks(soundBank)
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

return SoundBank
