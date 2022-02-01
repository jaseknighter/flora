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
 
  pse.note_on = function(plant_id, note_to_play, pitch_frequency, beat_frequency, envelope_time_remaining, note_source)
    local output_bandsaw = params:get("output_bandsaw")
    local output_midi = params:get("output_midi")

    local output_crow1 = params:get("output_crow1")
    local output_crow3 = params:get("output_crow3")
    local output_crow2 = params:get("output_crow2")
    local output_crow4 = params:get("output_crow4")
    
    local output_jf = params:get("output_jf")
    local jf_mode = params:get("jf_mode")
    -- local midi_thru_jf = params:get("midi_thru_jf")

    local output_wsyn = params:get("output_wsyn")
    local output_wdel_ks = params:get("output_wdel_ks")
    
    local midi_out_channel = plant_id == 1 and midi_out_channel1 or midi_out_channel2
    local envelope_length = envelopes[plant_id].get_env_time()
    
    -- MIDI out
    -- if (note_source == "flora" and output_bandsaw == 4) or output_midi > 1 then
    if (note_source == "flora" and (output_midi == 2 or output_midi == 4)) or
      (note_source == "midi" and (output_midi == 3 or output_midi == 4))  then
      local level = plant_id == 1 and params:get("plow1_max_level") or params:get("plow2_max_level")
      level = math.floor(util.linlin(0,10,0,127,level))
      midi_out_device:note_on(note_to_play, level, midi_out_channel)
      table.insert(active_notes, note_to_play)
      -- Note off timeout
      local note_duration_param = plant_id == 1 and "plant_1_note_duration" or "plant_2_note_duration"
      clock.run(pse.midi_note_off, envelope_length, note_to_play, midi_out_channel, plant_id, #active_notes)
    end
    
    -- crow out
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

    -- clock out check
    if output_crow1 == 5 then 
      crow.output[1]:execute() 
    elseif output_crow2 == 5 then 
      crow.output[2]:execute() 
    elseif output_crow3 == 5 then 
      crow.output[3]:execute() 
    elseif output_crow4 == 5 then 
      crow.output[4]:execute() 
    end

    -- note, trigger, envelope, gate check
    if (plant_id == 1 and (note_source == "flora" and (output_crow1 == 2 or output_crow1 == 4))) or
      (note_source == "midi" and (output_crow1 == 3 or output_crow1 == 4)) then
      -- if output_crow > 1 then
      local volts = (note_to_play-60)/12
      crow.output[1].volts = volts
      local output_param = params:get("output_crow2")
      if output_param == 2 then -- envelope
        local asl_envelope = asl_generator(envelopes[1].get_env_time())
        -- print("2",asl_envelope)
        crow.output[2].action = tostring(asl_envelope)
      elseif output_param == 3 then -- trigger
        local time = crow_trigger_2
        local level = params:get("plow1_max_level")
        local polarity = 1
        crow.output[2].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
      elseif output_param == 4 then -- gate
        local num_plow_controls = params:get("num_plow1_controls")
        local time = envelopes[1].get_envelope_arrays().times[num_plow_controls]
        -- local time = params:get("plow1_max_time")
        local level = params:get("plow1_max_level")
        local polarity = 1
        crow.output[2].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
      end
      if output_param > 1 then crow.output[2]() end
    end

    
    if (plant_id == 2 and (note_source == "flora" and (output_crow3 == 2 or output_crow3 == 4))) or
      (note_source == "midi" and (output_crow3 == 3 or output_crow3 == 4)) then
      -- if output_crow > 1 then
      local volts = (note_to_play-60)/12
      crow.output[3].volts = volts
      local output_param = params:get("output_crow4")
      if output_param == 2 then -- envelope
        local asl_envelope = asl_generator(envelopes[2].get_env_time())
        -- print("2",asl_envelope)
        crow.output[4].action = tostring(asl_envelope)
      elseif output_param == 3 then -- trigger
        local time = crow_trigger_4
        local level = params:get("plow2_max_level")
        local polarity = 1
        crow.output[4].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
      elseif output_param == 4 then -- gate
        -- local time = params:get("plow2_max_time")
        local num_plow_controls = params:get("num_plow2_controls")
        local time = envelopes[2].get_envelope_arrays().times[num_plow_controls]
        local level = params:get("plow2_max_level")
        local polarity = 1
        crow.output[4].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
      end
      if output_param > 1 then crow.output[4]() end
    end


    -- just friends out
    if (note_source == "flora" and (output_jf == 2 or output_jf == 4)) or
      (note_source == "midi" and (output_jf == 3 or output_jf == 4)) then
        if jf_mode == 1 then
        if plant_id == 1 then
          local level = params:get("plow1_max_level") 
          crow.ii.jf.play_voice(1,(note_to_play-60)/12,level)
        else
          local level = params:get("plow2_max_level") 
          crow.ii.jf.play_voice(2,(note_to_play-60)/12,level)
        end
      else
        local level = params:get("plow1_max_level") 
        crow.ii.jf.play_note((note_to_play-60)/12,level)
      end
    end
    
    -- wsyn out
    if (note_source == "flora" and (output_wsyn == 2 or output_wsyn == 4)) or
      (note_source == "midi" and (output_wsyn == 3 or output_wsyn == 4)) then
        local pitch = (note_to_play-48)/12
        local velocity = active_plant == 1 and params:get("plow1_max_level") or params:get("plow2_max_level") 
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
    if ((note_source == "flora" and (output_wdel_ks == 2 or output_wdel_ks == 3 or output_wdel_ks > 4)) or
      (note_source == "midi" and (output_wdel_ks > 3 ))) then
      local pitch = (note_to_play-48)/12
      local level = plant_id == 1 and params:get("plow1_max_level") or params:get("plow2_max_level") 
      crow.send("ii.wdel.pluck(" .. level .. ")")
      crow.send("ii.wdel.freq(" .. pitch .. ")")
      params:set("wdel_rate",0)
    end

    -- divide 1 over beat_frequency to translate from hertz (cycles per second) into beats per second
    if envelope_length > 1/beat_frequency then
      local time_remaining = envelope_time_remaining and envelope_time_remaining - 1/beat_frequency or envelope_length - 1/beat_frequency 
      if time_remaining > 1/beat_frequency then
        clock.sleep(1/beat_frequency)
        -- print(envelope_length,beat_frequency,time_remaining,1/beat_frequency)
        clock.run(pse.note_on, plant_id, note_to_play, pitch_frequency, beat_frequency, time_remaining, note_source)
      end
    end
  end
  return pse
end

return plant_sounds_externals
