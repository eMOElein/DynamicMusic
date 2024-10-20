local vfs = require('openmw.vfs')

local Track = {}

function Track.Create(path)
    if not path then
        error("path not specified", 2)
    end

    local track = {}
    track.length = -1

    track.setLength = Track.setLength
    track.setPath = Track.setPath

    track:setPath(path)

    return track
end

function Track.isValid(self)
    return vfs.fileExists(self.path)
end

function Track.setLength(self, length)
    self.length = length
end

function Track.setPath(self, path)
    self.path = path
    self.pathLower = string.lower(path)
end

Track.Decoder = {
    fromTable = function(dataTable)
        if not dataTable.path then
            error("path not specified")
        end

        local track = Track.Create(dataTable.path)

        if dataTable.length then
            track:setLength(dataTable.length)
        end

        return track
    end
}

return Track
