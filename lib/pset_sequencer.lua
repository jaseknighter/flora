-- a PSET sequencer 

------------------------------
-- a note about pset sequencer portability to other scripts:
--
-- although not much testing has been done, this code should be portable to other norns scripts. 

-- only three lines of code are required for basic functionality to work.
--
-- to configure the pset sequencer for another (target) script follow the steps below and reference the subsequent code examples:
-- 
--  
-- STEPS
--
--    1. add an include statement that points to this file
--    2. setup the path to the target script's psets by calling the 'setup_pset_path' function and pass it a relative path to the script's pset directory (including a trailing slash in the directory's name)
--    3a. setup one or more table containing the names of parameters to exclude (note: if there are lots of params they can be grouped in separate tables)
--    3b. setup a table called something like 'pset_exclusion_tables' containing the name of each table created in the prior step
--    3c. (optional) setup a table called something like  'pset_exclusion_table_labels' containing labels for each table created in the prior step. these labels appear in the 'pset exclusions' group in the PARAMETERS->EDIT menu.
--    4. start the pset sequencer: call the function 'pset_seq_timer_init()' at the end of the scripts init function/sequence. 
--        IMPORTANT: if exclusion tables were create (in the optional steps 3a-3c), pass the two tables ('pset_exclusion_tables' and pset_exclusion_table_labels') to the 'pset_seq_timer_init' function like: 'pset_seq_timer_init(pset_exclusion_tables, pset_exclusion_table_labels)'
--
--
-- EXAMPLES (referencing the above steps)
--
-- (basic example) code for steps 1, 2 and 4 that goes to the end of the target script's init function:
--
--    pset_seq = include "flora/lib/pset_sequencer"
--    pset_seq.set_pset_path ("flora/")
--    pset_seq.pset_seq_timer_init(pset_exclusion_tables, pset_exclusion_table_labels)


-- (example with pset exclusions) code for steps 1-4 that goes to the end of the target script's init function:
--
--    pset_seq = include "flora/lib/pset_sequencer"
--    pset_seq.set_pset_path ("flora/")
--    local pset_param_exclusions_plant = {"plant1_instructions","plant2_instructions","plant1_angle","plant2_angle"}
--    local pset_param_exclusions_nav = {"page_turner", "active_plant_switcher"}
--    local pset_exclusion_tables = {pset_param_exclusions_plant,pset_param_exclusions_nav}
--    local pset_exclusion_table_labels = {"plant psets", "nav psets"}
--    pset_seq.pset_seq_timer_init(pset_exclusion_tables, pset_exclusion_table_labels)
--
-- note: for the above example with pset exclusions, you'll obvsiously want to customize the code to reference actual parameters used in the script you want to sequence.
------------------------------


-- local pset_path = _path.data.."flora/"
local pset_path

------------------------------
-- pset path and PSET exclusion setup
------------------------------

local pset_seq = {}

pset_seq.set_pset_path = function (pset_path_dir)
  pset_path = _path.data .. pset_path_dir 
end


-- set pset exclusions
local function set_pset_param_exclusions(pset_exclusion_tables, pset_exclusion_table_labels)
  -- set params for custom exclusions
  -- params:add_group("pset exclusions",#pset_exclusion_table_labels)
  for i=1,#pset_exclusion_tables,1
  do
    
    if #pset_exclusion_table_labels > 0 then
        params:add{type = "option", id = "exclude_" .. pset_exclusion_table_labels[i], name = "exclude " .. pset_exclusion_table_labels[i],
        options = {"false", "true"}, default = 1,
          action = function(x) 
            local setting
            if x==1 then setting = false else setting = true end
            pset_seq.set_save_paramlist(pset_exclusion_tables[i], setting)  
          end
        }
    end
  end
end


------------------------------
-- main pset sequencer code
------------------------------
local loading_preset = false
local ticks_per_seq_cycle = clock.get_tempo() * 1/1
local pset_seq_direction = "up"
local pset_dir_len

local function set_pset_seq_timer()
  local arg_time = clock.get_tempo()
  pset_seq_ticks = 1
  pset_seq_timer = metro.init(function() 
    if params:get("pset_seq_enabled") == 2 then
      pset_seq_ticks = pset_seq_ticks + 1
      if pset_seq_ticks == ticks_per_seq_cycle then
        pset_seq_ticks = 1
        local num_psets = pset_seq.get_num_psets()
        local current_pset = params:get("load_pset")
        local mode = params:get("pset_seq_mode")
        local new_pset_id
        if mode == 1 then
          new_pset_id = current_pset < num_psets and current_pset + 1 or 1
        elseif mode == 2 then
          if pset_seq_direction == "up" then
            new_pset_id = current_pset < num_psets and current_pset + 1 or current_pset - 1
            pset_seq_direction = current_pset < num_psets and pset_seq_direction or "down"
          else
            new_pset_id = current_pset > 1 and current_pset - 1 or current_pset + 1
            pset_seq_direction =  current_pset > 1 and pset_seq_direction or "up"
          end
        elseif mode == 3 then
          new_pset_id = math.random(1,num_psets)
        end
        
        local old_mode = mode
        params:set("load_pset", new_pset_id)
      end
    end  
    if clock.get_tempo() ~= arg_time and initializing_pset_seq_timer == false then
      initializing_pset_seq_timer = true
      metro.free(pset_seq_timer.props.id)
      set_pset_seq_timer()
      initializing_pset_seq_timer = false
    end
  end, 1/arg_time, -1)
  pset_seq_timer:start()
  initializing_pset_seq_timer = false
end

local function set_ticks_per_seq_cycle()
  ticks_per_seq_cycle = math.floor(clock.get_tempo() * (params:get("pset_seq_beats")/params:get("pset_seq_beats_per_bar")))
  pset_seq_ticks = 1
end 

local function set_num_psets()
  local dir = util.scandir (pset_path)
  if #dir ~= pset_dir_len then
    num_psets = 0
    for i=1,#dir,1
    do
      if (string.find(dir[i],".pset") ~= nil) then
        num_psets = num_psets + 1
      end
    end
    pset_dir_len = #dir
  end
end

pset_seq.get_num_psets = function()
  return num_psets
end

pset_seq.set_save_paramlist = function(paramlist, state)
  if paramlist and #paramlist > 0  then
    for i=1,#paramlist,1
    do
      if paramlist[i] then
        -- print("paramlist[i]",paramlist[i], state)
        params:set_save(paramlist[i],state)
      end
    end
  end
end

------------------------------
-- pset sequencer init
------------------------------
pset_seq.pset_seq_timer_init = function (pset_exclusion_tables, pset_exclusion_table_labels)

  -- setup pset sequence parameters
  set_num_psets()
  params:add_group("pset sequencer",5+#pset_exclusion_table_labels)
  params:add_option("pset_seq_enabled","pset seq enabled", {"false", "true"})
  params:add_option("pset_seq_mode","pset seq mode", {"loop", "up/down", "random"})
  params:add_number("load_pset", "load pset", 1, pset_seq.get_num_psets(),1,nil, false, false)

  params:set_action("load_pset", function(x) 
    set_num_psets()
    local param = params:lookup_param("load_pset")
    param.max = pset_seq.get_num_psets() 
    
    if x>param.max then 
      x = param.max 
      param.value = param.max 
    end
    params.value = x
    params:read(x)
    param.value = x
  
  end )
  
  params:add_number("pset_seq_beats", "pset seq beats", 1, 16, 4)
  params:set_action("pset_seq_beats", function() 
    set_ticks_per_seq_cycle() 
  end )
  params:add_number("pset_seq_beats_per_bar", "pset seq beats per bar", 1, 4, 1)
  params:set_action("pset_seq_beats_per_bar", function() set_ticks_per_seq_cycle() end )
  
  -- set default exclusions
  local default_exclusions = {"pset_seq_enabled","pset_seq_mode","load_pset", "pset_seq_beats","pset_seq_beats_per_bar"}
  pset_seq.set_save_paramlist(default_exclusions, false)

  -- set the custom pset exclusions (defined in flora.lua)
  if pset_exclusion_tables then
    set_pset_param_exclusions(pset_exclusion_tables, pset_exclusion_table_labels)
  end
  
  -- start pset sequence timer
  set_pset_seq_timer()
end

return pset_seq
