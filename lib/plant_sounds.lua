-- sounds and outputs

------------------------------
-- todo: figure out if rqmin & rqmax named correctly
------------------------------


local midi_out_device = midi.connect(1)
midi_out_device.event = function() end


local flora_sounds = {}
flora_sounds.__index = flora_sounds

function flora_sounds:new(parent)
  local fs = {}
  fs.index = 1
  setmetatable(fs, sounds)
  
  fs.active_notes = {}

  all_notes_off = function()
    if (params:get("output") == 2 or params:get("output") == 3) then
      for _, a in pairs(fs.active_notes) do
        midi_out_device:note_off(a, nil, midi_out_channel1)
        midi_out_device:note_off(a, nil, midi_out_channel2)
      end
    end
    fs.active_notes = {}
  end

  fs.note_on = function(note_to_play, freq)
    envelopes[parent.id].update_envelope()
    engine.note_on(note_to_play, freq)
  end

  fs.midi_note_off = function(delay, note_num, channel)
    clock.sync(delay)  
    midi_out_device:note_off(note_num, nil, channel)

  end
  
  fs.play = function(node_obj)
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
          local note_to_play = node_obj.note > 0 and node_obj.note or #notes
          local note_to_play = note_to_play <= #notes and note_to_play or 1
          local note_to_play = notes[note_to_play]
          local freq = MusicUtil.note_num_to_freq(note_to_play)
          local output_param = params:get("output")
          if output_param == 1 or output_param == 3 or output_param == 4 then
            fs.note_on(note_to_play, freq)
          end
    
          -- MIDI out
          fs.midi_out_channel = parent.id == 1 and midi_out_channel1 or midi_out_channel2
          if output_param == 2 or output_param == 3 then
            midi_out_device:note_on(note_to_play, 96, fs.midi_out_channel)
            table.insert(fs.active_notes, note_to_play)

            -- Note off timeout
            local note_duration_param = parent.id == 1 and "plant_1_note_duration" or "plant_2_note_duration"
            local envelope_length = envelopes[parent.id].get_env_time()
            clock.run(fs.midi_note_off, envelope_length, note_to_play, fs.midi_out_channel)
          end

          if output_param == 4 then
            crow.output[1].volts = (note_to_play-60)/12
            crow.output[2].execute()
          end
          if output_param == 4 or output_param == 5 then
            crow.ii.jf.play_note((note_to_play-60)/12,5)
          end
          -- clock.sync(node_obj.duration)
        elseif (node_obj.rest and parent.initializing == false) then
          clock.sync(node_obj.duration)
        end

        if node_obj.restart then
          node_obj.play_fn()
        elseif (node_obj.s_id == parent.current_sentence_id) then
            node_obj.play_fn(node_obj.i, fs.note, node_obj.s_id)
        end
      end
    end
  end

  fs.set_note_scalar = function(x)
    note_scalar = x
  end
  
  fs.set_note_duration = function(duration)
    fs.note_duration = duration
  end

  fs.get_note_duration = function()
    return fs.note_duration
  end

  
  fs.set_note = function(last_index, last_note, last_s_id)
    local s = parent.lsys.get_sentence()
    fs.note = last_note and last_note or #notes/2
    local s_id = last_s_id and last_s_id or parent.current_sentence_id
    if (parent.changing_instructions == false and s_id == parent.current_sentence_id) then
      i = last_index and last_index + 1 or 1
      local l = string.sub(s, i, i)
      local node_obj = {}
      node_obj.s_id = parent.current_sentence_id
      node_obj.duration = fs.get_note_duration()
      if i == #s then
        node_obj.restart = true
        node_obj.s = s
        node_obj.i = i
        node_obj.play_fn = fs.set_note
      else
        node_obj.restart = false
        node_obj.s = s
        node_obj.i = i
        node_obj.play_fn = fs.set_note
      end  
      if l == "F" then
        node_obj.note = fs.note
      elseif l == "G" then
        node_obj.rest = 1
      elseif l == "[" then
        parent.sound_matrix.push_matrix(note)
      elseif l == "]" then
        fs.note = parent.sound_matrix.pop_matrix()
      elseif (l == "+" and fs.note) then
        local new_note = fs.note + math.ceil(note_scalar * parent.turtle.theta) <= #notes and fs.note + math.ceil(note_scalar * parent.turtle.theta) or 1
        fs.note = new_note
      elseif (l == "-" and fs.note) then
        local new_note = fs.note + math.ceil(note_scalar * -parent.turtle.theta) > 1 and fs.note + math.ceil(note_scalar * -parent.turtle.theta)  or #notes
        fs.note = new_note
      end
      clock.run(fs.play,node_obj)
    else 
      parent.changing_instructions = false
      parent.current_sentence_id = parent.current_sentence_id + 1
      fs.set_note()
    end
  end
  
  return fs
end

return flora_sounds
