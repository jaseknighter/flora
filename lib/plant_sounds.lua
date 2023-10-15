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
    if (params:get("output_midi") > 1) then
      for _, a in pairs(ps.active_notes) do
        midi_out_device:note_off(a, nil, midi_out_channel1)
        midi_out_device:note_off(a, nil, midi_out_channel2)
      end
    end
    ps.active_notes = {}
  end

  ps.find_note = function(note)
    local note_idx=1
    for i=1,#notes do
      if note==notes[i] then note_idx = i end
    end
    return note_idx
  end

  ps.engine_note_on = function(note_to_play, freq, random_note_frequency, skip_engine)
    envelopes[parent.id].update_envelope()
    
    local tin_target = params:get("tin_target")
    if tin_target == parent.id or tin_target == 3 then  
      tt.set_tt_note(note_to_play)
    end

    if skip_engine == false and (params:get("output_bandsaw")==1 or params:get("output_bandsaw")>=3) then
      engine.note_on(note_to_play, freq, random_note_frequency)
    end
    -- local psn1=params:get("pitchshift1")
    -- local psn2=params:get("pitchshift2")
    -- local psn3=params:get("pitchshift3")
    -- engine.pitchshift_note1(psn1)
    -- engine.pitchshift_note2(psn2)
    -- engine.pitchshift_note3(psn3)
  end

  ps.engine_tin_note_on = function(note_to_play, velo)
    if params:get("output_bandsaw")==2 or params:get("output_bandsaw")==3 then
      local freq = MusicUtil.note_num_to_freq(note_to_play)
      local tin_env = params:get("tin_env")
      if tin_env == 1 then
        engine.set_env_levels(0,velo,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
      elseif tin_env == 2 then
        envelopes[active_plant].update_envelope()
      elseif tin_env == 3 then
        local env_arrays = deep_copy(tt.env_arrays)
        add_nil_values_to_array(env_arrays.levels,MAX_ENVELOPE_NODES)
        add_nil_values_to_array(env_arrays.times,MAX_ENVELOPE_NODES)
        add_nil_values_to_array(env_arrays.curves,MAX_ENVELOPE_NODES)
  
        engine.set_env_levels(table.unpack(env_arrays.levels))
        engine.set_env_times(table.unpack(env_arrays.times))
        engine.set_env_curves(table.unpack(env_arrays.curves))
      
      
      end
      -- envelopes[parent.id].update_envelope()
      engine.note_on(note_to_play, freq, 1)
    end
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
    
          -- print(note_to_play, freq, random_note_frequency)
          local note_idx = ps.find_note(note_to_play) - 1
          
          if params:get("output_bandsaw")==1 or params:get("output_bandsaw")==3 then
            ps.engine_note_on(note_to_play, freq, random_note_frequency, false)
          else
            ps.engine_note_on(note_to_play, freq, random_note_frequency, true )
          end

          if parent.id == 1 then 
            clock.run(ps.externals1.note_on,parent.id, note_to_play, freq, random_note_frequency,nil,"flora")
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
