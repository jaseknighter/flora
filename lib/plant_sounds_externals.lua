-- external sounds and outputs

local plant_sounds_externals = {}
plant_sounds_externals.__index = plant_sounds_externals

function plant_sounds_externals:new(active_notes)
  local pse = {}
  pse.index = 1
  setmetatable(pse, plant_sounds_externals)

  


  pse.midi_note_off = function(delay, note_num, channel, plant_id, note_location)
    local note_off_delay
    if plant_id == 1 then
      note_off_delay = midi_out_envelope_override1 or delay
    elseif plant_id == 2 then
      note_off_delay = midi_out_envelope_override2 or delay
    end
    clock.sleep(note_off_delay)
    if note_location <= #active_notes then
      table.remove(active_notes, note_location)
    else
    --   print("note location is out of bounds!!!", note_location, #active_notes)
    end
    midi_out_device:note_off(note_num, nil, channel)
  end
 
  pse.note_on = function(plant_id, note_to_play, pitch_frequency, beat_frequency, envelope_time_remaining)
    local output_midi = params:get("output_midi")
    local output_crow = params:get("output_crow")
    local output_crow2 = params:get("output_crow2")
    local output_crow4 = params:get("output_crow4")
    
    local output_jf = params:get("output_jf")
    local output_wsyn = params:get("output_wsyn")
    local output_wdel_ks = params:get("output_wdel_ks")
    
    local midi_out_channel = plant_id == 1 and midi_out_channel1 or midi_out_channel2
    local envelope_length = envelopes[plant_id].get_env_time()

    -- MIDI out
    if output_midi == 2 then
      midi_out_device:note_on(note_to_play, 96, midi_out_channel)
      table.insert(active_notes, note_to_play)
      -- Note off timeout
      local note_duration_param = plant_id == 1 and "plant_1_note_duration" or "plant_2_note_duration"
      clock.run(pse.midi_note_off, envelope_length, note_to_play, midi_out_channel, plant_id, #active_notes)
    end
    
    -- crow out
    if output_crow == 2 then
      local asl_generator = function(env_length)
        local envelope_data = envelopes[plant_id].get_envelope_arrays()
        local asl_envelope = ""
        for i=2, envelope_data.segments, 1
        do
          local to_shape 
          if envelope_data.curves[i] > 0 then to_shape = 'exponential'
          elseif envelope_data.curves[i] < 0 then to_shape = 'logarithmic'
          else to_shape = 'linear'
          end
          
          local to_string =  "to(" .. 
                             (envelope_data.levels[i]) .. "," ..
                             (envelope_data.times[i]-envelope_data.times[i-1]) .. 
                             "," .. to_shape .. 
                             "),"
                             asl_envelope = asl_envelope .. to_string

          if i == envelope_data.segments then
            local to_string = "to(" .. 
                              (envelope_data.levels[i]) .. "," ..
                              (env_length-envelope_data.times[i]) .. 
                              "," .. to_shape .. 
                              "),"
                              asl_envelope = asl_envelope .. to_string
          end
        end
      
        asl_envelope = "{" .. asl_envelope .. "}"
        return asl_envelope 
      end
      
      local volts = (note_to_play-60)/12
      if plant_id == 1 then
        crow.output[1].volts = volts
        local output_param = params:get("output_crow2")
        if output_param == 1 then -- envelope
          local asl_envelope = asl_generator(envelopes[1].get_env_time())
          crow.output[2].action = tostring(asl_envelope)
        elseif output_param == 2 then -- trigger
          local time = crow_trigger_2
          local level = params:get("plow1_max_level")
          local polarity = 1
          crow.output[2].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
        elseif output_param == 3 then -- gate
          local time = crow_trigger_4
          local level = params:get("plow1_max_level")
          local polarity = 1
          crow.output[2].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
        end
        crow.output[2]()
      else
        crow.output[3].volts = volts
        local output_param = params:get("output_crow4")
        if output_param == 1 then -- envelope
          local asl_envelope = asl_generator(envelopes[2].get_env_time())
          crow.output[4].action = tostring(asl_envelope)
        elseif output_param == 2 then -- trigger
          local time = crow_trigger_2
          local level = params:get("plow2_max_level")
          local polarity = 1
          crow.output[4].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
        elseif output_param == 3 then -- gate
          local time = params:get("plow2_max_time")
          local level = params:get("plow2_max_level")
          local polarity = 1
          crow.output[4].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
        end
        crow.output[4]()
      end
    end
    
    -- just friends out
    if output_jf == 2 then
      crow.ii.jf.play_note((note_to_play-60)/12,5)
    end
    
    -- wsyn out
    if output_wsyn == 2 then
      local pitch = (note_to_play-48)/12
      local velocity = params:get("wsyn_vel")
      
      if plant_id == 1 then
        params:set("wsyn_init",1)
        local voice = 1
        crow.send("ii.wsyn.play_voice(" .. voice .."," .. pitch .."," .. velocity .. ")")
      else
        local voice = 2
        crow.send("ii.wsyn.play_voice(" .. voice .."," .. pitch .."," .. velocity .. ")")
      end
    end
    
    -- wdel karplus-strong out
    -- local pitch = (note_to_play-48)/12
    local pitch = (note_to_play-48)/12
    -- print(pitch,pitch_frequency)
    if output_wdel_ks == 2 and plant_id == 1 then
      local level = params:get("plow1_max_level")
      crow.send("ii.wdel.pluck(" .. level .. ")")
      crow.send("ii.wdel.freq(" .. pitch .. ")")
      params:set("wdel_rate",0)
    elseif output_wdel_ks == 3 and plant_id == 2 then
      local level = params:get("plow2_max_level") 
      crow.send("ii.wdel.pluck(" .. level .. ")")
      crow.send("ii.wdel.freq(" .. pitch .. ")")
      params:set("wdel_rate",0)
    end
  
    -- divide 1 over beat_frequency to translate from hertz (cycles per second) into beats per second
    if envelope_length > 1/beat_frequency then
      local time_remaining = envelope_time_remaining and envelope_time_remaining - 1/beat_frequency or envelope_length - 1/beat_frequency 
      if time_remaining > 1/beat_frequency then
        clock.sleep(1/beat_frequency)
        clock.run(pse.note_on, plant_id, note_to_play, pitch_frequency, beat_frequency, time_remaining)
      end
    end
  end
  return pse
end

return plant_sounds_externals
