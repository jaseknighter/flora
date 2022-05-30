w_slash = {}

function w_slash.wdel_add_params()
  w_slash.DEL_TIME_SHORT = cs.def{
    min=0,
    max=100,
    warp='lin',
    step=1,
    default=0,
    -- quantum=1,
    wrap=false,
  }

  w_slash.DEL_TIME_LONG = cs.def{
    min=0.1,
    max=10,
    warp='lin',
    step=0.1,
    default=0.4999084,
    -- default=13.90283,
    -- quantum=1,
    wrap=false,
  }

  w_slash.DEL_FILTER = cs.def{
    min=16,
    max=16000,
    warp='exp',
    step=1,
    default=12000,
    -- quantum=1,
    wrap=false,
  }

  function start_ks()
    clock.sleep(0.001)
    params:set("wdel_time_short",0)
    crow.ii.wdel.time(0)
    params:set("wdel_feedback",99)
    params:set("wdel_mix",10)
  end

  params:add{type = "option", id = "output_wdel_ks", name = "Karplus-Strong",
    options = {"off","plant 1","plant 2","midi", "p1 + midi", "p2 + midi", },
    default = 1,
    action = function(value)
      if value > 1 then
        local val = value == 4 and 2
        params:set("wdel_filter",12000)
        params:set("wdel_frequency",0)
        params:set("wdel_rate",0)
        params:set("wdel_mix",0)
        pset_wdel_ks = val
        clock.run(start_ks)
      end
    end
  }

  params:add {
    type = "control",
    id = "wdel_mix",
    name = "Mix (dry->wet)",
    controlspec = controlspec.new(0, 100, "lin", 0, 50,"%"),
    action = function(val) 
      local mix_val = util.linlin (0, 100, -5, 5, val)
      crow.send("ii.wdel.mix(" .. mix_val .. ")") 
      pset_wdel_mix = val
      params:set("wdel_freeze",1)
    end
  }

  params:add {
    type = "number",
    id = "wdel_time_short",
    name = "Time: short (0-100ms)",
    controlspec = w_slash.DEL_TIME_SHORT,
    action = function(val) 
      if val < 0 then params:set("wdel_time_short",0) end
      crow.send("ii.wdel.time(" .. val/10000 .. ")") 
      pset_wdel_time_short = val
      params:set("wdel_freeze",1)
    end
  }

  params:add {
    type = "control",
    id = "wdel_time_long",
    name = "Time: long (0.1-10s)",
    controlspec = w_slash.DEL_TIME_LONG,
    action = function(val) 
      crow.send("ii.wdel.time(" .. val .. ")") 
      pset_wdel_time_long = val
      params:set("wdel_freeze",1)
    end
  }

  params:add {
    type = "control",
    id = "wdel_feedback",
    name = "Feedback",
    
    controlspec = controlspec.new(0, 100, "lin", 0, 30,"%"),
    action = function(val) 
      local feedback_val = util.linlin (0, 100, -5, 5, val)
      crow.send("ii.wdel.feedback(" .. feedback_val .. ")") 
      pset_wdel_feedback = val
      params:set("wdel_freeze",1)
    end
  }

  params:add {
    type = "control",
    id = "wdel_filter",
    name = "Fdbk Filter",
    controlspec = w_slash.DEL_FILTER,
    action = function(val)       
      local filter_val = util.explin (w_slash.DEL_FILTER.minval, w_slash.DEL_FILTER.maxval, -5, 5, val)
      crow.send("ii.wdel.filter(" .. filter_val .. ")") 
      pset_wdel_filter = val
      params:set("wdel_freeze",1)
    end
  }

  params:add {
    type = "option",
    id = "wdel_freq_to_freq",
    name = "Freq to del freq",
    options = {"off","1x","2x","3x","4x","5x","6x"},
    default=2,
    action = function(val)       
    end
  }
  

  params:add {
    type = "control",
    id = "wdel_frequency",
    name = "Del Frequency (V8)",
    controlspec = controlspec.new(-5, 5, "lin", 0, -1.5),
    action = function(val)       
      crow.send("ii.wdel.freq(" .. val .. ")") 
      pset_wdel_frequency = val
    end
  }

  params:add {
    type = "control",
    id = "wdel_mod_rate",
    name = "Mod Rate",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0),
    action = function(val)       
      crow.send("ii.wdel.mod_rate(" .. val .. ")") 
      pset_wdel_mod_rate = val
    end
  }

  params:add {
    type = "control",
    id = "wdel_mod_amount",
    name = "Mod Amount",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0),
    action = function(val)       
      crow.send("ii.wdel.mod_amount(" .. val .. ")") 
      pset_wdel_mod_amount = val
    end
  }

  --[[
  params:add {
    type = "control",
    id = "wdel_length_count",
    name = "Length Count",
    controlspec = controlspec.new(0, 10, "lin", 0,  1),
    action = function(val)       
      crow.send("ii.wdel.length(" .. val ..",".. params:get("wdel_length_divisions") .. ")") 
      pset_wdel_length_count = val
    end
  }
  
  params:add {
    type = "control",
    id = "wdel_length_divisions",
    name = "Length Divisions",
    controlspec = controlspec.new(0, 10, "lin", 0, 1),
    action = function(val)       
      crow.send("ii.wdel.length(" .. params:get("wdel_length_count") ..",".. val .. ")") 
      pset_wdel_length_divisions = val
    end
  }
  
  params:add {
    type = "control",
    id = "wdel_position_count",
    name = "Position Count",
    controlspec = controlspec.new(0, 10, "lin", 0, 1),
    action = function(val)       
      crow.send("ii.wdel.position(" .. val ..",".. params:get("wdel_position_divisions") .. ")") 
      pset_wdel_position_count = val
    end
  }
  
  params:add {
    type = "control",
    id = "wdel_position_divisions",
    name = "Position Divisions",
    controlspec = controlspec.new(0, 10, "lin", 0, 1),
    action = function(val)       
      crow.send("ii.wdel.position(" .. params:get("wdel_position_count") ..",".. val .. ")") 
      pset_wdel_position_divisions = val
    end
  }
  
  params:add {
    type = "control",
    id = "wdel_cut_count",
    name = "Cut Count",
    controlspec = controlspec.new(0, 10, "lin", 0, 1),
    action = function(val)       
      crow.send("ii.wdel.cut(" .. val ..",".. params:get("wdel_cut_divisions") .. ")") 
      pset_wdel_cut_count = val
    end
  }

  params:add {
    type = "control",
    id = "wdel_cut_divisions",
    name = "Cut Divisions",
    controlspec = controlspec.new(0, 10, "lin", 0, 1),
    action = function(val)       
      crow.send("ii.wdel.cut(" .. params:get("wdel_cut_count") ..",".. val .. ")") 
      pset_wdel_cut_divisions = val
    end
  }
  ]]

  params:add {
    type = "control",
    id = "wdel_clock",
    name = "Clock",
    controlspec = controlspec.new(-5, 5, "lin", 0, 1),
    action = function(val)       
      crow.send("ii.wdel.clock(" .. val .. ")") 
      pset_wdel_clock = val
    end
  }

  params:add {
    type = "control",
    id = "wdel_clock_ratio_mul",
    name = "Clock ratio mul",
    controlspec = controlspec.new(0, 10, "lin", 0, 1),
    action = function(val)       
      crow.send("ii.wdel.clock_ratio(" .. val ..",".. params:get("wdel_clock_ratio_div") .. ")") 
      pset_wdel_clock_ratio_mul = val
    end
  }
  
  params:add {
    type = "control",
    id = "wdel_clock_ratio_div",
    name = "clock ratio div",
    controlspec = controlspec.new(0, 10, "lin", 0, 1),
    action = function(val)       
      crow.send("ii.wdel.clock_ratio(" .. params:get("wdel_clock_ratio_mul") ..",".. val .. ")") 
      pset_wdel_clock_ratio_div = val
    end
  }
  
  params:add {
    type = "control",
    id = "wdel_rate",
    name = "Rate",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0.353),
    action = function(val)       
      crow.send("ii.wdel.rate(" .. val .. ")") 
      pset_wdel_rate = val
      params:set("wdel_freeze",1)
    end
  }

  params:add{type = "trigger", id = "wdel_pluck", name = "Pluck",
    action = function(val)
      crow.send("ii.wdel.pluck(5)") 
      params:set("wdel_freeze",1)
    end
  }

    params:add{type = "option", id = "wdel_freeze", name = "Freeze",
    options = {"active","frozen"}, default=1,
    action = function(val)
      local freeze_val = val == 1 and 0 or 1
      crow.send("ii.wdel.freeze(" .. freeze_val .. ")") 
    end}


  params:add{
    type = "trigger",
    id = "wdel_init",
    name = "W Delay Init",
    action = function()
      params:set("output_wdel_ks", pset_wdel_ks)
      params:set("wdel_time_mix", pset_wdel_mix)
      params:set("wdel_time_long", pset_wdel_time_long)
      params:set("wdel_time_short", pset_wdel_time_short)
      params:set("wdel_feedback", pset_wdel_feedback)
      params:set("wdel_filter", pset_wdel_filter)
      params:set("wdel_clock_ratio_mul", pset_wdel_clock_ratio_mul)
      params:set("wdel_clock_ratio_div", pset_wdel_clock_ratio_div)
      params:set("wdel_rate", pset_wdel_rate)
      params:set("wdel_freq", pset_wdel_freq)
      params:set("wdel_pluck", pset_wdel_pluck)
      params:set("wdel_mod_rate", pset_wdel_mod_rate)
      params:set("wdel_mod_amount", pset_wdel_mod_amount)
      params:set("wdel_freeze", pset_wdel_ffreeze)
      --[[
      params:set("wdel_length_count", pset_wdel_length_count)
      params:set("wdel_length_divisions", pset_wdel_length_divisions)
      params:set("wdel_position_count", pset_wdel_position_divisions)
      params:set("wdel_cut_count", pset_wdel_cut_count)
      params:set("wdel_cut_divisions", pset_wdel_cut_divisions)
      params:set("wdel_clock", pset_wdel_clock)
      ]]
    end
  }
  params:hide("wdel_init")
end

function w_slash.wsyn_add_params()
  params:add{type = "option", id = "output_wsyn", name = "wsyn output",
    options = {"off","plants","midi", "plants + midi"},
    default = 1,
    action = function(val)
      pset_wsyn_outut_wsyn = val
      -- if val == 2 then 
        -- crow.output[2].action = "{to(5,0),to(0,0.25)}"
        -- crow.ii.pullup(true)
        -- crow.ii.jf.mode(1)
      -- end
    end
  }


  --[[ 
  -- code for wsyn patching (work in progress)
  local patch_options = {'none','ramp','curve','fm_env','fm_index','lpg_time','lpg_symmetry','gate','v8 (gate rqrd)','fm_ratio (num)','fm_ratio (denom)'}
  params:add {
    type = "option",
    id = "input1",
    name = "Input 1",
    options = patch_options,
    default = 1,
    action = function(val) 
      if val-1 > 0 then
        crow.send("ii.wsyn.patch(".. (val-1) ..", 1)")
      end
    end
  }

  params:add {
    type = "option",
    id = "input2",
    name = "Input 2",
    options = patch_options,
    default = 1,
    action = function(val) 
      if val-1 > 0 then
        crow.send("ii.wsyn.patch(".. (val-1) ..", 2)")
      end
    end
  }
  ]]

  params:add {
    type = "option",
    id = "wsyn_ar_mode",
    name = "AR mode",
    options = {"off", "on"},
    default = 2,
    action = function(val) 
      crow.send("ii.wsyn.ar_mode(".. (val-1) ..")")
      pset_wsyn_ar_mode = val
    end
  }

  params:add {
    type = "control",
    id = "wsyn_vel",
    name = " Velocity",
    controlspec = controlspec.new(0, 5, "lin", 0, 2, "v"),
    action = function(val) 
      pset_wsyn_vel = val
    end
  }

  params:add {
    type = "control",
    id = "wsyn_curve",
    name = " Curve",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) 
      crow.send("ii.wsyn.curve(" .. val .. ")") 
      pset_wsyn_curve = val
    end
  }

  params:add {
    type = "control",
    id = "wsyn_ramp",
    name = " Ramp",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) 
      crow.send("ii.wsyn.ramp(" .. val .. ")") 
      pset_wsyn_ramp = val
    end
  }
  params:add {
    type = "control",
    id = "wsyn_fm_index",
    name = "FM index",
    controlspec = controlspec.new(0, 5, "lin", 0, 0, "v"),
    action = function(val) 
      crow.send("ii.wsyn.fm_index(" .. val .. ")") 
      pset_wsyn_fm_index = val
    end
  }
  params:add {
    type = "control",
    id = "wsyn_fm_env",
    name = "FM env",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) 
      crow.send("ii.wsyn.fm_env(" .. val .. ")") 
      pset_wsyn_fm_env = val
    end
  }
  params:add {
    type = "control",
    id = "wsyn_fm_ratio_num",
    name = "FM ratio numerator",
    controlspec = controlspec.new(1, 20, "lin", 1, 2),
    action = function(val) 
      crow.send("ii.wsyn.fm_ratio(" .. val .. "," .. params:get("wsyn_fm_ratio_den") .. ")") 
      pset_wsyn_fm_ratio_num = val
    end
  }
  params:add {
    type = "control",
    id = "wsyn_fm_ratio_den",
    name = "FM ratio denominator",
    controlspec = controlspec.new(1, 20, "lin", 1, 1),
    action = function(val) 
      crow.send("ii.wsyn.fm_ratio(" .. params:get("wsyn_fm_ratio_num") .. "," .. val .. ")") 
      pset_wsyn_fm_ratio_den = val
    end
  }
  params:add {
    type = "control",
    id = "wsyn_lpg_time",
    name = "LPG time",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) 
      crow.send("ii.wsyn.lpg_time(" .. val .. ")") 
      pset_wsyn_lpg_time = val
    end
  }
  params:add {
    type = "control",
    id = "wsyn_lpg_symmetry",
    name = "LPG symmetry",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) 
      crow.send("ii.wsyn.lpg_symmetry(" .. val .. ")") 
      pset_wsyn_lpg_symmetry = val
    end
  }
  params:add{
    type = "trigger",
    id = "wsyn_pluckylog",
    name = "Pluckylogger >>>",
    action = function()
      params:set("wsyn_curve", math.random(-40, 40)/10)
      params:set("wsyn_ramp", math.random(-5, 5)/10)
      params:set("wsyn_fm_index", math.random(-50, 50)/10)
      params:set("wsyn_fm_env", math.random(-50, 40)/10)
      params:set("wsyn_fm_ratio_num", math.random(1, 4))
      params:set("wsyn_fm_ratio_den", math.random(1, 4))
      params:set("wsyn_lpg_time", math.random(-28, -5)/10)
      params:set("wsyn_lpg_symmetry", math.random(-50, -30)/10)
    end
  }
  params:add{
    type = "trigger",
    id = "wsyn_randomize",
    name = "Randomize all >>>",
    action = function()
      params:set("wsyn_curve", math.random(-50, 50)/10)
      params:set("wsyn_ramp", math.random(-50, 50)/10)
      params:set("wsyn_fm_index", math.random(0, 50)/10)
      params:set("wsyn_fm_env", math.random(-50, 50)/10)
      params:set("wsyn_fm_ratio_num", math.random(1, 20))
      params:set("wsyn_fm_ratio_den", math.random(1, 20))
      params:set("wsyn_lpg_time", math.random(-50, 50)/10)
      params:set("wsyn_lpg_symmetry", math.random(-50, 50)/10)
    end
  }
  params:add{
    type = "trigger",
    id = "wsyn_init",
    name = "W Synth Init",
    action = function()
      params:set("wsyn_curve", pset_wsyn_curve)
      params:set("wsyn_ramp", pset_wsyn_ramp)
      params:set("wsyn_fm_index", pset_wsyn_fm_index)
      params:set("wsyn_fm_env", pset_wsyn_fm_env)
      params:set("wsyn_fm_ratio_num", pset_wsyn_fm_ratio_num)
      params:set("wsyn_fm_ratio_den", pset_wsyn_fm_ratio_den)
      params:set("wsyn_lpg_time", pset_wsyn_lpg_time)
      params:set("wsyn_lpg_symmetry", pset_wsyn_lpg_symmetry)
      params:set("wsyn_vel", pset_wsyn_vel)
    end
  }
  params:hide("wsyn_init")
end

function w_slash.wtape_add_params()
  params:add {
    type = "number",
    id = "wtape_timestamp",
    name = "Timestamp",
    min = 0,
    action = function(val)       
      crow.send("ii.wtape.timestamp(" .. val .. ")") 
      pset_wtape_timestamp = val
    end
  }

  params:add {
    type = "number",
    id = "wtape_seek",
    name = "Seek",
    default = 0,
    action = function(val)       
      crow.send("ii.wtape.seek(" .. val .. ")") 
      pset_wtape_seek = val
    end
  }

  params:add{type = "option", id = "wtape_record", name = "Record",
    options = {"off","on"}, default=1,
    action = function(val)
      local record_val = val == 1 and 0 or 1
      crow.send("ii.wtape.record(" .. record_val .. ")") 
      pset_wtape_record = val
    end
  }

  params:add{type = "option", id = "wtape_play", name = "Play",
    options = {"off","on"}, default=1,
    action = function(val)
      local play_val = val == 1 and 0 or 1
      crow.send("ii.wtape.play(" .. play_val .. ")") 
      pset_wtape_play = val
    end
  }

  params:add{type = "trigger", id = "wtape_reverse", name = "Reverse",
    action = function()
      crow.send("ii.wtape.reverse()") 
    end
  }

  params:add{type = "option", id = "wtape_loop_active", name = "Loop Active",
    options = {"false","true"}, default=1,
    action = function(val)
      local loop_active = val == 1 and 0 or 1
      crow.send("ii.wtape.loop_active(" .. loop_active .. ")") 
      pset_wtape_loop_active = val
    end
  } 
    
  params:add {
    type = "option",
    id = "wtape_echo_mode",
    name = "Echo Mode",
    options = {"off","on"},
    default = 1,
    action = function(val)
      local echo_mode = val == 1 and 0 or 1
      crow.send("ii.wtape.loop_active(" .. echo_mode .. ")") 
      pset_wtape_echo_mode = val
    end
  }

  params:add{type = "trigger", id = "wtape_loop_start", name = "Loop Start",
    action = function()
      crow.send("ii.wtape.loop_start()") 
    end
  }
  
  params:add{type = "trigger", id = "wtape_loop_end", name = "Loop End",
    action = function()
      crow.send("ii.wtape.loop_end()") 
    end
  }

  params:add{type = "option", id = "wtape_loop_next", name = "Loop Next",
    options = {"backward","forward"}, default=1,
    action = function(val)
      local direction = val == 1 and -1 or 1
      crow.send("ii.wtape.loop_next(" .. direction .. ")") 
      pset_wtape_next = direction
    end
  }

  params:add{type = "trigger", id = "wtape_loop_next_trigger", name = "Loop Next Trigger",
    action = function(val)
      crow.send("ii.wtape.loop_next(" .. pset_wtape_next .. ")") 
    end
  } 

  params:add{type = "option", id = "wtape_loop_scale_mult", name = "Set Loop Scale",
    options = {"reset","half speed", "2x speed"},
    action = function(val)
      if val == 1 then 
        pset_wtape_loop_scale = 0
      elseif val == 2 then 
        pset_wtape_loop_scale = 2
      elseif val == 3 then 
        pset_wtape_loop_scale = 0.5
      end
      crow.send("ii.wtape.loop_scale(" .. pset_wtape_loop_scale .. ")") 
    end
  } 

  params:add {
    type = "control",
    id = "wtape_speed",
    name = "Speed",
    controlspec = controlspec.new(0.75, 1.5, "lin", 0, 1),
    action = function(val)       
      crow.send("ii.wtape.speed(" .. val .. ")") 
      pset_wtape_speed = val
    end
  }

  params:add {
    type = "control",
    id = "wtape_freq",
    name = "Freq (v8)",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0),
    action = function(val)       
      crow.send("ii.wtape.freq(" .. val .. ")") 
      pset_wtape_freq = val
    end
  }

  params:add {
    type = "control",
    id = "wtape_erase_strength",
    name = "Erase Strength",
    controlspec = controlspec.new(0, 1, "lin", 0, 0.5),
    action = function(val)       
      crow.send("ii.wtape.erase_strength(" .. val .. ")") 
      pset_wtape_erase_strength = val
    end
  }
  
  params:add {
    type = "control",
    id = "wtape_monitor_level",
    name = "Monitor Level",
    controlspec = controlspec.new(0, 1, "lin", 0, 0.5),
    action = function(val)       
      crow.send("ii.wtape.monitor_level(" .. val .. ")") 
      pset_wtape_monitor_level = val
    end
  }
  
  params:add {
    type = "control",
    id = "wtape_rec_level",
    name = "Record Level",
    controlspec = controlspec.new(0, 1, "lin", 0, 0.5),
    action = function(val)       
      crow.send("ii.wtape.rec_level(" .. val .. ")") 
      pset_wtape_rec_level = val
    end
  }
  
  params:add{
    type = "trigger",
    id = "wtape_init",
    name = "W Tape Init",
    action = function()
      params:set("wtape_record", pset_wtape_record)
      params:set("wtape_play", pset_wtape_play)
      params:set("wtape_loop_scale", pset_wtape_loop_scale)
      params:set("wtape_loop_direction", pset_wtape_loop_direction)
      params:set("wtape_loop_active", pset_wtape_loop_active)
      params:set("wtape_timestamp", pset_wtape_timestamp)
      params:set("wtape_seek", pset_wtape_seek)
      params:set("wtape_speed", pset_wtape_speed)
      params:set("wtape_freq", pset_wtape_freq)
      params:set("wtape_erase_strength", pset_wtape_erase_strength)
      params:set("wtape_monitor_level", pset_wtape_monitor_level)
      params:set("wtape_rec_level", pset_wtape_rec_level)
      params:set("wtape_echo_mode", pset_wtape_echo_mode)
    end
  }
  params:hide("wtape_init")
end

return w_slash
