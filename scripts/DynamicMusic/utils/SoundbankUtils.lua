local Soundbank = require('scripts.DynamicMusic.models.Soundbank')


--- @class SoundbankUtils
local SoundbankUtils = {}

function SoundbankUtils.loadSoundbank(file)
    local soundbank = require(file)

    if not soundbank.id or soundbank.id ~= "DEFAULT" then
        soundbank.id = file.gsub(file, soundbankDirectory, "")

        soundbank = Soundbank.Decoder.fromTable(soundbank)
    end
end

return SoundbankUtils