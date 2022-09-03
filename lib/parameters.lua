-- flora params

------------------------------
-- notes and todo lsit
--
-- note: see globals.lua for global variables (e.g. options.OUTPUT, etc.)
--
-- todo list: 
--  add param for scale of random rotation when the random letter ('r') is added to the instruction set
--  figure out why midi cc's mapped to exponential controlspecs don't seem to update exponentially (e.g. rqmin & rqmax)
--  add param for scale_length (currently, adding this parameter results in error messages when scale_length is decreased)
------------------------------

flora_params = {}

local specs = {}
    
specs.AMP = cs.new(0,10,'lin',0,AMPLITUDE_DEFAULT,'')

specs.NOTE_SCALAR = cs.def{
                      min=0,
                      max=20,
                      warp='lin',
                      step=0.1,
                      default=3,
                      -- quantum=1,
                      wrap=false,
                    }
              
specs.NOTE_FREQUENCY_NUMERATOR = cs.def{
                      min=1,
                      max=NOTE_FREQUENCY_NUMERATOR_MAX,
                      warp='lin',
                      step=1,
                      default=1,
                      -- quantum=1,
                      wrap=false,
                    }

specs.NOTE_FREQUENCY_DENOMINATOR = cs.def{
                      min=1,
                      max=NOTE_FREQUENCY_DENOMINATOR_MAX,
                      warp='lin',
                      step=1,
                      default=1,
                      -- quantum=1,
                      wrap=false,
                    }

specs.NOTE_FREQUENCY_SCALAR_OFFSET = cs.def{
                      min=-0.99,
                      max=0.99,
                      warp='lin',
                      step=0.01,
                      default=0,
                      -- quantum=1,
                      wrap=false,
                    }
                    
specs.TEMPO_SCALAR_OFFSET = cs.def{
                      min=tempo_scalar_offset_min,
                      max=tempo_scalar_offset_max,
                      warp='lin',
                      step=0.1,
                      default=tempo_scalar_offset_default,
                      -- quantum=1,
                      wrap=false,
                    }
                    
specs.RQMIN = cs.def{
                min=0.1,
                max=30,
                warp='exp',
                step=0.1,
                default=1,
                -- quantum=1,
                wrap=false,
              }

specs.RQMAX = cs.def{
                min=0.1,
                max=40,
                warp='exp',
                step=0.1,
                default=5,
                -- quantum=1,
                wrap=false,
              }
              
flora_params.specs = specs

--------------------------------
-- hidden params
--------------------------------

flora_params.add_params = function(plants)
  params:add_separator("")
  params:add{type = "number", id = "page_turner", name = "page turner",
  min = 1, max = 5, default = 1, 
  action = function(x) 
    encoders_and_keys.enc(1,x-pages.index)
  end}

  params:add{type = "number", id = "active_plant_switcher", name = "active plant switcher",
  min = 1, max = 2, default = 1, 
  action = function(x) 
    -- encoders_and_keys.enc(1,x-pages.index)
    if initializing == false then
      if (x==1 and active_plant == 2) or (x==2 and active_plant == 1) then 
        plants[active_plant].switch_active_plant() 
      end
    end
  end}

  -- params:hide("page_turner")
  -- params:hide("active_plant_switcher")

--------------------------------
-- 
--------------------------------


  params:add{type = "option", id = "scale_mode", name = "scale mode",
  options = scale_names, default = 5,
  action = function() build_scale() end}
  

  params:add{type = "number", id = "root_note", name = "root note",
  min = 0, max = 127, default = root_note_default, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end}


  params:add{type = "number", id = "root_note_offset", name = "root note offset",
  min = 1, max = scale_length, default = 1 }

  params:add{type = "trigger", id = "set_root", name = "set root",
  action = function() build_scale() end} 


  params:add{type = "number", id = "note_offset1", name = "note offset 1",
  min = -scale_length, max = scale_length, default = 0}

  params:add{type = "number", id = "note_offset2", name = "note offset 2",
  min = -scale_length, max = scale_length, default = 0}

  function params.set_note_offsets()
    note_offset1 = params:get("note_offset1")
    note_offset2 = params:get("note_offset2")
  end

  params:add{type = "trigger", id = "set_note_offset", name = "set note offset",
  action = function() params.set_note_offsets() end} 

  params:add{type = "trigger", id = "reset_offsets", name = "reset offsets",
  action = function() 
    params:set("root_note_offset",1)
    params:set("note_offset1",0)
    params:set("note_offset2",0)
    params.set_note_offsets() 
    build_scale()
  end} 

--------------------------------
-- inputs/outputs/midi params
--------------------------------
  params:add_separator("inputs/outputs")
  -- params:add_group("inputs/outputs",17+14)
  params:add{type = "option", id = "output_bandsaw", name = "bandsaw (eng)",
  options = {"off","plants", "midi", "plants + midi"},
  default = 2,
}

-- midi

  params:add_group("midi",13)
  
  --[[
  params:add{type = "option", id = "midi_engine_control", name = "midi engine control",
    options = {"off","on"},
    default = 2,
    -- action = function(value)
    -- end
  }
  ]]

  local midi_devices = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}

  function params.get_midi_devices()
    local devices = {}
    for i=1,#midi.vports,1
    do
      table.insert(devices, i .. ". " .. midi.vports[i].name)
    end
    midi_devices = devices
    local midi_in = params:lookup_param("midi_device")
    midi_in.options = midi_devices
    local midi_out = params:lookup_param("midi_out_device")
    midi_out.options = midi_devices
    
    -- tab.print(midi_devices)
  end


  params:add_separator("midi in")
  
  midi_in_device = {}

  params:add{
    type = "option", id = "midi_device", name = "device", options = midi_devices, 
    min = 1, max = 16, default = 1, 
    action = function(value)
      midi_in_device.event = nil
      midi_in_device = midi.connect(value)
      midi_in_device.event = midi_event
    end
  }
  
  params:add{type = "option", id = "use_midi_velocity", name = "use midi velocity",
    options = {"no","yes"},
    default = 1,
  }

  params:add{
    type = "number", id = "plant1_cc_channel", name = "plant 1:midi in channel",
    min = 1, max = 16, default = plant1_cc_channel,
    action = function(value)
      -- all_notes_off()
      midi_in_command1 = value + 143
    end
  }
    
  params:add{type = "number", id = "plant2_cc_channel", name = "plant 2:midi in channel",
    min = 1, max = 16, default = plant2_cc_channel,
    action = function(value)
      -- all_notes_off()
      midi_in_command2 = value + 143
    end
  }
  
  params:add{
    type = "number", id = "plow1_cc_channel", name = "plow 1:midi cc channel",
    min = 1, max = 16, default = plow1_cc_channel,
    action = function(value)
      -- all_notes_off()
      plow1_cc_channel = value
    end
  }

  params:add{
    type = "number", id = "plow2_cc_channel", name = "plow 2:midi cc channel",
    min = 1, max = 16, default = plow2_cc_channel,
    action = function(value)
      -- all_notes_off()
      plow2_cc_channel = value
    end
  }
  
  params:add{
    type = "number", id = "water_cc_channel", name = "water:midi cc channel",
    min = 1, max = 16, default = water_cc_channel,
    action = function(value)
      -- all_notes_off()
      water_cc_channel = value
    end
  }

  params:add_separator("midi out")

  params:add{type = "option", id = "output_midi", name = "midi out",
    options = {"off","plants", "midi", "plants + midi"},
    default = 1,
  }
  
  params:add{
    type = "option", id = "midi_out_device", name = "device", options = midi_devices,
    min = 1, max = 16, default = 1,
    action = function(value) 
      midi_out_device = midi.connect(value) 
    end
  }
  
  params:add{
    type = "number", id = "midi_out_channel1", name = "plant 1:midi out channel",
    min = 1, max = 16, default = midi_out_channel1,
    action = function(value)
      -- all_notes_off()
      midi_out_channel1 = value
    end
  }
    
  params:add{type = "number", id = "midi_out_channel2", name = "plant 2:midi out channel",
    min = 1, max = 16, default = midi_out_channel2,
    action = function(value)
      -- all_notes_off()
      midi_out_channel2 = value
    end
  }

  params.get_midi_devices()

-- crow
  params:add_group("crow",5)

  params:add{type = "option", id = "input_crow2", name = "process crow in2",
    options = {"off","on"},
    default = INPUT_CROW2_DEFAULT,
    action = function(value)    
    end
  }

  params:add{type = "option", id = "output_crow1", name = "crow out1 mode",
    -- options = {"off","on"},
    options = {"off","plants", "midi", "plants + midi", "clock", "1lfo", "2lfo"},
    default = 6,
    action = function(value)
      if value == 5 then 
        crow.output[1].action = "{to(5,0),to(5,0.05),to(0,0)}"
      end
    end
  }

  params:add{type = "option", id = "output_crow2", name = "crow out2 mode",
    options = {"off","envelope","trigger","gate","clock", "1lfo", "2lfo"},
    default = 2,
    action = function(value)
      if value == 3 then 
        crow.output[2].action = "{to(5,0),to(0,0.25)}"
      elseif value == 5 then
        crow.output[2].action = "{to(5,0),to(5,0.05),to(0,0)}"
      end
    end
  }

  params:add{type = "option", id = "output_crow3", name = "crow out3 mode",
    -- options = {"off","on"},
    options = {"off","plants", "midi", "plants + midi", "clock", "1lfo", "2lfo"},
    default = 2,
    action = function(value)
      if value == 5 then 
        crow.output[3].action = "{to(5,0),to(5,0.05),to(0,0)}"
      end
    end
  }

  params:add{type = "option", id = "output_crow4", name = "crow out4 mode",
    options = {"off","envelope","trigger","gate", "clock", "1lfo", "2lfo"},
    default = 2,
    action = function(value)
      if value == 3 then 
        crow.output[4].action = "{to(5,0),to(0,0.25)}"
      elseif value == 5 then 
        crow.output[4].action = "{to(5,0),to(5,0.05),to(0,0)}"
      end
    end
  }

-- just friends
params:add_group("just friends",2)
  params:add{type = "option", id = "output_jf", name = "just friends",
    options = {"off","plants", "midi", "plants + midi"},
    default = 2,
    action = function(value)
      if value > 1 then 
        -- crow.output[2].action = "{to(5,0),to(0,0.25)}"
        crow.ii.pullup(true)
        crow.ii.jf.mode(1)
      else
        crow.ii.jf.mode(0)
        -- crow.ii.pullup(false)
      end
    end
  }

  params:add{type = "option", id = "jf_mode", name = "just friends mode",
    options = {"mono","poly"},
    default = 2,
    action = function(value)
      -- if value == 2 then 
      --   -- crow.output[2].action = "{to(5,0),to(0,0.25)}"
      --   crow.ii.pullup(true)
      --   crow.ii.jf.mode(1)
      -- else 
      --   crow.ii.jf.mode(0)
      --   -- crow.ii.pullup(false)
      -- end
    end
  }


  params:add_group("w/syn",14)
  w_slash.wsyn_add_params()
  -- w_slash.wsyn_v2_add_params()

  params:add_group("w/del",16)
  w_slash.wdel_add_params()

  params:add_group("w/tape",17)
  w_slash.wtape_add_params()

  lfo.setup_params()

  params:add_separator("plant/plow/water")
  --------------------------------
  -- plant parameters
  --------------------------------
  params:add_group("plants",6)
  -- params:add_separator("plant")

  params:add{
    type = "number", id = "plant1_instructions", name = "plant 1: instructions", min=1, max = garden.get_num_plants(), default = INITIAL_PLANT_INSTRUCTIONS_1,
    action = function(value)
      if initializing == false then
        plants[1].set_instructions(value - plants[1].current_instruction)
      end
    end
  }

  params:add{
    type = "number", id = "plant2_instructions", name = "plant 2: instructions", min=1, max=garden.get_num_plants(), default = INITIAL_PLANT_INSTRUCTIONS_2,
    action = function(value)
      if initializing == false then
        plants[2].set_instructions(value - plants[2].current_instruction)
      end
    end
  }
  params:add{
    type = "number", id = "plant1_angle", default=90, min=-360, max=360, step=1, name = "plant 1: angle",
    action = function(value)
      if initializing == false and value ~= value-plants[1].get_angle() then
        plants[1].set_angle(value-plants[1].get_angle(), true)
        -- plants[1].set_angle(value)
      end
    end
  }

  params:add{
    type = "number", id = "plant2_angle", default=90, min=-360, max=360, step=1, name = "plant 2: angle",
    action = function(value)
      if initializing == false and value ~= value-plants[2].get_angle() then
        -- plants[2].set_angle(value-plants[2].get_angle())
        plants[2].set_angle(value-plants[2].get_angle(), true)
      end
    end
  }

  params:add{
    type = "number", id = "plant1_generation", name = "plant 1: generation", min=1, max=10, default=1,
    action = function(value)
      -- print(value , plants[1].current_instruction)
      if initializing == false and value ~= value-plants[1].current_instruction then
        -- clock.run(plants[1].change_instructions,plants[1].current_instruction, value)
        plants[1].change_instructions(plants[1].current_instruction, value)
      end
    end
  }

  params:add{
    type = "number", id = "plant2_generation", name = "plant 2: generation", min=1, max=10, default=1,
    action = function(value)
      if initializing == false and value ~= value-plants[2].current_instruction then
        -- clock.run(plants[2].change_instructions,plants[2].current_instruction, value)
        plants[2].change_instructions(plants[2].current_instruction, value)
      end
    end
  }

  --------------------------------
  -- plow (envelope) parameters
  --------------------------------
  params:add_group("plows (envs)",2+4+(2*(MAX_ENVELOPE_NODES*3))+19)
  params:add_separator("env controls")
  -- params:add_separator("plow")
  
  get_node_time = function(env_id, node_id)
    local node_time = envelopes[env_id].get_envelope_arrays().times[node_id]
    return node_time 
  end

  get_node_level = function(env_id, node_id)
    return envelopes[env_id].get_envelope_arrays().levels[node_id]
  end

  get_node_curve = function(env_id, node_id)
    return envelopes[env_id].get_envelope_arrays().curves[node_id]
  end

  reset_plow_control_params = function(plow_id, delay)
    -- if delay == true then clock.sleep(0.1) end
    local env_nodes = envelopes[plow_id].graph_nodes
    -- local plow_times = plow_id == 1 and plow1_times or plow2_times
    for i=1,MAX_ENVELOPE_NODES,1
    do
      local param_id_name, param_name, get_control_value_fn, min_val, max_val

      -- update time
      param_id_name = "plow".. plow_id.."_time" .. i
      param_name = "plow".. plow_id.."-control" .. i .. "-time"
      get_control_value_fn = get_node_time
      local control_value = get_control_value_fn(plow_id,i) or 1
      local param = params:lookup_param(param_id_name)
      local prev_val = (env_nodes[i-1] and env_nodes[i-1].time) or 0
      local next_val = env_nodes[i+1] and env_nodes[i+1].time or envelopes[plow_id].env_time_max
      local controlspec = cs.new(prev_val,next_val,'lin',0,control_value,'')
      if env_nodes[i] then
        param.controlspec = controlspec
        if env_nodes[i].time ~= params:get(param.id)  then 
          params:set(param.id, control_value) 
        end
      end

      -- update level 
      param_id_name = "plow".. plow_id.."_level" .. i
      param_name = "plow".. plow_id.."-control" .. i .. "-level"
      get_control_value_fn = get_node_level
      local control_value = get_control_value_fn(plow_id,i) or 1
      local param = params:lookup_param(param_id_name)
      local max_val = envelopes[plow_id].env_level_max
      local controlspec = cs.new(0,max_val,'lin',0,control_value,'')
      if env_nodes[i] then
        param.controlspec = controlspec
        if (i == 1 or i == #envelopes[plow_id].graph_nodes) and param:get() ~= 0 then
          params:set(param.id, 0) 
        elseif env_nodes[i].level ~= params:get(param.id)  then
          params:set(param.id, control_value) 
        end
      end
      
      -- update curve 
      param_id_name = "plow".. plow_id.."_curve" .. i
      param_name = "plow".. plow_id.."-control" .. i .. "-curve"
      get_control_value_fn = get_node_curve
      local control_value = get_control_value_fn(plow_id,i) or 1
      local param = params:lookup_param(param_id_name)
      if env_nodes[i] then
        if env_nodes[i].curve ~= params:get(param.id)  then
          params:set(param.id, control_value) 
        end
      end
    end

    local time_param = params:lookup_param("time_modulation"..plow_id)
    time_param.max = params:get("plow"..plow_id.."_max_time") * 0.1
    local level_param = params:lookup_param("level_modulation"..plow_id)
    level_param.max = params:get("plow"..plow_id.."_max_level") * 0.1

    update_plow_controls(plow_id, x)
  end  

  update_plow_controls = function (plow_id, x)
    local num_plow_controls = plow_id == 1 and envelopes[1].get_envelope_arrays().segments or envelopes[2].get_envelope_arrays().segments
    local plow_times = plow_id == 1 and plow1_times or plow2_times
    local plow_levels = plow_id == 1 and plow1_levels or plow2_levels
    local plow_curves = plow_id == 1 and plow1_curves or plow2_curves
    for i=1,MAX_ENVELOPE_NODES,1
    do
      if i <= num_plow_controls then
        params:show(plow1_times[i])
        if i > 1 then
          if i~=num_plow_controls then 
            params:show(plow_levels[i]) 
          else 
            params:hide(plow_levels[i]) 
          end
          params:show(plow_curves[i])
        end 
      else
        params:hide(plow_times[i])
        params:hide(plow_levels[i])
        params:hide(plow_curves[i])
      end
    end
  end

  params:add_number("num_plow1_controls", "num plow1 controls", 3, MAX_ENVELOPE_NODES, 5)
  -- params:hide("num_plow1_controls")

  params:set_action("num_plow1_controls", 
    function(x)
      if initializing == false then
        add_remove_nodes(1, x)
      end
    end
  )

  params:add_number("num_plow2_controls", "num plow2 controls", 3, MAX_ENVELOPE_NODES, 5)
  -- params:hide("num_plow2_controls")

  params:set_action("num_plow2_controls", 
    function(x)
      if initializing == false then
        add_remove_nodes(2, x)
      end
    end
  )

  add_remove_nodes = function(plow_id, num_nodes)
    if num_nodes < envelopes[plow_id].get_num_nodes() then
      local num_controls_to_remove = #envelopes[plow_id].graph_nodes - num_nodes
      for i=1,num_controls_to_remove,1
      do
        if envelopes[plow_id].active_node < 2 or envelopes[plow_id].active_node >= #envelopes[plow_id].graph_nodes then 
          envelopes[plow_id].set_active_node(2)
        end
        envelopes[plow_id].remove_node()
        reset_plow_control_params(plow_id)
      end
    else
      local num_controls_to_add = num_nodes - #envelopes[plow_id].graph_nodes
      for i=1,num_controls_to_add,1
      do
        if envelopes[plow_id].active_node < 1 or envelopes[plow_id].active_node >= #envelopes[plow_id].graph_nodes then 
          envelopes[plow_id].set_active_node(1)
        end
        envelopes[plow_id].add_node()
        reset_plow_control_params(plow_id)
      end
    end
    
    local num_plow_controls = plow_id == 1 and "num_plow1_controls" or "num_plow2_controls"
    local num_env_nodes = #envelopes[plow_id].graph_nodes
    params:set(num_plow_controls,num_env_nodes)
  end

  specs.PLOW_LEVEL = cs.new(0.0,MAX_AMPLITUDE,'lin',0,AMPLITUDE_DEFAULT,'')
  specs.PLOW_TIME = cs.new(0.0,MAX_ENV_LENGTH,'lin',0,ENV_TIME_MAX,'')

  local init_plow_controls = function(plow_id)
    
    -- set the values of the individual envelope nodes 
    local env = plow_id == 1 and envelopes[1].graph_nodes or envelopes[2].graph_nodes
    local num_plow1_controls = envelopes[1].get_envelope_arrays().segments
    local num_plow2_controls = envelopes[2].get_envelope_arrays().segments
    local num_plow_controls = plow_id == 1 and num_plow1_controls or num_plow2_controls
    local plow_times = plow_id == 1 and plow1_times or plow2_times
    local plow_levels = plow_id == 1 and plow1_levels or plow2_levels
    local plow_curves = plow_id == 1 and plow1_curves or plow2_curves
    
    
    -- set the envelope's overall max level
    params:add{
      type="control",
      id = plow_id == 1 and "plow1_max_level" or "plow2_max_level",
      name = plow_id == 1 and "plow 1 max level" or "plow 2 max level",
      controlspec=specs.PLOW_LEVEL,
      action=function(x) 
        if initializing == false then envelopes[plow_id].set_env_level(x) end
      end
    }
  
    -- set the envelope's overall max time
    params:add{
      type="control",
      id = plow_id == 1 and "plow1_max_time" or "plow2_max_time",
      name = plow_id == 1 and "plow 1 max time" or "plow 2 max time",
      controlspec=specs.PLOW_TIME,
      action=function(x) 
        if initializing == false then envelopes[plow_id].set_env_time(x) end
      end
    }  
    for i=1, MAX_ENVELOPE_NODES, 1
    do
      for j=1, 3, 1
      do
        local param_id_name, param_name, plow_control_type, get_control_value_fn, min_val, max_val
        if j == 1 then
          plow_control_type = "time"
          param_id_name = "plow".. plow_id.."_time" .. i
          param_name = "plow ".. plow_id.." control " .. i .. " time"
          get_control_value_fn = get_node_time
          min_val = 0
          max_val = MAX_ENV_LENGTH
        elseif j == 2 then
          plow_control_type = "level"
          param_id_name = "plow".. plow_id.."_level" .. i
          param_name = "plow ".. plow_id.." control " .. i .. " level"
          get_control_value_fn = get_node_level
          min_val = 0.0
          max_val = MAX_AMPLITUDE
        else 
          plow_control_type = "curve"
          param_id_name = "plow".. plow_id.."_curve" .. i
          param_name = "plow ".. plow_id.." control " .. i .. " curve"
          get_control_value_fn = get_node_curve
          min_val = CURVE_MIN
          max_val = CURVE_MAX
        end        
        
        params:add{
          type = "control", 
          id = param_id_name,
          name = param_name,
          controlspec = cs.new(min_val,max_val,'lin',0,control_value,''),
          action=function(x) 
            local control_value = get_control_value_fn(plow_id,i) or 1
            local param = params:lookup_param(param_id_name)
            local new_val = x
            local env_nodes = envelopes[plow_id].graph_nodes
            if plow_control_type == "time" and initializing == false then
              local prev_val = (env_nodes[i-1] and env_nodes[i-1][plow_control_type]) or 0
              local next_val = (env_nodes[i+1] and env_nodes[i+1][plow_control_type]) or envelopes[plow_id].get_env_time()
              new_val = util.clamp(new_val, prev_val, next_val)
              if env_nodes[i] and x ~= control_value then
                env_nodes[i][plow_control_type] = new_val
                param.controlspec.minval = prev_val
                param.controlspec.maxval = next_val
              end
            elseif initializing == false then
              if plow_control_type == "level" and env_nodes[i] then
                if (i ~= 1 and i ~= #envelopes[plow_id].graph_nodes) then
                  env_nodes[i][plow_control_type] = new_val
                end
              elseif env_nodes[i] then
                env_nodes[i][plow_control_type] = new_val
              end
            end
            envelopes[plow_id].graph:edit_graph(env_nodes)
            local num_plow_controls = plow_id == 1 and "num_plow1_controls" or "num_plow2_controls"
            local num_env_nodes = #envelopes[plow_id].graph_nodes
            params:set(num_plow_controls,num_env_nodes)
          end

        }
      end
    end
    
    
    for i=num_plow_controls+1,MAX_ENVELOPE_NODES,1
    do
      params:hide(plow_times[i])
      params:hide(plow_levels[i])
      params:hide(plow_curves[i])
    end
    params:hide(plow_levels[1])
    params:hide(plow_curves[1])
    params:hide(plow_levels[num_plow_controls])
  end

  init_plow_controls(1)
  init_plow_controls(2)

  params:add_separator("env mod params")
  params:add{type = "option", id = "show_env_mod_params", name = "show env mod params",
  options = {"off","on"}, default = 1,
  action = function(x)
    if x == 1 then show_env_mod_params = false else show_env_mod_params = true end
  end}

  params:add_taper("randomize_env_probability1", "1: env mod probability", 0, 100, 100, 0, "%")
  params:add_taper("time_probability1", "1: time mod probability", 0, 100, 0, 0, "%")
  params:add_taper("level_probability1", "1: level mod probability", 0, 100, 0, 0, "%")
  params:add_taper("curve_probability1", "1: curve mod probability", 0, 100, 0, 0, "%")
  params:add_taper("time_modulation1", "1: time modulation", 0, params:get("plow1_max_time"), 0, 0, "")
  params:add_taper("level_modulation1", "1: level modulation", 0, params:get("plow1_max_level"), 0, 0, "")
  params:add_taper("curve_modulation1", "1: curve modulation", 0, 5, 0, 0, "")

  params:add_number("env_nav_active_control1", "1: env mod nav", 1, #env_mod_param_labels)
  params:set_action("env_nav_active_control1", function(x) 
    if initializing == false then
      envelopes[1].set_env_nav_active_control(x-envelopes[1].env_nav_active_control) 
    end
  end )

  params:add_taper("randomize_env_probability2", "2: env probability", 0, 100, 100, 0, "%")
  params:add_taper("time_probability2", "2: time probability", 0, 100, 0, 0, "%")
  params:add_taper("level_probability2", "2: level probability", 0, 100, 0, 0, "%")
  params:add_taper("curve_probability2", "2: curve probability", 0, 100, 0, 0, "%")
  params:add_taper("time_modulation2", "2: time modulation", 0, params:get("plow1_max_time") * 0.1, 0, 0, "")
  params:add_taper("level_modulation2", "2: level modulation", 0, params:get("plow1_max_level"), 0, 0, "")
  params:add_taper("curve_modulation2", "2: curve modulation", 0, 5, 0, 0, "")
  
  params:add_number("env_nav_active_control2", "2: env mod nav", 1, #env_mod_param_labels)
  params:set_action("env_nav_active_control2", function(x) 
    if initializing == false then
      envelopes[2].set_env_nav_active_control(x-envelopes[2].env_nav_active_control) 
    end  
  end )

  
  --------------------------------
  -- water parameters
  --------------------------------
  local num_note_frequencies = 6

  local reset_note_frequencies = function()
  local tempo_scalar_offset = params:get("tempo_scalar_offset")
  local clock_tempo = params:get("clock_tempo")
  local clock_tempo_scalar = clock_tempo/(60 * tempo_scalar_offset)
  tempo_offset_note_frequencies = get_note_frequencies(clock_tempo_scalar)
  note_frequencies = get_note_frequencies()
  -- clock.run(set_dirty)
  set_dirty()
end

  params:add_group("water",4+num_cf_scalars_max+3+(3*num_note_frequencies)+2)
  
  params:add{
    type = "control",
    id = "tempo_scalar_offset", 
    name = "tempo scalar offset", 
    controlspec = specs.TEMPO_SCALAR_OFFSET
  }
  
  params:set_action("tempo_scalar_offset", 
    function()
      reset_note_frequencies()
    end
  )

  -- overwrite clock tempo action
  params:set_action("clock_tempo",
    function(bpm)
      local source = params:string("clock_source")
      if source == "internal" then clock.internal.set_tempo(bpm)
      elseif source == "link" then clock.link.set_tempo(bpm) end
      norns.state.clock.tempo = bpm
      reset_note_frequencies()
    end)

  params:add{
    type="control",
    id="amp",
    controlspec=specs.AMP,
    action=function(x) engine.amp(x) end
  }
  
  params:add{
    type = "control", 
    id = "rqmin", 
    name = "rqmin (/1000)",  
    controlspec = specs.RQMIN,
    action=function(x)
      engine.rqmin(x/1000) 
    end
  }

  params:add{
    type = "control", 
    id = "rqmax", 
    name = "rqmax (/1000)",  
    controlspec = specs.RQMAX,
    action=function(x)
      engine.rqmax(x/1000) 
    end
  }


  params:add{
    type = "control", 
    id = "note_scalar", 
    name = "note scalar",  
    controlspec = specs.NOTE_SCALAR, 
    action=function(x)
      for i=1, #plants, 1
      do
        plants[i].sounds.set_note_scalar(x)
      end
    end
  }
  
  
  local active_cf_scalars = {}
  params:add_number("num_active_cf_scalars", "num cf scalars", 1, num_cf_scalars_max, num_cf_scalars_default)

  local reset_cf_scalars = function()
    active_cf_scalars = {}
    local num_active_cf_scalars = params:get("num_active_cf_scalars")
    for i=1, num_active_cf_scalars, 1
    do
      local cf_scalar = params:get(cf_scalars[i])
      table.insert(active_cf_scalars,cf_scalar)
    end
  end
  
  params:set_action("num_active_cf_scalars", 
    function(x) 
      reset_cf_scalars()
      local num_active_cf_scalars = params:get("num_active_cf_scalars")
      for i=num_cf_scalars,1,-1 
      do
        if i > num_active_cf_scalars then
          params:hide(cf_scalars[i])
        else
          params:show(cf_scalars[i])
        end
      end
    end
  )
  
  
  for i=1, num_cf_scalars, 1
  do
    params:add{
      type = "option", 
      id = cf_scalars[i], 
      name = "cf scalar" .. i,
      options = options.SCALARS,
      default = 2
    }
    
    params:set_action(cf_scalars[i], 
      function(x) 
        reset_cf_scalars()       
      end
    )

    params:hide(cf_scalars[i])
  end
  
--------------------------------
  

  params:add{
    type = "option", 
    id = "plant_1_note_duration", 
    name = "plant 1: note duration",
    options = options.NOTE_DURATIONS,
    default = NOTE_DURATION_INDEX_DEFAULT_1,
    action=function(x)
      plants[1].sounds.set_note_duration(options.NOTE_DURATIONS[x])
    end
  } 
  
  params:add{
    type = "option", 
    id = "plant_2_note_duration", 
    name = "plant 2: note duration",
    options = options.NOTE_DURATIONS,
    default = NOTE_DURATION_INDEX_DEFAULT_2,
    action = function(x) 
      plants[2].sounds.set_note_duration(options.NOTE_DURATIONS[x])
    end
  }
  
  params:add_number("num_note_frequencies", "# note freqs", 1, num_note_frequencies, 1)

  function get_note_frequencies(scalar)
    local scalar = scalar or 1
    local frequencies = {}
    local num_active_note_frequencies = params:get("num_note_frequencies")
    for i=1, num_active_note_frequencies, 1
    do
      local frequency_n = params:get(note_frequency_numerators[i])
      local frequency_d = params:get(note_frequency_denominators[i])
      local frequency_o = params:get(note_frequency_offsets[i])
      local frequency = frequency_n/(frequency_d+frequency_o)
      table.insert(frequencies, frequency*scalar)
    end
    return frequencies
  end

  params:set_action("num_note_frequencies", 
    function(x) 
      reset_note_frequencies()
      
      local num_active_note_frequencies = params:get("num_note_frequencies")
      for i=num_note_frequencies,1,-1
      do
        if i > num_active_note_frequencies then
          params:hide(note_frequency_numerators[i])
          params:hide(note_frequency_denominators[i])
          params:hide(note_frequency_offsets[i])
          
        else
          params:show(note_frequency_numerators[i])        
          params:show(note_frequency_denominators[i])
          params:show(note_frequency_offsets[i])        
        end
      end
    end
  )
  
  
  for i=1, num_note_frequencies, 1
  do
    params:add{
        type = "control", 
        id = note_frequency_numerators[i], 
        name = "note freq"..i..": numerator",  
        controlspec = specs.NOTE_FREQUENCY_NUMERATOR, 
        action=function(x) 
          reset_note_frequencies()       
        end
     }

    params:add{
        type = "control", 
        id = note_frequency_denominators[i], 
        name = "note freq"..i..": denominator",  
        controlspec = specs.NOTE_FREQUENCY_DENOMINATOR, 
        action=function(x) 
          reset_note_frequencies()       
        end
     }

    params:add{
        type = "control", 
        id = note_frequency_offsets[i], 
        name = "note freq"..i..": offset",  
        controlspec = specs.NOTE_FREQUENCY_SCALAR_OFFSET, 
        action=function(x) 
          reset_note_frequencies()       
        end
     }
    
    params:hide(note_frequency_numerators[i])
    params:hide(note_frequency_denominators[i])
    params:hide(note_frequency_offsets[i])
  end

  params:add{type = "trigger", id = "basic_sequence", name = "load basic sequence",
    action = function()
      -- set minimal plant instructions
      params:set("plant1_instructions",12)
      params:set("plant2_instructions",12)
      -- set minimal envelopes
      params:set("num_plow1_controls",3)
      params:set("plow1_time1",0)
      params:set("plow1_time2",0)
      params:set("plow1_level2",4)
      params:set("plow1_curve3",-10)
      params:set("plow1_max_time",2)
      params:set("plow1_max_level",5)
      params:set("num_plow2_controls",3)
      params:set("plow2_time1",0)
      params:set("plow2_time2",0)
      params:set("plow2_level2",4)
      params:set("plow2_curve3",-10)
      params:set("plow2_max_time",2)
      params:set("plow2_max_level",5)
      -- set tempo/note scalar params
      params:set("note_scalar",1)
      params:set("tempo_scalar_offset",1)
    end
  }
  --------------------------------
  -- wow and flutter parameters
  --------------------------------
  params:add_separator("")

  params:add_group("wow and flutter",7)
  
  specs.WOBBLE_AMP = cs.def{
                      min=0,
                      max=0.20,
                      warp='lin',
                      step=0.01,
                      default=WOBBLE_DEFAULT,
                      wrap=false,
                    }

  specs.FLUTTER_AMP = cs.def{
                      min=0,
                      max=0.20,
                      warp='lin',
                      step=0.01,
                      default=FLUTTER_DEFAULT,
                      wrap=false,
                    }

  params:add{type = "option", id = "enable_wow_flutter", name = "enable wow and flutter",
    options = {"off","on"}, default=2,
    action = function(value)
      if value == 1 then
        engine.wobble_amp(0) 
        engine.flutter_amp(0) 
      else
        engine.wobble_amp(params:get("wobble_amp"))
        engine.wobble_amp(params:get("flutter_amp")) 
      end
    end
  }

  params:add{
    type = "number", id = "wobble_rpm", name = "wobble rpm", min=1, max=1000, default=33,
    action=function(x)
      engine.wobble_rpm(x) 
    end
  }

  params:add{
    type = "control", id = "wobble_amp", name = "wobble amp", controlspec = specs.WOBBLE_AMP,
    action=function(x)
      if params:get("enable_wow_flutter") == 1 then
        engine.wobble_amp(0) 
      else
        engine.wobble_amp(x) 
      end
    end
  }

  params:add{
    type = "number", id = "wobble_exp", name = "wobble exp", min=1, max=1000, default=39,
    action=function(x)
      engine.wobble_exp(x) 
    end
  }
  
  params:add{
    type = "control", id = "flutter_amp", name = "flutter amp", controlspec = specs.FLUTTER_AMP,
    action=function(x)
      if params:get("enable_wow_flutter") == 1 then
        engine.flutter_amp(0) 
      else
        engine.flutter_amp(x) 
      end
    end
  }

  params:add{
    type = "number", id = "flutter_fixedfreq", name = "flutter fixed freq", min=1, max=100, default=6,
    action=function(x)
      engine.flutter_fixedfreq(x) 
    end
  }

  params:add{
    type = "number", id = "flutter_variationfreq", name = "flutter variation freq", min=1, max=1000, default=6,
    action=function(x)
      engine.flutter_variationfreq(x) 
    end
  }

  --------------------------------
  -- pitchshift parameters
  --------------------------------
  params:add_group("pitchshift",6)

  params:add{
    type = "control", id = "effect_pitchshift", name = "pitchshift", controlspec = controlspec.AMP,
    action=function(x)
      engine.effect_pitchshift(x) 
    end
  }

  -- WORK IN PROGRESS
  -- params:add{
  --   type = "option", id = "quantize_pitchshift", name = "quantize pitchshift", 
  --   options = {"off","on"},default=2,
  --   action=function(x)
  --     engine.quantize_pitchshift(x-1) 
  --   end
  -- }

  params:add{
    type = "taper", id = "grain_size", name = "grain size", min=0.01, max=1, default = 0.1,
    action=function(x)
      engine.grain_size(x) 
    end
  }
  
  params:add{
    type = "taper", id = "time_dispersion", name = "time dispersion", min=0.001, max=0.2, default = 0.01,
    action=function(x)
      engine.time_dispersion(x) 
    end
  }

  params:add{
    type = "number", id = "pitchshift_note1", name = "pitchshift note 1", min=-24, max=24, default=1,
    action=function(x)
      engine.pitchshift_note1(x) 
    end
  }

  params:add{
    type = "number", id = "pitchshift_note2", name = "pitchshift note 2", min=-24, max=24, default=3,
    action=function(x)
      engine.pitchshift_note2(x) 
    end
  }

  params:add{
    type = "number", id = "pitchshift_note3", name = "pitchshift note 3", min=-24, max=24, default=5,
    action=function(x)
      engine.pitchshift_note3(x) 
    end
  }

  --set the reverb input engine to -10db
  params:set(13, -10)
  
  params:bang()
  params:set("wsyn_init",1)

  reset_note_frequencies()

end

return flora_params
