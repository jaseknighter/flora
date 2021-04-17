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
    local output_param = params:get("output")
    local midi_out_channel = plant_id == 1 and midi_out_channel1 or midi_out_channel2
    local envelope_length = envelopes[plant_id].get_env_time()

    -- MIDI out
    if output_param == 2 or output_param == 3 or output_param == 4 then
      midi_out_device:note_on(note_to_play, 96, midi_out_channel)
      table.insert(active_notes, note_to_play)
      -- Note off timeout
      local note_duration_param = plant_id == 1 and "plant_1_note_duration" or "plant_2_note_duration"
      clock.run(pse.midi_note_off, envelope_length, note_to_play, midi_out_channel, plant_id, #active_notes)
    end
    
    -- crow out
    if output_param == 4 then
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
      
      if plant_id == 1 then
        crow.output[1].volts = (note_to_play-60)/12
        local asl_envelope = asl_generator(envelopes[1].get_env_time())
        crow.output[2].action = tostring(asl_envelope)
        crow.output[2]()
      else
        crow.output[3].volts = (note_to_play-60)/12
        local asl_envelope = asl_generator(envelopes[2].get_env_time())
        crow.output[4].action = tostring(asl_envelope)
        crow.output[4]()
      end
    end
    
    -- just friends out
    if output_param == 4 or output_param == 5 then
      crow.ii.jf.play_note((note_to_play-60)/12,5)
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
