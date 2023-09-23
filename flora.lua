---flora
-- v2.0
-- lines: llllllll.co/t/40261
--
-- k1+k2: show/hide instructions

------------------------------
-- todo list: 
--  add keyboard control for updating sentences/rulesets

--  credits: Brian Crabtree (@tehn), Dan Derks(@dan_derks), Daniel Shiffman, Eli Fieldsteel, Mark Wheeler (@markwheeler), Tom Armitage (@infovore), Tyler Etters (@tyleretters)
--  source code and documentation: https://github.com/jaseknighter/flora 
------------------------------

include "flora/lib/includes"

------------------------------
-- lfo code
------------------------------

lfo_lattice = Lattice:new{
  auto = true,
  meter = 4,
  ppqn = 96
}

lfo_pattern = lfo_lattice:new_sprocket{
  action = function(t) 
    if initializing == false then
      local lfo_slope1 = lfo[1].slope
      local lfo_slope2 = lfo[2].slope

      local lfo1_volts_min = params:get("1lfo_volts_min")
      local lfo1_volts_max = params:get("1lfo_volts_max")
      local lfo2_volts_min = params:get("2lfo_volts_min")
      local lfo2_volts_max = params:get("2lfo_volts_max")

      local lfo_val1 = util.linlin(-1,1,lfo1_volts_min,lfo1_volts_max,lfo_slope1)
      local lfo_val2 = util.linlin(-1,1,lfo2_volts_min,lfo2_volts_max,lfo_slope2)
      play_crow_lfos("1lfo", lfo_val1)
      play_midi_cc_lfos("1lfo", lfo[1].slope)
      play_crow_lfos("2lfo", lfo_val2)
      play_midi_cc_lfos("2lfo", lfo[2].slope)
    end
  end,
  division = 1/16,
  enabled = true
}

play_crow_lfos = function(source,volts)
  for i=1,4,1 do
    local output_crow = params:get("output_crow"..i)
    if source == "1lfo" and output_crow == 6 then -- lfo1 output
      crow.output[i].slew = params:get("1lfo_slew")/1000
      crow.output[i].volts = volts 
      crow.output[i]() 
    elseif source == "2lfo" and output_crow == 7 then -- lfo2 output
      crow.output[i].slew = params:get("2lfo_slew")/1000
      crow.output[i].volts = volts 
      crow.output[i]() 
    end
  end
end

play_midi_cc_lfos = function(source,volts)
  local play_midi_lfo1 = params:get("1play_midi_lfo_cc")
  local play_midi_lfo2 = params:get("2play_midi_lfo_cc")
  local cc_val = math.floor(util.linlin(-5,10,1,127,volts))
  if source == "1lfo" and play_midi_lfo1 == 2 then 
    -- local slew = params:get("lz_x_slew")/1000
    local cc = params:get("1midi_lfo_cc")
    local ch = params:get("1midi_lfo_chan")
    ch = ch > 0 and ch or nil
    if midi_out_device then  
      midi_out_device:cc(cc, cc_val, ch)
    end
    -- print("x",cc_val)
  end
  
  if source == "2lfo" and play_midi_lfo2 == 2 then 
    -- local slew = params:get("lz_y_slew")/1000
    local cc = params:get("2midi_lfo_cc")
    local ch = params:get("2midi_lfo_chan")
    ch = ch > 0 and ch or nil
    if midi_out_device then
      midi_out_device:cc(cc, cc_val, ch)
    end
  end
end

------------------------------
-- init
------------------------------
function init()
  -- set sensitivity of the encoders

  norns.enc.sens(1,6)
  norns.enc.sens(2,6)
  norns.enc.sens(3,6)


  nb:init()
  
  pages = UI.Pages.new(0, num_pages)
  
  -- look for a 16n device
  for i=16, 1, -1
  do
    if midi.devices[i] then
      if midi.devices[i].name == "16n" then device_16n = midi.devices[i] end
    end
  end
  
  -- if default_to_community_garden then
  --   l_system_instructions = l_system_instructions_community
  -- else
  --   l_system_instructions = l_system_instructions_default
  -- end

  for i=1,num_plants,1
  do
    envelopes[i] = envelope:new(i, num_plants)
    envelopes[i].init(num_plants)
    local active = i == 1 and true or false
    local initial_plant_instruction_num = i == 1 and INITIAL_PLANT_INSTRUCTIONS_1 or INITIAL_PLANT_INSTRUCTIONS_2
    envelopes[i].set_active(active)
    plants[i] = plant:new(i,initial_plant_instruction_num,envelopes[i].graph_nodes)
    if i == 1 then
      plants[1].set_active(true)
    end
  end

  parameters.add_params(plants)

  build_scale()
  for i=1,num_plants,1
  do
    plants[i].setup(plants[i].get_current_instruction())
  end
  
  modify.init()
  water.init()
  garden.init()

  -- for lib/hnds
  lfo_types = {"sine", "square", "s+h"}
  lfo_index = nil


  
  redraw_timer()
  page_scroll(1)
  -- polls.init()
  for i=1,#midi.vports,1 
  do
    if midi.vports[i].device and midi.vports[i].device.name == "16n" then
      -- print("found 16n")
      device_16n = midi.vports[i].device
    end
  end
  
  
  ----------- pset sequencer code starts here -------------
  
  -- plant modulation exclusion group
  local pset_param_exclusions_plant = {"plant1_instructions","plant2_instructions","plant1_angle","plant2_angle"}
  
  -- plow exclusion group
  local pset_param_exclusions_plow = {"num_plow1_controls","num_plow2_controls","plow1_max_level","plow1_max_time","plow2_max_level","plow2_max_time","randomize_env_probability1","time_probability1","level_probability1","curve_probability1","time_modulation1","level_modulation1","curve_modulation1","randomize_env_probability2","time_probability2","level_probability2","curve_probability2","time_modulation2","level_modulation2","curve_modulation2"}
  
  for i=1, MAX_ENVELOPE_NODES, 1
  do
    table.insert(pset_param_exclusions_plow, "plow1_time" .. i)
    table.insert(pset_param_exclusions_plow, "plow2_time" .. i)
    table.insert(pset_param_exclusions_plow, "plow1_level" .. i)
    table.insert(pset_param_exclusions_plow, "plow2_level" .. i)
    table.insert(pset_param_exclusions_plow, "plow1_curve" .. i)
    table.insert(pset_param_exclusions_plow, "plow2_curve" .. i)
  end
  
  -- plow modulation exclusion group
  local pset_param_exclusions_plow_modulation = {"randomize_env_probability1","time_probability1","level_probability1","curve_probability1","time_modulation1","level_modulation1","curve_modulation1"}
  
  -- water exclusion group
  local pset_param_exclusions_water = {"amp","rqmin","rqmax","note_scalar","num_active_cf_scalars","cfs1","cfs2","cfs3","cfs4","plant_1_note_duration","plant_2_note_duration","num_note_frequencies","tempo_scalar_offset","nf_numerator1","nf_denominator1","nf_offset1","nf_numerator2","nf_denominator2","nf_offset2","nf_numerator3","nf_denominator3","nf_offset3","nf_numerator4","nf_denominator4","nf_offset4","nf_numerator5","nf_denominator5","nf_offset5","nf_numerator6","nf_denominator6","nf_offset6"}
  
  -- nav exclusion group
  local pset_param_exclusions_nav = {"page_turner", "active_plant_switcher"}

  -- i/o exclusion group
  local pset_param_exclusions_inputs_outputs = {"midi_device","plant1_cc_channel","plant2_cc_channel","plow1_cc_channel","plow2_cc_channel","water_cc_channel","output_midi","midi_out_device","midi_out_channel1","midi_out_channel2","output_crow1","output_crow2","output_crow3","output_crow4","output_jf","jf_mode","output_wdel_ks","wdel_mix","wdel_time_short","wdel_time_long","wdel_feedback","wdel_filter","wdel_clock","wdel_clock_ratio_div","wdel_clock_ratio_mul","wdel_freeze","wdel_frequency","wdel_mod_rate","wdel_mod_amount","wdel_freeze","output_wsyn","wsyn_ar_mode","wsyn_vel","wsyn_curve","wsyn_ramp","wsyn_fm_index","wsyn_fm_env","wsyn_fm_ratio_num","wsyn_fm_ratio_den","wsyn_lpg_time","wsyn_lpg_symmetry","wsyn_pluckylog","wsyn_randomize","wsyn_init","wtape_timestamp","wtape_seek","wtape_record","wtape_play","wtape_reverse","wtape_loop_active","wtape_echo_mode","wtape_loop_start","wtape_loop_end","wtape_loop_next","wtape_loop_next_trigger","wtape_loop_scale_mult","wtape_speed","wtape_freq","wtape_erase_strength","wtape_monitor_level","wtape_rec_level"}

  -- root note & scale exclusion group
  local pset_param_exclusions_root_note_scale = {"scale_mode", "root_note"}

  -- table for exclusion group table names
  local pset_exclusion_tables = {pset_param_exclusions_plant,pset_param_exclusions_plow,pset_param_exclusions_plow_modulation,pset_param_exclusions_water,pset_param_exclusions_nav,pset_param_exclusions_inputs_outputs, pset_param_exclusions_root_note_scale}
  
  -- table for exclusion group labels 
  local pset_exclusion_table_labels = {"plant","plow","plow mod","water", "nav", "i/o", "root note/scale"}
  
  -- init the plant generation sequencer 
  p_gen_seq.init()

  -- init the pset sequencer passing pset exclusion info
  pset_seq.init(pset_exclusion_tables, pset_exclusion_table_labels)
  
  ----------- pset sequencer code ends here -------------

  save_load.init()
  sharer:new()
  sharer:init()
  clock.run(init_done)
end

function init_done()
  clock.sleep(0.5)
  function process_crow_input_stream(v)
    local x = math.abs(v)
    if params:get("input_crow2") == 2 then
      params:set("note_scalar",math.floor(x))
    end
  end
  
  midi_out_device = midi.connect(params:get("midi_out_device")) 
  midi_out_channel1 = params:get("midi_out_channel1")
  midi_out_channel2 = params:get("midi_out_channel2")
  midi_out_channel_tt = params:get("midi_out_channel_tt")

  crow.input[2].stream = process_crow_input_stream
  crow.input[2].mode("stream", 0.1)  
  lfo_lattice:start()
  lfo.init()
  tt.init()
  screen.clear()
  initializing = false
end

--------------------------
-- encoders and keys
--------------------------
function enc(n, delta)
  encoders_and_keys.enc(n, delta)
end

function key(n,z)
  encoders_and_keys.key(n, z)
end

--------------------------
-- redraw 
--------------------------
function redraw_timer()
  redrawtimer = metro.init(function() 
    local status = norns.menu.status()
    -- local menu_status = true
    if status == false and menu_status == false and initializing == false then
      if screen_dirty then
        flora_pages.draw_pages(true)
        screen_dirty = false
      elseif pages.index < 4 then
        local notes_only = true
        flora_pages.draw_pages(notes_only)
      end
    end
    
    if menu_status == true and status == false then
      menu_status = false
      screen_dirty = true
    elseif menu_status == false and status == true then
      menu_status = true
      params:get_midi_devices()
      _menu.rebuild_params()
    end
  end, SCREEN_FRAMERATE, -1)
  redrawtimer:start()
  
end

function cleanup ()
  all_notes_off()
end
