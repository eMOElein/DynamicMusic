# Dynamic Music
A configurable framework that provides support for situation specific custom ambient music for OpenMW  
https://www.nexusmods.com/morrowind/mods/53568


# Script Settings
## General Settings
### Use Default Soundbank
This uses the DEFAULT soundbank from **scripts/DynamicMusic/soundbanks/DEFAULT.lua** for all situations that are not covered by any other soundbank. This needs to be active for most of the dynamic combat music settings to work properly.
If you had custom music tracks in your vanilla music folder you need to add them to the DEFAULT soundbank manually as it only contains the vanilla Morrowind tracks.

## Combat Settings
### Play combat music
Controls whether combat music should be played or not.
If you set this to no then combat music will not be played at all.

### Min.Enemy Level
Combat music will only play if the enemy that is attacking has at least this level. Otherwise exploration music continues to play.

### Min. Level Difference
Ensures that combat music is still being played if the player is not X levels ahead of the enemy.
Even if the enemy's level is below the value that was set in "Min. Enemy Level".
This way low level enemys that might still be a threat if the player has a low level will trigger combat music.
Set this option to 0 if you don't like this behaviour.

# Soundbanks
Soundbanks are Lua tables that are used to tell Dynamic Music what tracks to play and when.\
All soundbanks need to be stored in **scripts/DynamicMusic/soundbanks** in your Morrowind installation's **Data Files** folder.\
 \
A soundbank contains a list of exploration and/or combat tracks and a set of filters that are used to determine in which situation the tracks should be played.

### Soundbank Priority
Soundbanks are prioritized by their name.\
If two or more soundbanks are allowed to play for the current ingame situation the one that come's **last** in alphabetical order (by filename) will be played.

### Example Soundbank

```lua
local soundbank = {
    -- The soundbank is only allowed to play if the current cell's name contains one or more of the strings listed in this filter
    -- Be careful with special characters as they need to work properly with Lua's string.gmatch function which is used
    -- to determine if the cell's name contains the pattern.
    -- Escape special characters properly.
    -- If this filter is not provided it will be ignored.
    cellNamePatterns = {
        'Balmora',
        'Mage\'s Guild'
    },
    -- The soundbank is only allowed to play if the current cell's name exactly matches with one or more of the strings listed in this filter.
    -- If this filter is not provided it will be ignored.
    cellNames = {
        'Balmora',
        'Balmora, Guild of Mages'
    },
    -- This is a bit misleading at the moment since region id's are expected here instead of region names.
    -- The soundbank is only allowed to play it the current cell's region id matches one of the region Id's listed in this filter.
    -- If this filter is not provided it will be ignored.
    regionNames = {
        'armun ashlands region',
        'ashlands region'
    },
    -- If this filter is set to true the soundbank is only allowed to play if the current cell is an interior cell.
    -- If this filter is not provided it will be ignored.
    interiorOnly = true,
    -- If this filter is set to true the soundbank is only allowed to play if the current cell is an exterior cell.
    -- If this filter is not provided it will be ignored.
    exteriorOnly = true,
    -- If this filter is set the soundbank is only allowed during the ingame hours in the list.
    -- In this example the soundbank is allowed to play from 18:00pm until 21:00pm
    -- It this filter is not provided it will be ignored.
    hourOfDay = {18,19,20},
    -- This filter is only checked if the game is currently in "combat" state.
    -- Combat tracks are only played if the enemy's name matches with one of the strings listed in this filter.
    -- If this filter is not provided it will be ignored.
    enemyNames = {
        "Ascended Sleeper",
        "Ash Ghoul",
        "Ash Slave",
    },
    -- Tracks that should play if the game is in "exploration" state
    tracks = {
        {
            -- Path to a track.
            path = 'Music/dm_personal/dfu_magic_2.mp3',
            -- The track's length in seconds.
            length = 88
        },
        {
            -- Path to another track.
            path = 'Music/dm_personal/dfu_magic_3.mp3',
            -- The track's length in seconds.
            length = 62
        }
    },
    -- Tracks that should play if the game is in "combat" state.
    combatTracks = {
        {
            -- Path to a track.
            path = "Music/MS/combat/Dagoth/combat1.mp3",
            -- The track's length in seconds.
            length = 56
        },
        {
            -- Path to a another track.
            path = "Music/MS/combat/Dagoth/combat2.mp3",
            -- The track's length in seconds.
            length = 58
        }
    }
}

return soundbank
```
