-- sounds and outputs

------------------------------
-- todo: figure out if rqmin & rqmax named correctly
------------------------------

local plant_sounds = {}
plant_sounds.__index = plant_sounds

function plant_sounds:new(parent)
  local ps = {}
  ps.index = 1
  setmetatable(ps, sounds)
  
  ps.active_notes = {}

  local externals1 = plant_sounds_externals:new(ps.active_notes)
  local externals2 = plant_sounds_externals:new(ps.active_notes)

  all_notes_off = function()
    if (params:get("output") == 2 or params:get("output") == 3) then
      for _, a in pairs(ps.active_notes) do
        midi_out_device:note_off(a, nil, midi_out_channel1)
        midi_out_device:note_off(a, nil, midi_out_channel2)
      end
    end
    ps.active_notes = {}
  end

  ps.engine_note_on = function(note_to_play, freq, random_note_frequency)
    envelopes[parent.id].update_envelope()
    engine.note_on(note_to_play, freq, random_note_frequency)
  end
    
  ps.play = function(node_obj)
    if (node_obj.s_id == parent.current_sentence_id) then
      if (node_obj.note) then
        clock.sync(node_obj.duration)
        parent.show_note = true
      end
      -- clock.sync(node_obj.duration)
      if (node_obj.s_id == parent.current_sentence_id) then
        if (#node_obj.s == node_obj.i) then
          parent.current_sentence_id = parent.current_sentence_id + 1
        end

        local note_index = node_obj.i
        local turtle_position = parent.turtle.get_position(note_index)
        if (turtle_position and turtle_position.x) then
          current_note_indices[parent.id] = note_index
        end
        
        if (node_obj.note and parent.initializing == false) then
          
          -- set a random scalar for the note about to play
          local num_active_cf_scalars = params:get("num_active_cf_scalars")
          local random_cf_scalars_index = params:get(cf_scalars[math.random(num_active_cf_scalars)])
          local cf_scalar = cf_scalars_map[random_cf_scalars_index]

          -- set a random note_frequency for the note about to play
          local num_note_freq_index = math.random(#tempo_offset_note_frequencies)
          local random_note_frequency = tempo_offset_note_frequencies[num_note_freq_index]
          
          local note_to_play = node_obj.note
          note_to_play = node_obj.note > 0 and node_obj.note or #notes
          note_to_play = note_to_play <= #notes and note_to_play or 1
          note_to_play = notes[note_to_play]

          local freq = MusicUtil.note_num_to_freq(note_to_play)
          freq = freq * cf_scalar
          note_to_play = MusicUtil.freq_to_note_num(freq)
          local output_param = params:get("output")
          if output_param == 1 or output_param == 3 or output_param == 4 then
            ps.engine_note_on(note_to_play, freq, random_note_frequency)
          end
          local midi_out_channel = parent.id == 1 and midi_out_channel1 or midi_out_channel2
          if parent.id == 1 then 
            externals1.note_on(parent.id, note_to_play, freq, random_note_frequency)
          else
            externals2.note_on(parent.id, note_to_play, freq, random_note_frequency)
          end 
        elseif (node_obj.rest and parent.initializing == false) then
          clock.sync(node_obj.duration)
          -- clock.sleep(node_obj.duration)
        end

        if node_obj.restart then
          node_obj.play_fn()
        elseif (node_obj.s_id == parent.current_sentence_id) then
            node_obj.play_fn(node_obj.i, ps.note, node_obj.s_id)
        end
      end
    end
  end

  ps.set_note_scalar = function(x)
    note_scalar = x
  end
  
  ps.set_note_duration = function(duration)
    ps.note_duration = duration
  end

  ps.get_note_duration = function()
    return ps.note_duration
  end

  
  ps.set_note = function(last_index, last_note, last_s_id)
    local s = parent.lsys.get_sentence()
    ps.note = last_note and last_note or #notes/2
    local s_id = last_s_id and last_s_id or parent.current_sentence_id
    if (parent.changing_instructions == false and s_id == parent.current_sentence_id) then
      i = last_index and last_index + 1 or 1
      local l = string.sub(s, i, i)
      local node_obj = {}
      node_obj.s_id = parent.current_sentence_id
      node_obj.duration = ps.get_note_duration()
      if i == #s then
        node_obj.restart = true
        node_obj.s = s
        node_obj.i = i
        node_obj.play_fn = ps.set_note
      else
        node_obj.restart = false
        node_obj.s = s
        node_obj.i = i
        node_obj.play_fn = ps.set_note
      end  
      if l == "F" then
        node_obj.note = ps.note
      elseif l == "G" then
        node_obj.rest = 1
      elseif l == "[" then
        parent.sound_matrix.push_matrix(note)
      elseif l == "]" then
        ps.note = parent.sound_matrix.pop_matrix()
      elseif (l == "+" and ps.note) then
        local new_note = ps.note + math.ceil(note_scalar * parent.turtle.theta) <= #notes and ps.note + math.ceil(note_scalar * parent.turtle.theta) or 1
        ps.note = new_note
      elseif (l == "-" and ps.note) then
        local new_note = ps.note + math.ceil(note_scalar * -parent.turtle.theta) > 1 and ps.note + math.ceil(note_scalar * -parent.turtle.theta)  or #notes
        ps.note = new_note
      end
      clock.run(ps.play,node_obj)
    else 
      parent.changing_instructions = false
      parent.current_sentence_id = parent.current_sentence_id + 1
      ps.set_note()
    end
  end
  
  return ps
end

return plant_sounds
