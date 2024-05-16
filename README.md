# Dynamic Music
A configurable framework that provides support for situation specific custom ambient music for OpenMW  
https://www.nexusmods.com/morrowind/mods/53568


Below you can find a detailed explanation of the settings options that are currently available in the script configuration menu.
# General Settings
## Use Default Soundbank
A default soundbank that is used as a fallback in every gameplay situation that is not covered by another sonudbank. This ensures that Dynamic Music is always active and always knows the track and the tracklength that is currently being played. This is needed for some features to work properly. The default soundbank only uses morrowind's vanilla tracks so if you have custom tracks in your vanilla music folders you need to add them to the default soundbank manually. This is necessary because a soundbank currently needs to know the exact length for each track and lua cannot determine the tracklength of an mp3 file. So unfortunately the default soundbank cannot be built automatically at runtime at the moment.

# Combat Settings
The framework supports dynamic combat music.
Combat music can be turned on/off or only play if the enemy is considered to be a threat to the player.
Dynamic combat music only works if the combat music is controlled through Dynamic Music itself so it is highly recommended to leave the default soundbank activated so that the music is controlled through Dynamic Music in every situation.

There's several options available here.
## Play Combat Music
Controls whether combat music should be played or not.
If you set this to no then combat music will not be played at all.

## Min.Enemy Level
Combat music will only play if the enemy that is attacking has at least this level. Otherwise exploration music continues to play.

## Min. Level Difference
Ensures that combat music is still being played if the player is not X levels ahead of the enemy.
Even if the enemy's level is below the value that was set in "Min. Enemy Level".
This way low level enemys that might still be a threat if the player has a low level will trigger combat music.
Set this option to 0 if you don't like this behaviour.