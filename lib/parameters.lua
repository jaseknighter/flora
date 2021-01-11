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
--[[
specs.CFHZMIN = cs.def{
                  min=0.1,
                  max=30,
                  warp='lin',
                  step=0.01,
                  default=0.1,
                  -- quantum=1,
                  wrap=false,
                }                 

specs.CFHZMAX = cs.def{
                  min=0.1,
                  max=30,
                  warp='lin',
                  step=0.01,
                  default=0.3,
                  -- quantum=1,
                  wrap=false,
                }               
]]
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

flora_params.add_params = function(plants)
  
  params:add{type = "option", id = "scale_mode", name = "scale mode",
  options = scale_names, default = 5,
  action = function() build_scale() end}
  
  params:add{type = "number", id = "root_note", name = "root note",
  min = 0, max = 127, default = root_note_default, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
  action = function() build_scale() end}

  -- params:add{type = "number", id = "scale_length", name = "scale length",
  -- min = 1, max = 72, default = scale_length, action = function() set_scale_length() build_scale() end}


  params:add_separator()
  
  params:add{type = "option", id = "crow_clock", name = "crow clock out",
    options = {"off","on"},
    action = function(value)
      if value == 2 then
        crow.output[1].action = "{to(5,0),to(5,0.05),to(0,0)}"
      end
    end}
  
  params:add{type = "option", id = "output", name = "output",
    options = options.OUTPUT,
    default = OUTPUT_DEFAULT,
    action = function(value)
      -- all_notes_off()
      if value == 4 then crow.output[2].action = "{to(5,0),to(0,0.25)}"
      elseif value == 5 then
        crow.ii.pullup(true)
        crow.ii.jf.mode(1)
      end
    end}
    
    
    
  params:add{
    type = "number", id = "midi_out_device", name = "midi out device",
    min = 1, max = 4, default = 1,
    action = function(value) midi_out_device = midi.connect(value) end
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
  
  params:add_separator()

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
    engine.set_cfScalars(table.unpack(active_cf_scalars))
  end
  
  params:add_group("cf scalars",num_cf_scalars)

  params:set_action("num_active_cf_scalars", 
    function(x) 
      engine.set_numCFScalars(x)
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
  

  local num_note_frequencies = 6
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
      -- table.insert(note_frequencies, note_frequency)
      -- table.insert(engine_frequencies, note_frequency*clock_tempo_scalar)
      table.insert(frequencies, frequency*scalar)
    end
    return frequencies
  end

  local reset_note_frequencies = function()
    
    local tempo_scalar_offset = params:get("tempo_scalar_offset")
    local clock_tempo = params:get("clock_tempo")
    local clock_tempo_scalar = clock_tempo/(60 * tempo_scalar_offset)
    local engine_frequencies = get_note_frequencies(clock_tempo_scalar)
    engine.set_frequencies(table.unpack(engine_frequencies))
    
    note_frequencies = get_note_frequencies()

  end

  params:add_group("note freqs",num_note_frequencies*3)

  params:set_action("num_note_frequencies", 
    function(x) 
      engine.set_numFrequencies(x)
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

  -- params:set_action("clock_tempo", 
  --   function()
  --      reset_note_frequencies()
  --   end
  -- )
    
  --set the reverb input engine to -10db
  params:set(13, -10)
  params:bang()
  reset_note_frequencies()
  

--[[
  params:add{
    type = "control", 
    id = "cfhzmin", 
    name = "cfhzmin",  
    controlspec = specs.CFHZMIN,
    action=function(x)
      engine.cfhzmin(x) 
    end
  }

  params:add{
    type = "control", 
    id = "cfhzmax", 
    name = "cfhzmax",  
    controlspec=specs.CFHZMAX,
    action=function(x)
      engine.cfhzmax(x) 
    end
  }
]]
  
--[[
   params:add{type = "control", id = "lsf", name = "lsf",  controlspec=cs.def{
      min=0,
      max=500,
      warp='lin',
      step=1,
      default=0,
      -- quantum=1,
      wrap=false,
    },
    action=function(x)
      engine.lsf(x) 
    end
  }
  
     params:add{type = "control", id = "ldb", name = "ldb",  controlspec=cs.def{
      min=0,
      max=500,
      warp='lin',
      step=1,
      default=100,
      -- quantum=1,
      wrap=false,
    },
    action=function(x)
      engine.ldb(x) 
    end
  }
]]

end

return flora_params
