local mydir = debug.getinfo(1).source:match("@?" .. _path.code .. "(.*/)")
local player_lib = include(mydir .. "player")
local nb = {}

if note_players == nil then
    note_players = {}
end

-- note_players is a global that you can add note-players to from anywhere before
-- you call nb:add_param.
nb.players = note_players -- alias the global here. Helps with standalone use.

nb.none = player_lib:new()

-- Set this before init() to affect the number of voices added for some mods.
nb.voice_count = 1

local abbreviate = function(s)
    if string.len(s) < 8 then return s end
    local acronym = util.acronym(s)
    if string.len(acronym) > 3 then return acronym end
    return string.sub(s, 1, 8)
end

local function add_midi_players()
    for i, v in ipairs(midi.vports) do
        for j = 1, nb.voice_count do
            (function(i, j)
                if v.connected then
                    local conn = midi.connect(i)
                    local player = {
                        conn = conn
                    }
                    function player:add_params()
                        params:add_group("midi_voice_" .. i .. '_' .. j, "midi " .. j .. ": " .. abbreviate(v.name), 3)
                        params:add_number("midi_chan_" .. i .. '_' .. j, "channel", 1, 16, 1)
                        params:add_number("midi_modulation_cc_" .. i .. '_' .. j, "modulation cc", 1, 127, 72)
                        params:add_number("midi_bend_range_" .. i .. "_" .. j, "bend range", 1, 48, 12)
                        params:hide("midi_voice_" .. i .. '_' .. j)
                    end

                    function player:ch()
                        return params:get("midi_chan_" .. i .. '_' .. j)
                    end

                    function player:note_on(note, vel)
                        self.conn:note_on(note, util.clamp(math.floor(127 * vel), 0, 127), self:ch())
                    end

                    function player:note_off(note)
                        self.conn:note_off(note, 0, self:ch())
                    end

                    function player:active()
                        params:show("midi_voice_" .. i .. '_' .. j)
                        _menu.rebuild_params()
                    end

                    function player:inactive()
                        params:hide("midi_voice_" .. i .. '_' .. j)
                        _menu.rebuild_params()
                    end

                    function player:modulate(val)
                        self.conn:cc(params:get("midi_modulation_cc_" .. i .. '_' .. j),
                            util.clamp(math.floor(127 * val), 0, 127),
                            self:ch())
                    end

                    function player:modulate_note(note, key, value)
                        if key == "pressure" then
                            self.conn:key_pressure(note, util.round(value * 127), self:ch())
                        end
                    end

                    function player:pitch_bend(note, amount)
                        local bend_range = params:get("midi_bend_range_" .. i .. '_' .. j)
                        if amount < -bend_range then
                            amount = -bend_range
                        end
                        if amount > bend_range then
                            amount = bend_range
                        end
                        local normalized = amount / bend_range -- -1 to 1
                        local send = util.round(((normalized + 1) / 2) * 16383)
                        self.conn:pitchbend(send, self:ch())
                    end

                    function player:describe()
                        local mod_d = "cc"
                        if params.lookup["midi_modulation_cc_" .. i .. '_' .. j] ~= nil then
                            mod_d = "cc " .. params:get("midi_modulation_cc_" .. i .. '_' .. j)
                        end
                        return {
                            name = "v.name",
                            supports_bend = true,
                            supports_slew = false,
                            note_mod_targets = { "pressure" },
                            modulate_description = mod_d
                        }
                    end

                    nb.players["midi: " .. abbreviate(v.name) .. " " .. j] = player
                end
            end)(i, j)
        end
    end
end

-- Call from your init method.
function nb:init()
    nb_player_refcounts = {}
    add_midi_players()
    self:stop_all()
end

-- Add a voice select parameter. Returns the parameter. You can then call
-- `get_player()` on the parameter object, which will return a player you can
-- use to play notes and stuff.
function nb:add_param(param_id, param_name)
    local names = {}
    for name, _ in pairs(note_players) do
        table.insert(names, name)
    end
    table.sort(names)
    table.insert(names, 1, "none")
    local names_inverted = tab.invert(names)
    params:add_option(param_id, param_name, names, 1)
    local string_param_id = param_id .. "_hidden_string"
    params:add_text(string_param_id, "_hidden string", "")
    params:hide(string_param_id)
    local p = params:lookup_param(param_id)
    local initialized = false
    function p:get_player()
        local name = params:get(string_param_id)
        if name == "none" then
            if p.player ~= nil then
                p.player:count_down()
            end
            p.player = nil
            return nb.none
        elseif p.player ~= nil and p.player.name == name then
            return p.player
        else
            if p.player ~= nil then
                p.player:count_down()
            end
            local ret = player_lib:new(nb.players[name])
            ret.name = name
            p.player = ret
            ret:count_up()
            return ret
        end
    end

    clock.run(function()
        clock.sleep(1)
        p:get_player()
        initialized = true
    end, p)
    params:set_action(string_param_id, function(name_param)
        local i = names_inverted[params:get(string_param_id)]
        if i ~= nil then
            -- silently set the interface param.
            params:set(param_id, i, true)
        end
        p:get_player()
    end)
    params:set_action(param_id, function()
        if not initialized then return end
        local i = p:get()
        params:set(string_param_id, names[i])
    end)
end

local function pairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0             -- iterator variable
    local iter = function() -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function nb:add_player_params()
    if params.lookup['nb_sentinel_param'] then
        return
    end
    for name, player in pairsByKeys(self:get_players()) do
        player:add_params()
    end
    params:add_binary('nb_sentinel_param', 'nb_sentinel_param')
    params:hide('nb_sentinel_param')
end

-- Return all the players in an object by name.
function nb:get_players()
    local ret = {}
    for k, v in pairs(self.players) do
        ret[k] = player_lib:new(v)
    end
    table.sort(ret)
    return ret
end

-- Stop all voices. Call when you load a pset to avoid stuck notes.
function nb:stop_all()
    for _, player in pairs(self:get_players()) do
        player:stop_all()
    end
end

return nb
