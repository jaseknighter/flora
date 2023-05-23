# Nota Bene

A norns library that plays notes well. 

The goal of this is to reduce the work of supporting a lot of different kinds of voices, and to allow people to install the voices they want to play with individually, as mods. You can also package voices with your script. 


To use the `nb` library in your script, do:
```
git submodule add https://github.com/sixolet/nb.git lib/nb
```

This will add `nb` as a *submodule*. You can then update it to the latest version by using

```
git submodule update --remote
git commit -m 'update submodules'
```

Then you can edit your script to use the `nb` library. Some highlights:

```
nb:init() -- run this first, from your init method.
```

```
nb:add_param("voice_id", "voice") -- adds a voice selector param to your script.
nb:add_player_params() -- Adds the parameters for the selected voices to your script.
```

```
-- Grab the chosen voice's player off your param
local player = params:lookup_param("voice_id"):get_player()
-- Play a note at velocity 0.5 for 0.2 beats (according to the norns clock)
player:play_note(48, 0.5, 0.2)
-- You can also use note_on and note_off methods
player:note_on(48, 0.5)
--- time elapses...
player:note_off(48)
```

MIDI devices that are currently connected while the script is started will be available for selection as vocies. Other vocies depend on any voices included with the script or installed as mods.
