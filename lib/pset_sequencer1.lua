--------------------------
-- pset sequencer configs
-- update these based on the script being loaded
--------------------------
local pset_path = _path.data.."flora/"

local pset_param_exclusions_plant = {"plant1_instructions","plant2_instructions","plant1_angle","plant2_angle"}
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

local pset_param_exclusions_plow_modulation = {"randomize_env_probability1","time_probability1","level_probability1","curve_probability1","time_modulation1","level_modulation1","curve_modulation1"}

local pset_param_exclusions_water = {"amp","rqmin","rqmax","note_scalar","num_active_cf_scalars","cfs1","cfs2","cfs3","cfs4","plant_1_note_duration","plant_2_note_duration","num_note_frequencies","tempo_scalar_offset","nf_numerator1","nf_denominator1","nf_offset1","nf_numerator2","nf_denominator2","nf_offset2","nf_numerator3","nf_denominator3","nf_offset3","nf_numerator4","nf_denominator4","nf_offset4","nf_numerator5","nf_denominator5","nf_offset5","nf_numerator6","nf_denominator6","nf_offset6"}

pset_paramset_exclusions = {pset_param_exclusions_plant,pset_param_exclusions_plow,pset_param_exclusions_plow_modulation,pset_param_exclusions_water}

pset_paramset_exclusions_labels = {"none","plant psets","plow psets","plow mod psets","water psets"}



------------------------------
-- pset sequencer code
------------------------------
local loading_preset = false
local ticks_per_seq_cycle = clock.get_tempo() * 1/1
local pset_seq_direction = "up"
local updating_seq = false




function set_pset_seq_timer()
  local arg_time = clock.get_tempo()
  pset_seq_ticks = 1
  pset_seq_timer = metro.init(function() 
    if params:get("pset_seq_enabled") == 2 and updating_seq == false then
      pset_seq_ticks = pset_seq_ticks + 1
      if pset_seq_ticks == ticks_per_seq_cycle then
        pset_seq_ticks = 1
        local num_psets = get_num_psets()
        local current_pset = params:get("pset_load_seq")
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
        params:set("pset_load_seq", new_pset_id)
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

-- function set_ticks_per_seq_cycle()
--   ticks_per_seq_cycle = clock.get_tempo() * params:get("pset_seq_beats")/params:get("pset_seq_beats_per_bar")
--   pset_seq_ticks = 1
-- end 

function set_num_psets()
  num_psets = 0
  local dir = util.scandir (pset_path)
  for i=1,#dir,1
  do
    if (string.find(dir[i],".pset") ~= nil) then
      num_psets = num_psets + 1
    end
  end
end

function get_num_psets()
  return num_psets
end

-- function load_params(x, param)
--   loading_preset = true
--   clock.sleep(0.1)
--   params:read(x)
--   param.value = x

-- end

function set_save_paramlist(paramlist, state)
  if paramlist and #paramlist > 0  then
    for i=1,#paramlist,1
    do
      if paramlist[i] then
        params:set_save(paramlist[i],state)
      end
    end
  end
end

function pset_seq_timer_init()
  -- setup pset sequence parameters
  set_num_psets()
  params:add_separator("pset sequencer")
  params:add_option("pset_seq_enabled","pset seq enabled", {"false", "true"})
  params:add_option("pset_seq_mode","pset seq mode", {"loop", "up/down", "random"})
  params:add_number("pset_load_seq", "load pset seq", 1, get_num_psets(),1,nil, false, false)

  params:set_action("pset_load_seq", function(x) 
    if loading_preset == false then
      set_num_psets()
      local param = params:lookup_param("pset_load_seq")
      param.max = get_num_psets() 
      
      if x>param.max then 
        x = param.max 
        param.value = param.max 
      end
      params.value = x
      
      -- if params:get_allow_pmap("pset_load_seq") then
      --   param.allow_pmap = false
      -- end
      
      -- for i=1,num_psets,1
      -- do
      --   remove_psets(i)
      -- end
      params:read(x)
      param.value = x
      -- clock.run(load_params,x,param)
    end
  end )
  
  params:add_number("pset_seq_beats", "pset seq beats", 1, 16, 4)
  params:set_action("pset_seq_beats", function() 
    -- set_ticks_per_seq_cycle() 
    ticks_per_seq_cycle = clock.get_tempo() * (params:get("pset_seq_beats")/params:get("pset_seq_beats_per_bar"))
    pset_seq_ticks = 1
  end )
  params:add_number("pset_seq_beats_per_bar", "pset seq beats per bar", 1, 4, 1)
  params:set_action("pset_seq_beats_per_bar", function() set_ticks_per_seq_cycle() end )
  params:hide("pset_seq_beats_per_bar")


  -- custom exclusions set by the pset_paramset_exclusions param
  params:add{type = "option", id = "pset_paramset_exclusions", name = "exclude psets",
  options = pset_paramset_exclusions_labels, default = 4,
    action = function(x) 
      -- set all params' save settings to true
      for i=1,#pset_paramset_exclusions,1
      do
        set_save_paramlist(pset_paramset_exclusions[i], true)  
      end
      -- set excluded params' save settings to false
      if x ~= 1 then -- don't need to do this if 'none' was selected
        set_save_paramlist(pset_paramset_exclusions[x-1], false)
      end
    end
  }

  -- (default) exclude pset params from being saved
  local default_exclusions = {"pset_seq_enabled","pset_seq_mode","pset_load_seq", "pset_seq_beats","pset_seq_beats_per_bar","pset_paramset_exclusions","page_turner", "active_plant_switcher"}
  set_save_paramlist(default_exclusions, false)

  -- start pset sequence timer
  set_pset_seq_timer()
end

--------------------------
-- note:  The remove_psets function isn't needed because
--        the ParamSet:set_save function takes care of 
--        preventing a pset from being saved. 
--------------------------

--[[
local pset_path = _path.data.."flora/"
local pset_file_prefix ="flora-"

function remove_psets(pset_index)
  pset_index = pset_index < 10 and tostring("0" .. pset_index) or tostring(pset_index)
  pset_file_path = pset_path .. pset_file_prefix .. pset_index .. ".pset"
  
  new_psets = {}
  psets_to_remove = {"pset_seq_enabled","pset_seq_mode", "pset_load_seq","pset_seq_beats","pset_seq_beats_per_bar"}
  found_psets_to_remove = {}
  pset_file = io.open(pset_file_path,"r") 
  io.input(pset_file)
  while true do
    local line = io.read()
    local find_pset_to_remove
    for i=1, #psets_to_remove, 1
    do
      find_pset_to_remove = line and string.find(line,psets_to_remove[i])
      if find_pset_to_remove then break end
    end
    local found_pset_to_remove = find_pset_to_remove and find_pset_to_remove >= 1 or nil
    if found_pset_to_remove then 
      -- print("found_pset_to_remove", line) 
      table.insert(found_psets_to_remove,line)
    else
      if line then table.insert(new_psets,line) end
    end 
    if line == nil then break end
  end
  io.close(pset_file)
  
  if #found_psets_to_remove > 0 then
    new_pset_file = io.open(pset_file_path,"w+") 
    io.output(new_pset_file)
    for i=1,#new_psets,1
    do
      -- print(i,new_psets[i])
      io.write(new_psets[i] .. "\n")
    end
    io.close(new_pset_file)
  else
    -- print("no psets to remove")
  end
end
]]
