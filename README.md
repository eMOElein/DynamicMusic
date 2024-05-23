# Dynamic Music
A configurable framework that provides support for situation specific custom ambient music for OpenMW  
https://www.nexusmods.com/morrowind/mods/53568


# Script Settings
## General Settings
### Playlist priority
The priority that is used to generate the playlists.
This value should be below OpenMW Music's priority for combat playlists which is 10.
Otherwise the dynamic combat music will be overruled by OpenMW's vanilla combat music.

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
All soundbanks need to be stored in **scripts/DynamicMusic/soundBanks** in your Morrowind installation's **Data Files** folder.\
 \
A soundbank contains a list of exploration and/or combat tracks and a set of filters that are used to determine in which situation the tracks should be played.

### Soundbank Priority
Soundbanks are prioritized by their name.\
If two or more soundbanks are allowed to play for the current ingame situation the one that come's **last** in alphabetical order (by filename) will be played.