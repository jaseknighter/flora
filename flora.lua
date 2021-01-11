---flora - beta
-- v0.0.3-beta @jaseknighter
-- lines: llllllll.co/t/flora-beta/40261
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
--  create parameters for envelope settings
--  make additional Bandsaw variables available to crow, jf, and midi output (e.g., note frequency)
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
  
  
  if default_to_community_garden then
    l_system_instructions = l_system_instructions_community
  else
    l_system_instructions = l_system_instructions_default
  end

  for i=1,num_plants,1
  do
    envelopes[i] = envelope:new(i, num_plants)
    envelopes[i].init(num_plants)
    envelopes[i].set_env_max_level(ENV_MAX_LEVEL_DEFAULT)
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
    plants[i].run_plant_code()
  end
  
  water.init()
  set_redraw_timer(SCREEN_FRAMERATE)
  page_scroll(1)
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
