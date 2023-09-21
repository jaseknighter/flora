local player = {
    length = 1.0
}

if nb_player_refcounts == nil then
    nb_player_refcounts = {}
end

-- Wrap an object to be a full "player", with default implementations of all
-- the player methods
function player:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Implement this to add params from your player to the script
function player:add_params()
end

-- Implement to do midi-style note-on. If you only implement play_note,
-- you should implement a trivial note_on to call it.
-- "properties" is an optional table of note mod properties. It should
-- contain only keys that the vocie says it can modulate in note_mod_targets
-- in the description.
-- The note should be interepereted as pitch mod 128. High-value notes may be sent
-- in the case two note-ons happen for the same note; this is possible in MPE situations.
function player:note_on(note, vel, properties)
end

-- Implement to do midi-style note-off. This is optional if you implement
-- play_note instead.
function player:note_off(note)
end

-- Optional. Send pitch bend to the voice. If the voice doesn't support
-- per-note pitch bend, may bend all notes. Amount is given in semitones.
function player:pitch_bend(note, amount)
end

-- Optional. Modulate the voice, in whatever way seems best. Range 0-1.
function player:modulate(val)
end

-- Optional. Modulate the voice, in the way that corresponds to the key. Range 0-1.
-- Implementations may choose to a param on the voice or send-and-forget.
-- The `key` should be present in voice_mod_targets in the description.
function player:modulate_voice(key, val)
end

-- Optional. Set the slew time for the voice. 
-- May be an alias for `modulate_voice`, but accepts a slew time in _seconds_.
function player:set_slew(slew)
end

-- Optional. Modulate a single note. `key` should be present in note_mod_targets
-- in the description. `value` should be between -1 and 1.
-- Depending on the parameter, the voice may interperet modulation as either
-- additive to, multiplicative of, or replacing any timbral properties.
-- For example, modulating `amp` should multiply with the `amp` in properties, 
-- but modulating a filter cutoff should be additive.
function player:modulate_note(note, key, value)
end

-- Recommended.  Describe the voice's capabilities.
-- Supported keys:
-- supports_bend (does this voice support pitch bend?)
-- supports_slew (does this voice support set_slew?)
-- note_mod_targets (optional list of targets for "note mod")
function player:describe()
    return {
        name = "none",
        supports_bend = false,
        supports_slew = false,
        modulate_description = "unsupported",
        note_mod_targets = {},
        voice_mod_tarets = {},
    }
end

-- Optional. Callback for when a voice is used by at least one selector.
-- Suggest using it to show parameters to control the voice.
function player:active()
    self.is_active = true
    self.active_routine = clock.run(function()
        clock.sleep(1)
        if self.is_active then
            self:delayed_active()
        end
        self.active_routine = nil
    end)
end

-- Optional. Callback for when a voice is slected for more than one second.
-- This is where you want to change modes on external devices or whatever.
function player:delayed_active()
end

-- Optional. Callback for when a voice is no longer used. Useful for hiding
-- parameters or whatnot.
function player:inactive()
    self.is_active = false
    if self.active_routine ~= nil then
        clock.cancel(self.active_routine)
    end
end

-- Stop all voices. Use on pset load.
function player:stop_all()
end

-- Play a note for a given length. `properties` is optional, see note_on
-- for further description.
function player:play_note(note, vel, length, properties)
    self:note_on(note, vel, properties)
    clock.run(function()
        clock.sleep(length*clock.get_beat_sec())
        self:note_off(note)
    end)
end

-- Private.
function player:count_up()
    if self.name ~= nil then
        if nb_player_refcounts[self.name] == nil then
            nb_player_refcounts[self.name] = 1
            self:active()
        else
            nb_player_refcounts[self.name] = nb_player_refcounts[self.name] + 1
        end
    end
end

-- Private
function player:count_down()
    if self.name ~= nil then
        if nb_player_refcounts[self.name] ~= nil then
            nb_player_refcounts[self.name] = nb_player_refcounts[self.name] - 1
            if nb_player_refcounts[self.name] == 0 then
                nb_player_refcounts[self.name] = nil
                self:inactive()
            end
        end
    end
end

return player
