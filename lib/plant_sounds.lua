-- sounds and outputs

------------------------------
-- todo: figure out if rqmin & rqmax named correctly
------------------------------

local plant_sounds = {}
plant_sounds.__index = plant_sounds

function plant_sounds:new(parent)
  local ps = {}
  ps.restart = false
  ps.index = 1
  setmetatable(ps, sounds)
  
  ps.active_notes = {}

  -- local externals1 = plant_sounds_externals:new(ps.active_notes)
  -- local externals2 = plant_sounds_externals:new(ps.active_notes)
  ps.externals1 = plant_sounds_externals:new(ps.active_notes)
  ps.externals2 = plant_sounds_externals:new(ps.active_notes)
  
  all_notes_off = function()
    if (params:get("output_midi") > 2) then
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
      else 
        -- set clock.sync to 0.001 to prevent a stack overflow
        clock.sync(0.001)
      end
      envelopes[parent.id].modulate_env()
  
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
          
          local note_to_play = parent.id == 1 and node_obj.note + note_offset1 or node_obj.note + note_offset2
          note_to_play = note_to_play > 0 and note_to_play or #notes + note_to_play
          note_to_play = note_to_play <= #notes and note_to_play or note_to_play - #notes
          note_to_play = notes[note_to_play]

          local freq = MusicUtil.note_num_to_freq(note_to_play)
          freq = freq * cf_scalar
          note_to_play = MusicUtil.freq_to_note_num(freq)
          -- if parent.id == 1 then print("note_to_play", note_to_play) end
          -- local output_param = params:get("output")
          local output_engine = params:get("output_engine")
    
          if output_engine == 2 or output_engine == 4 then
            ps.engine_note_on(note_to_play, freq, random_note_frequency)
          end
          local midi_out_channel = parent.id == 1 and midi_out_channel1 or midi_out_channel2
          -- if parent.id == 1 and (output_engine > 1) then 
          if parent.id == 1 then 
            clock.run(ps.externals1.note_on,parent.id, note_to_play, freq, random_note_frequency,nil,"flora")
          -- elseif parent.id == 2 and (output_engine > 1) then 
          elseif parent.id == 2 then 
            clock.run(ps.externals2.note_on,parent.id, note_to_play, freq, random_note_frequency,nil,"flora")
          end 
        elseif (node_obj.rest and parent.initializing == false) then
          clock.sync(node_obj.duration)
          -- clock.sleep(node_obj.duration)
        end

        if ps.restart then
          ps.set_note()
        -- elseif (node_obj.s_id == parent.current_sentence_id) then
        else
          ps.set_note(node_obj.i, ps.note, node_obj.s_id)
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
    if (initializing == false and parent.changing_instructions == false and s_id == parent.current_sentence_id) then
      local i = last_index and last_index + 1 or 1
      local l = string.sub(s, i, i)
      local node_obj = {}
      node_obj.s_id = parent.current_sentence_id
      node_obj.duration = ps.get_note_duration()
      if i == #s then
        ps.restart = true
      else
        if ps.restart == true then
          ps.restart = false
        end 
      end  
      node_obj.s = s
      node_obj.i = i
      if l == "F" then
        node_obj.note = ps.note
      elseif l == "G" then
        node_obj.rest = 1
      elseif l == "[" then
        parent.sound_matrix.push_matrix(note)
      elseif l == "]" then
        ps.note = parent.sound_matrix.pop_matrix()
      elseif (l == "+" and ps.note) then
        local new_note = ps.note + math.ceil(note_scalar * parent.turtle.theta) 
        new_note = new_note <= #notes and ps.note + math.ceil(note_scalar * parent.turtle.theta) or 1 + (new_note-#notes)
        ps.note = new_note
      elseif (l == "-" and ps.note) then
        local new_note = ps.note + math.ceil(note_scalar * -parent.turtle.theta) 
        new_note = new_note > 1 and ps.note + math.ceil(note_scalar * -parent.turtle.theta)  or #notes - new_note
        ps.note = new_note
      elseif (l == "!" and ps.note) then
        local random_angle
        local check_polarity = string.sub(s, i+1, i+1)
        if check_polarity == "_" then
          random_angle = string.sub(s, i+2, i+4)
          random_angle = tonumber("-" .. random_angle)
          random_angle = math.rad(random_angle)
        else
          random_angle = tonumber(string.sub(s, i+1, i+3))
          random_angle = random_angle and math.rad(random_angle) or math.rad(0)
        end
         
        local new_note =  ps.note + math.ceil(note_scalar * random_angle)

        if new_note > #notes then
          new_note = 1 + (new_note-#notes)
        elseif new_note < 1 then
          new_note = #notes - new_note
        else
          new_note = ps.note + math.ceil(note_scalar * random_angle)  
        end
        
        ps.note = new_note
      end
      if parent.initializing == false and parent.playing == true then
        clock.run(ps.play,node_obj)
      end
    else 
      parent.changing_instructions = false
      parent.current_sentence_id = parent.current_sentence_id + 1
      ps.set_note()
    end
  end
  
  return ps
end

return plant_sounds
