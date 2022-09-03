-- hnds
--
-- Lua lfo's for script
-- parameters.
-- ----------
--
-- from v0.4 @justmat's otis

local number_of_lfos = 2

local tau = math.pi * 2

local options = {
  lfotypes = {
    "sine",
    "square",
    "s+h"
  }
}

local lfo = {}
for i = 1, number_of_lfos do
  lfo[i] = {
    freq = 0.01,
    counter = 1,
    waveform = options.lfotypes[1],
    slope = 0,
    depth = 100,
    offset = 0
  }
end

-- redefine in user script ---------
for i = 1, number_of_lfos do
  lfo[i].lfo_targets = {"none"}
end

function lfo.process()
end
------------------------------------


function lfo.scale(old_value, old_min, old_max, new_min, new_max)
  -- scale ranges
  local old_range = old_max - old_min

  if old_range == 0 then
    old_range = new_min
  end

  local new_range = new_max - new_min
  local new_value = (((old_value - old_min) * new_range) / old_range) + new_min

  return new_value
end


local function make_sine(n)
  return 1 * math.sin(((tau / 100) * (lfo[n].counter)) - (tau / (lfo[n].freq)))
end


local function make_square(n)
  return make_sine(n) >= 0 and 1 or -1
end


local function make_sh(n)
  local polarity = make_square(n)
  if lfo[n].prev_polarity ~= polarity then
    lfo[n].prev_polarity = polarity
    return math.random() * (math.random(0, 1) == 0 and 1 or -1)
  else
    return lfo[n].prev
  end
end


function lfo.setup_params()
  for i = 1, number_of_lfos do
    -- modulation destination
    params:add_group("lfo " .. i, 13)
    -- params:add_option(i .. "lfo_target", i .. " lfo target", lfo[i].lfo_targets, 1)
    -- lfo on/off
    params:add_option(i .. "lfo", i .. " lfo", {"off", "on"}, 2)
    -- lfo shape
    params:add_option(i .. "lfo_shape", i .. " shape", options.lfotypes, 1)
    params:set_action(i .. "lfo_shape", function(value) lfo[i].waveform = options.lfotypes[value] end)
    -- lfo depth
    params:add_number(i .. "lfo_depth", i .. " depth", 0, 100, 100)
    params:set_action(i .. "lfo_depth", function(value) lfo[i].depth = value end)
    -- lfo offset
    params:add_control(i .."offset", i .. " offset", controlspec.new(-4.0, 3.0, "lin", 0.1, 0.0, ""))
    params:set_action(i .. "offset", function(value) lfo[i].offset = value end)
    -- lfo speed
    params:add_control(i .. "lfo_freq", i .. " freq", controlspec.new(0.01, 10.0, "lin", 0.1, 0.5, ""))
    params:set_action(i .. "lfo_freq", function(value) lfo[i].freq = value end)
    
    params:add_separator("::crow settings::")
    -- lfo slew
    params:add_control(i .. "lfo_slew", i .. " slew (ms)", controlspec.new(0, 2000, 'lin', 0, 31.25, "",0.001))

    params:add_control(i .. "lfo_volts_min", i .. " min v", controlspec.new(-5, 10, 'lin', 0, 0, ""))
    params:set_action(i .. "lfo_volts_min", function(value) 
      local current_max_value = params:get(i.."lfo_volts_max")
      if value > current_max_value then 
        value = current_max_value
        params:set(i.."lfo_volts_min",value)
      end  
    end)

    params:add_control(i .. "lfo_volts_max", i .. " max v", controlspec.new(-5, 10, 'lin', 0, 5, ""))
    params:set_action(i .. "lfo_volts_max", function(value) 
      local current_min_value = params:get(i.."lfo_volts_min")
      if value < current_min_value then 
        value = current_min_value
        params:set(i.."lfo_volts_max",value)
      end    
    end)

    -- MIDI_LFO1 = 102 -- set in globals.lua
    -- MIDI_LFO2 = 103 -- set in globals.lua
    params:add_separator("::midi settings::")
    params:add_option(i .. "play_midi_lfo_cc", i .. " lfo cc out", {"off", "on"}, 2)
    params:add_number(i .. "midi_lfo_cc", i .. " lfo cc", 0, 127, MIDI_LFO_CC_DEFAULT+i)
    params:add_number(i .. "midi_lfo_chan", i .. " lfo chan", 0, 127, MIDI_LFO_CHANNEL_DEFAULT + i)
    -- params:add_separator("::read only::")
    -- params:add_control(i .. "lfo_value", i .. " lfo value", controlspec.new(-1, 1, "lin", 0.001, 0.0001, ""))
  end

end
function lfo.init()
  -- lfo.setup_params()
  local lfo_metro = metro.init()
  lfo_metro.time = .01
  lfo_metro.count = -1
  lfo_metro.event = function()
    for i = 1, number_of_lfos do
      if params:get(i .. "lfo") == 2 then
        local slope
        if lfo[i].waveform == "sine" then
          slope = make_sine(i)
        elseif lfo[i].waveform == "square" then
          slope = make_square(i)
        elseif lfo[i].waveform == "s+h" then
          slope = make_sh(i)
        end
        lfo[i].prev = slope
        lfo[i].slope = math.max(-1.0, math.min(1.0, slope)) * (lfo[i].depth * 0.01) + lfo[i].offset
        lfo[i].counter = lfo[i].counter + lfo[i].freq
        -- params:set(i.."lfo_value",lfo[i].slope)
      end
    end
    lfo.process()
  end
  lfo_metro:start()
end


return lfo
