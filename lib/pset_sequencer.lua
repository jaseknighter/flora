-- a PSET sequencer 

------------------------------
-- a note about pset sequencer portability to other scripts:
--
-- although not much testing has been done, this code should be portable to most other norns scripts. 

-- only two lines of code are required for basic functionality to work (see "SIMPLE EXAMPLE" below).
-- groups of params may be setup to be excluded from the PSET sequencer (see "PSET EXCLUSION GROUP EXAMPLE" below) 

-- SIMPLE EXAMPLE
-- add the two lines below to the script's init function:
--[[ 
  
  pset_seq = include "flora/lib/pset_sequencer"
  pset_seq.init()

]]

-- PSET EXCLUSION GROUP EXAMPLE
-- add the lines below to setup exclusion groups and modify as needed
-- another example may be found at the end of flora.lua's init function
--[[ 

  pset_seq = include "flora/lib/pset_sequencer"

  -- these two lines setup two exclusion groups 
  local exclusion_group_1 = {"scale_mode", "root_note"}
  local exclusion_group_2 = {"rev_eng_input","rev_cut_input","rev_monitor_input","rev_tape_input","rev_return_level","rev_pre_delay","rev_lf_fc","rev_low_time","rev_mid_time","rev_hf_damping"}

  -- create a table with the names of the exclusion group variable names
  local pset_exclusion_tables = {exclusion_group_1, exclusion_group_2}

  -- create a table with labels for the exclusion group variable names 
  --    note: you'll see these labels in the params menu
  local pset_exclusion_table_labels = {"exclude root note/scale", "exclude reverb params"}

  -- initialize the PSET sequencer, passing it the two variables defined above: `pset_exclusion_tables` and `pset_exclusion_table_labels`
  pset_seq.init(pset_exclusion_tables, pset_exclusion_table_labels)

]]
------------------------------

------------------------------
-- pset path and PSET exclusion setup
------------------------------

local pset_path
local pset_seq = {}

-- set pset exclusions
local function set_pset_param_exclusions(pset_exclusion_tables, pset_exclusion_table_labels)
  for i=1,#pset_exclusion_tables,1
  do
    if #pset_exclusion_table_labels > 0 then
        params:add{type = "option", id = pset_exclusion_table_labels[i].."_excl", name = pset_exclusion_table_labels[i],
        options = {"false", "true"}, default = 1,
          action = function(x) 
            local setting
            if x==1 then setting = true else setting = false end
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
  -- local current_pset = first.min
  pset_seq_timer = metro.init(function() 
    if params:get("pset_seq_enabled") == 2 then
      local first = params:lookup_param("pset_exclusion_first")
      local last = params:lookup_param("pset_exclusion_last")
      local new_pset_id
      -- print("yo", params:lookup_param("pset_exclusion_first").min, params:lookup_param("pset_exclusion_last").max)
        pset_seq_ticks = pset_seq_ticks + 1
      if pset_seq_ticks == ticks_per_seq_cycle then
        pset_seq_ticks = 1
        local num_psets = last.value - first.value + 1
        -- local num_psets = pset_seq.get_num_psets()
        local current_pset = params:get("load_pset")
        local mode = params:get("pset_seq_mode")
        if mode == 1 then
          new_pset_id = current_pset < last.value and current_pset + 1 or first.value
        elseif mode == 2 then
          if first.value == last.value then
            new_pset_id = first.value
          elseif pset_seq_direction == "up" then
            new_pset_id = current_pset < last.value and current_pset + 1 or current_pset - 1
            pset_seq_direction = current_pset < last.value and pset_seq_direction or "down"
          else
            new_pset_id = current_pset > first.value and current_pset - 1 or current_pset + 1
            pset_seq_direction =  current_pset > first.value and pset_seq_direction or "up"
          end
        elseif mode == 3 then
          new_pset_id = math.random(1,num_psets) + first.value - 1
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

function set_num_psets()
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
        params:set_save(paramlist[i],state)
      end
    end
  end
end

------------------------------
-- pset sequencer init
------------------------------
pset_seq.init = function (pset_exclusion_tables, pset_exclusion_table_labels)
  
  pset_path = _path.data .. norns.state.name .. "/"

  -- setup pset sequence parameters
  set_num_psets()
  local num_pset_exclusion_sets = pset_exclusion_table_labels and #pset_exclusion_table_labels+1 or 0
  params:add_group("pset sequencer",8+num_pset_exclusion_sets)

  params:add_option("pset_seq_enabled","pset seq enabled", {"false", "true"})
  params:set_action("pset_seq_enabled", function(x) 
    if x == 2 then
      initializing_pset_seq_timer = true
      metro.free(pset_seq_timer.props.id)
      set_pset_seq_timer()
      set_pset_exclusion_last()
      set_pset_exclusion_first()
      initializing_pset_seq_timer = false
    end
  end )

    params:add_option("pset_seq_mode","pset seq mode", {"loop", "up/down", "random"})
  params:add_number("load_pset", "load pset", 1, pset_seq.get_num_psets(),1,nil, false, false)

  params:set_action("load_pset", function(x) 
    set_num_psets()
    pset_seq.get_num_psets() 
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

  
  function set_pset_exclusion_first(val)
    set_num_psets()    
    local first = params:lookup_param("pset_exclusion_first")
    first.max = pset_seq.get_num_psets()

    if first.value == 0 then
      params:set("pset_exclusion_first",1) 
    elseif first.value > first.max then 
      params:set("pset_exclusion_first",first.max) 
    end

    if val then
      local clamped_val = util.clamp(val,1,params:get("pset_exclusion_last"))
      if val > clamped_val then 
        params:set("pset_exclusion_first",clamped_val) 
      end
    end
  end
    
  function set_pset_exclusion_last(val)
    set_num_psets()    
    local last = params:lookup_param("pset_exclusion_last")
    last.max = pset_seq.get_num_psets()
  
    if last.value == 0 or last.value > last.max then
      params:set("pset_exclusion_last",last.max) 
    end
  
    if val then
      local clamped_val = util.clamp(val,params:get("pset_exclusion_first"), last.max)
      if val < clamped_val then 
        params:set("pset_exclusion_last", clamped_val) 
      end
    end
  end

  params:add_number("pset_exclusion_first", "first", 1, pset_seq.get_num_psets(), 1)
  params:set_action("pset_exclusion_first", function(val) 
    set_pset_exclusion_first(val)
    set_pset_exclusion_last()
  end )
  

  params:add_number("pset_exclusion_last", "last", 1, pset_seq.get_num_psets(), pset_seq.get_num_psets())
  params:set_action("pset_exclusion_last", function(val) 
    set_pset_exclusion_last(val)
    set_pset_exclusion_first()
  end )
  
  params:add_trigger("reset_first_lst_ranges","<<reset first/last ranges>>")
  params:set_action("reset_first_lst_ranges", function() 
    set_pset_exclusion_last(val)
    set_pset_exclusion_first()
  end )

  -- set default exclusions 
  -- INCLUDES HACK FOR FLORA to exclude plow screen params max level & max time by default until envelope PSET bug is fixed
  if pset_path == "/flora" then
    default_exclusions = {"pset_seq_enabled","pset_seq_mode","load_pset", "pset_seq_beats","pset_seq_beats_per_bar","plow1_max_level","plow1_max_time","plow2_max_level","plow2_max_time"}
  else
    default_exclusions = {"pset_seq_enabled","pset_seq_mode","load_pset", "pset_seq_beats","pset_seq_beats_per_bar", "pset_exclusion_first", "pset_exclusion_last"}
  end
  pset_seq.set_save_paramlist(default_exclusions, false)

  -- set the custom pset exclusions (defined in the script's main lua file, e.g., `flora.lua`)
  if pset_exclusion_tables then
    params:add_separator("pset exclusions")
    set_pset_param_exclusions(pset_exclusion_tables, pset_exclusion_table_labels)
  end
  
  -- end pset sequence timer
  set_pset_seq_timer()
end

return pset_seq
