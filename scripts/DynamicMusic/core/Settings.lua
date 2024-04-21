local I = require('openmw.interfaces')
local storage = require('openmw.storage')

local Settings = {}
Settings._SETTINGS_DB = {}

Settings.KEYS = {
    COMBAT_MIN_ENEMY_LEVEL = 'COMBAT_MIN_ENEMY_LEVEL',
    COMBAT_MIN_LEVEL_DIFFERENCE = 'COMBAT_MIN_LEVEL_DIFFERENCE',
    GENERAL_PLAY_COMBAT_MUSIC = 'GENERAL_PLAY_COMBAT_MUSIC',
    GENERAL_PLAY_EXPLORATION_MUSIC = 'GENERAL_PLAY_EXPLORATION_MUSIC',
    GENERAL_USE_DEFAULT_SOUNDBANK = 'GENERAL_USE_DEFAULT_SOUNDBANK'
}

Settings.PAGE = {
    key = 'Page_openmw_dynamic_music',
    l10n = 'Dynamic_Music',
    name = 'Dynamic Music',
    description = 'Dynamic Music Framework',
}

Settings.GROUPS = {
    GENERAL = {
        key = 'Settings_openmw_dynamic_music_1000_general',
        page = Settings.PAGE.key,
        l10n = 'Dynamic_Music',
        name = '1: General Settings',
        description = 'General Settings',
        permanentStorage = true
    },
    COMBAT= {
        key = 'Settings_openmw_dynamic_music_2000_combat',
        page = Settings.PAGE.key,
        l10n = 'Dynamic_Music',
        name = '2: Combat Settings',
        description = 'Combat related settings.',
        permanentStorage = true
    }
}

Settings.SETTINGS = {
    {
        key = Settings.KEYS.COMBAT_MIN_ENEMY_LEVEL,
        group = Settings.GROUPS.COMBAT,
        renderer = 'number',
        name = 'Min. Enemy Level',
        description =
        'Minimum enemy level needed to play combat music. (Needs activated DEFAULT soundbank to work in areas where no soundbank matches)',
        default = 5,
    },
    {
        key = Settings.KEYS.COMBAT_MIN_LEVEL_DIFFERENCE,
        group = Settings.GROUPS.COMBAT,
        renderer = 'number',
        name = 'Min. Level Difference',
        description =
        'Ignore Min. Enemy Level if the player is not X levels above the enemy\'s level. (Needs activated DEFAULT soundbank to work in areas where no soundbank matches)',
        default = 2,
    },
    {
        key = Settings.KEYS.GENERAL_PLAY_COMBAT_MUSIC,
        group = Settings.GROUPS.GENERAL,
        renderer = 'checkbox',
        name = 'Play Combat Music',
        description = 'Whether combat music should be played or not.',
        default = true,
    },
    {
        key = Settings.KEYS.GENERAL_PLAY_EXPLORATION_MUSIC,
        group = Settings.GROUPS.GENERAL,
        renderer = 'checkbox',
        name = 'Play Exploration Music',
        description = 'Whether exploration music should be played or not.',
        default = true,
    },
    {
        key = Settings.KEYS.GENERAL_USE_DEFAULT_SOUNDBANK,
        group = Settings.GROUPS.GENERAL,
        renderer = 'checkbox',
        name = 'Use DEFAULT Soundbank',
        description = 'Uses the DEFAULT soundbank if no other soundbank matches. If you have custom tracks in your vanilla playlist they will be ignored and need to be added to the DEFAULT soundbank manually.',
        default = false,
    }
}

I.Settings.registerPage {
    key = Settings.PAGE.key,
    l10n = Settings.PAGE.l10n,
    name = Settings.PAGE.name,
    description = Settings.PAGE.description
}

for _, group in pairs(Settings.GROUPS) do
    print("REGISTERGROUP: " .. group.name)

    local settings = {}
    for _, s in pairs(Settings.SETTINGS) do
        if s.group == group then
            local setting = {
                key = s.key,
                renderer = s.renderer,
                name = s.name,
                description = s.description,
                default = s.default
            }

            table.insert(settings, setting)
        end
    end

    I.Settings.registerGroup {
        key = group.key,
        page = Settings.PAGE.key,
        l10n = group.l10n,
        name = group.name,
        description = group.description,
        permanentStorage = true,
        settings = settings
    }

    local playerSection = storage.playerSection(group.key)
    for _, setting in pairs(settings) do
        Settings._SETTINGS_DB[setting.key] = setting
        setting._playerSection = playerSection
    end
end

function Settings.getValue(key)
    return Settings._SETTINGS_DB[key]._playerSection:get(key)
end

return Settings
