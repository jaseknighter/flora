---flora - beta
-- v0.1.0-beta @jaseknighter
-- lines: llllllll.co/t/40261
--
-- k1+k2: show/hide instructions

------------------------------
-- includes (found in includes.lua), notes and todo list:

-- includes: 
--  globals (global variables, constants, and functions)
--  encoders_and_keys
--  parameters
--  flora_pages (code to decide which screen and top navigation to display)
--  plant (l-system code run on pages 1-3. also contains includes for sounds)
--  envelope (envelope code run on page 4)
--  water (engine and output parameter code run on page 5)
--
-- todo list: 
--  improve the quality and portability of the code
--  (done) create parameters for envelope settings
--  (done) make additional Bandsaw variables available to crow, jf, and midi output (e.g., note frequency)
--  add modulation and probability controls
--  increase and decrease the brightness of the circles that appear when each note plays
--    according to the level of the note's graph/envelope
--  improve screen drawing efficiency
--    then, the SCREEN_FRAMERATE value can be increased safely 
--    and more complex/lengthy sentences can be safely supported
--  address coding/nomenclature inconsistencies (reference coding guidelines: https://github.com/monome/norns/wiki/coding-style-(lua))
--    examples: 
--      'setup' vs 'init' vs 'new' 
  --    inconsistent use of ALL CAPS for naming constant values
--      use of colon vs dot function syntax
--  enable control over ruleset variables (axiom and ruleset especially)
--  add keyboard control for updating sentences/rulesets
--  explore support for more than two plants at a time
--  investigate (seemingly non-consequential) error message at startup related to midi maps 
--    for controls not yet created (e.g. for note frequencies > 1):
--      lua: /home/we/norns/lua/core/paramset.lua:301: attempt to index a nil value (local 'param')
--      stack traceback:
--        /home/we/norns/lua/core/paramset.lua:301: in function 'core/paramset.t'
--        /home/we/norns/lua/core/menu/params.lua:589: in field 'menu_midi_event'
--        /home/we/norns/lua/core/midi.lua:404: in function </home/we/norns/lua/core/midi.lua:391>
--  prevent 'wrong count of arguments' warning (e.g. for command 'set_frequencies')
--  free up allocated sc server resources less abruptly when stopping the engine
--
-- notes: 
--  additional notes and todo lists may be found in the other lua and sc code files
--  credits: Brian Crabtree (@tehn), Dan Derks(@dan_derks), Daniel Shiffman, Eli Fieldsteel, Mark Wheeler (@markwheeler), Tom Armitage (@infovore), Tyler Etters (@tyleretters)
--  source code and documentation: https://github.com/jaseknighter/flora 
------------------------------

include "flora/lib/includes"

------------------------------
-- init
------------------------------
function init()

  -- set sensitivity of the encoders
  norns.enc.sens(1,6)
  norns.enc.sens(2,6)
  norns.enc.sens(3,6)

  pages = UI.Pages.new(0, 5)
  
  -- look for a 16n device
  for i=16, 1, -1
  do
    if midi.devices[i] then
      if midi.devices[i].name == "16n" then device_16n = midi.devices[i] end
    end
  end
  
  if default_to_community_garden then
    l_system_instructions = l_system_instructions_community
  else
    l_system_instructions = l_system_instructions_default
  end

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
  -- env_parameters.add_params()
  build_scale()

  for i=1,num_plants,1
  do
    plants[i].run_plant_code()
  end
  
  water.init()
  set_redraw_timer()
  page_scroll(1)
  -- polls.init()
  for i=1,#midi.vports,1 
  do
    if midi.vports[i].device and midi.vports[i].device.name == "16n" then
      -- print("found 16n")
      device_16n = midi.vports[i].device
    end
  end
  
  
  --------------------------
  -- setup pset sequencer and pset exclusions
  --------------------------
  pset_seq.set_pset_path ("flora/")
  
  -- plant modulation exclusion group
  local pset_param_exclusions_plant = {"plant1_instructions","plant2_instructions","plant1_angle","plant2_angle"}
  
  -- plow exclusion group
  local pset_param_exclusions_plow = {"num_plow1_controls","num_plow2_controls","plow1_max_level","plow1_max_time","randomize_env_probability1","time_probability1","level_probability1","curve_probability1","time_modulation1","level_modulation1","curve_modulation1","randomize_env_probability2","time_probability2","level_probability2","curve_probability2","time_modulation2","level_modulation2","curve_modulation2"}
  
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
  
  -- table for exclusion group table names
  local pset_exclusion_tables = {pset_param_exclusions_plant,pset_param_exclusions_plow,pset_param_exclusions_plow_modulation,pset_param_exclusions_water,pset_param_exclusions_nav}
  
  -- table for exclusion group labels 
  local pset_exclusion_table_labels = {"plant psets","plow psets","plow mod psets","water psets", "nav psets"}
  
  -- call pset sequencer to initialize and setup exclusion groups
  pset_seq.pset_seq_timer_init(pset_exclusion_tables, pset_exclusion_table_labels)
  
  clock.run(init_done)
end

function init_done()
  clock.sleep(0.5)
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
function set_redraw_timer()
  redrawtimer = metro.init(function() 
    local status = norns.menu.status()
    if status == false and menu_status == false and initializing == false then
      if screen_dirty then
        flora_pages.draw_pages()
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
    end
  end, SCREEN_FRAMERATE, -1)
  redrawtimer:start()
  
end


function cleanup ()
  all_notes_off()
end

