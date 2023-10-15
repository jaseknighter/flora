--- envelope with an arbitrary number of nodes
--  graphing code based on Mark Wheeler's (@markeats) code: https://github.com/monome/norns/blob/main/lua/lib/graph.lua


------------------------------
-- includes (found in includes.lua), notes, and todo list
--  includes: 
--    ArbGraph = include("lib/arbitrary_graph")
--
--  notes: 
--    about the envelope controls:
--    levels for the first and last envelope nodes always 0
--      (so level controls for these nodes are skipped)
--    the angle controls change the angle of the line connected to the prior node
--      (as a result, the first node has no angle control)
--
--  todo list: 
--    parameterize envelope settings and move default settings to globals.lua
--    fix super confusing variable nomenclature (e.g. y_max vs env_level_max)
------------------------------

local updating_envelope = false

add_nil_values_to_array = function(current_array, target_array_size)
  for i=#current_array+1,target_array_size,1
  do
    table.insert(current_array,0)
  end
  return current_array
end

local Envelope = {}
Envelope.__index = Envelope

function Envelope:new(id, env_nodes)
  local e = {}
  e.index = 1
  setmetatable(e, Envelope)
  e.id = id
    
  -- this is where we will store the graph
  e.graph = {}
  e.graph_params = {}
    
  -- set graph constants for envelopes
  -- e.level = 3 -- default amp of each envelope
  e.x_min = 0
  e.x_max = MAX_ENV_LENGTH
  e.y_min = 0
  e.y_max = MAX_AMPLITUDE
  
  e.time_incr = 1
  e.level_incr = 0.1
  e.curve_incr = 1
  
  e.env_level_min = 0.0
  e.env_level_max = AMPLITUDE_DEFAULT
  e.env_time_min = 0.01
  e.env_time_max = ENV_LENGTH_DEFAULT
  e.curve_min = CURVE_MIN
  e.curve_max = CURVE_MAX
  
  e.node_params = {"time", "level", "curve"}
  
  e.updating_graph = false
  e.DEFAULT_GRAPH_NODES = id == 1 and DEFAULT_GRAPH_NODES_P1 or DEFAULT_GRAPH_NODES_P2
  e.graph_nodes = env_nodes and env_nodes or deep_copy(e.DEFAULT_GRAPH_NODES)
  e.active_node = 0
  e.active_node_param = 1
  
  e.env_nav_active_control = 1
  
  --------------------------
  -- init
  --------------------------
  e.init = function(num_envs, show_level_time_bars)
    -- setup graph_node_params: each node_param contains an array of:
    --    graph_level: accepts e.y_min to e.y_max, defaults to 1.
    --    time: accepts e.x_min to e.x_max, defaults to 1.
    --    curve: accepts "lin", "exp" or a number where 0 is linear and positive and negative numbers curve the graph up and down, defaults to -4.
    -- setup starting point at 0, 0 
    e.graph = ArbGraph.new_graph(e.x_min, e.env_time_max, e.y_min, e.env_level_max, e.graph_nodes, show_max_levels)
    e.cursor_location_x = (e.env_time_max/e.x_max) * e.x_max
    e.cursor_location_y = (e.env_level_max/e.y_max) * e.y_max

    local graph_x = 10 + screen_size.x/num_envs*(e.id-1)
    local graph_y = 15
    local graph_width = screen_size.x/num_envs - 10
    local graph_height = 35

    e.graph:set_position_and_size(graph_x, graph_y, graph_width, graph_height)
    e.graph:set_active(false)
    e.show_level_time_bars = show_level_time_bars
  end
  
  
  e.get_num_nodes = function()
    return #e.graph_nodes
  end

  e.set_env_time = function(env_time_max)
    local old_time_max = e.env_time_max and e.env_time_max or 0.5 --0.5
    local min_time = alt_key_active and e.env_time_min or 0.25 --0.5
    e.env_time_max = util.clamp(env_time_max, min_time, e.x_max)
    for i=1, #e.graph_nodes, 1
      do
      local node_time = e.graph_nodes[i].time
      e.graph_nodes[i].time = node_time * (e.env_time_max / old_time_max)
    end
    e.graph:edit_graph(e.graph_nodes)
    e.graph:set_x_max(e.env_time_max)
    if initializing == false then 
      params:set("plow" .. active_plant .. "_max_time", e.env_time_max) 
    end
    e.update_envelope()
  end

  e.get_env_time = function()
    return e.env_time_max
  end

  e.get_env_level = function()
    return e.env_level_max
  end
  
  e.set_env_level = function(new_level)
    local old_level_max = e.env_level_max
    if new_level ~= old_level_max then
      e.env_level_max = new_level
      for i=1, #e.graph_nodes, 1
        do
        local node_level = e.graph_nodes[i].level
        e.graph_nodes[i].level = node_level * (e.env_level_max / old_level_max) < 10 and node_level * (e.env_level_max / old_level_max) or 10
      end
      e.graph:edit_graph(e.graph_nodes)
      e.graph:set_y_max(e.env_level_max)  
      if initializing == false then params:set("plow" .. active_plant .. "_max_level", e.env_level_max) end
    end
  end
  
  e.set_active = function(is_active)
    e.graph:set_active(is_active)
  end
  
  e.update_envelope = function()

    engine.set_numSegs(#e.graph_nodes)
    local env_arrays = e.get_envelope_arrays()
    -- note: to prevent warning messages when changing the number of envelope segments 
    --        (warnings like: "warning: wrong count of arguments for command 'set_env_levels'")
    --        the envelope arrays are filled in  with zeros.
    --        these zero values will be ignored by the engine
    add_nil_values_to_array(env_arrays.levels,MAX_ENVELOPE_NODES)
    add_nil_values_to_array(env_arrays.times,MAX_ENVELOPE_NODES)
    add_nil_values_to_array(env_arrays.curves,MAX_ENVELOPE_NODES)
  
    engine.set_env_levels(table.unpack(env_arrays.levels))
    engine.set_env_times(table.unpack(env_arrays.times))
    engine.set_env_curves(table.unpack(env_arrays.curves))
  end

  e.get_envelope_arrays = function ()
    local envelope = e.graph_nodes
    
    local env_data = {}
    
    env_data.segments = #envelope
    env_data.levels = {}
    env_data.times = {}
    env_data.curves = {}
    for i=1, MAX_ENVELOPE_NODES, 1
    do
      -- level array needs to be 1 less than the number of segments
      if envelope[i] and envelope[i].level then
        table.insert(env_data.levels,envelope[i].level)
      else
        table.insert(env_data.levels, nil)
      end
  
      if envelope[i] and envelope[i].time then
        table.insert(env_data.times,envelope[i].time) 
      else 
        table.insert(env_data.times, nil) 
      end 
          
      if envelope[i] and envelope[i].curve then
        table.insert(env_data.curves,envelope[i].curve)
      else
        table.insert(env_data.curves, nil)
      end
    end
    return env_data
  end
  
  e.set_active_node = function(node_num)
    e.active_node = node_num
  end
  
  e.add_node = function()
    local new_node = e.active_node + 1
    table.insert(e.graph_nodes, new_node, {})
    local new_node_time = (e.graph_nodes[new_node-1].time + e.graph_nodes[new_node+1].time)/2
    e.graph_nodes[new_node].time = new_node_time
    local new_node_level = (e.graph_nodes[new_node-1].level + e.graph_nodes[new_node+1].level)/2
    e.graph_nodes[new_node].level = new_node_level
    e.graph_nodes[new_node].curve = -4
    e.graph:add_point(e.graph_nodes[new_node].time, e.graph_nodes[new_node].level, e.graph_nodes[new_node].curve, false, new_node)
    e.graph:edit_graph(e.graph_nodes)
  end
  
  e.remove_node = function()
    if (e.active_node > 1 and e.active_node < #e.graph_nodes and #e.graph_nodes > 3) then
      table.remove(e.graph_nodes, e.active_node)
      e.graph:remove_point(e.active_node)
      e.graph:edit_graph(e.graph_nodes)
      params:set("num_plow" .. e.id .. "_controls",#e.graph_nodes)
    end
  end
  --------------------------
  -- encoders and keys
  --------------------------
  e.enc = function(n, delta)
    local graph_active_node = e.active_node
    
    -- set variables needed by each page/example
    if n == 1 then
      -- do nothing here
    elseif n == 2 then 
      if show_env_mod_params then
        e.set_env_nav_active_control(delta)
      else
        local incr = util.clamp(delta, -1, 1)
        if e.active_node_param == 4 then
          if e.env_nav_active_control == 1 and delta < 0 then
            e.active_node_param = 3
          end
          e.env_nav_active_control = e.env_nav_active_control + delta
          e.env_nav_active_control = util.clamp(e.env_nav_active_control,1,#env_mod_param_labels)
        elseif (e.active_node == 0 
          or (e.active_node == -1 and incr > 0 )
          or (e.active_node_param == 1 and incr < 0)
          or (e.active_node_param == #e.node_params and incr > 0)) then
          
          if (e.active_node + incr >= -1  
            and e.active_node + incr <= #e.graph_nodes
            ) then
            e.active_node = e.active_node + incr
            if (e.active_node_param == 1 and e.active_node == 1 and incr < 0) then
              e.active_node_param = 1
              e.active_node = 1
            elseif (e.active_node_param == 1 and incr < 0) then
              e.active_node_param = #e.node_params
            elseif (e.active_node_param == #e.node_params and incr > 0) then
              e.active_node_param = 1
            end
        end
      elseif (e.active_node_param + incr >= 0 and
        e.active_node_param + incr <= #e.node_params) then
          if (e.active_node_param == 1 and e.active_node == 1 and incr > 0) then
              e.active_node_param = 1
              e.active_node = 2
          elseif (e.active_node_param == 1 and e.active_node == #e.graph_nodes and incr > 0) then
              e.active_node_param = 3
          elseif (e.active_node_param == 3 and e.active_node == #e.graph_nodes and incr < 0) then
              e.active_node_param = 1
          else
            e.active_node_param = e.active_node_param + incr
          end
        end   
      end
    elseif n == 3 then 
      if show_env_mod_params then
        e.set_modulation_params(delta)
      else
        if (e.active_node == -1) then
          -- change the max level (amplitude) of the envelope and scale node level values accordingly
          local delta_clamp = util.clamp(delta, -1, 1)
          delta_clamp = alt_key_active and delta_clamp * 0.1 or delta_clamp
          -- local new_env_level = util.clamp(e.env_level_max + delta_clamp, 0.01, e.y_max)
          local new_env_level = util.clamp(e.env_level_max + delta_clamp, 0.01, e.y_max)
          e.set_env_level(new_env_level)
        elseif (e.active_node == 0) then
          -- change the max length of the envelope and scale node time values accordingly
          local delta_clamp = util.clamp(delta, -1, 1)
          delta_clamp = alt_key_active and delta_clamp * 0.01 or delta_clamp
          e.set_env_time(e.env_time_max + delta_clamp)
        elseif e.active_node_param == 1 then
          local delta_clamp = util.clamp(delta, -e.env_time_max, e.env_time_max)
          local incr = alt_key_active and delta_clamp * 0.01 or delta_clamp * 0.1 
          local prev_val = (e.graph_nodes[e.active_node-1] and e.graph_nodes[e.active_node-1].time) or 0
          local new_val = e.graph_nodes[e.active_node].time + incr
          local next_val = (e.graph_nodes[e.active_node+1] and e.graph_nodes[e.active_node+1].time) or e.env_time_max
          new_val = util.clamp(new_val, prev_val, next_val)
          e.graph_nodes[graph_active_node].time = new_val
          local param_id = id == 1 and plow1_times[graph_active_node] or plow2_times[graph_active_node]
          params:set(param_id,new_val)
        elseif e.active_node_param == 2 then
          if e.active_node ~= 1 and e.active_node ~= #e.graph_nodes then
            local delta_clamp = util.clamp(delta, -e.env_level_max, e.env_level_max)
            local incr = alt_key_active and delta_clamp * 0.01 or delta_clamp * 0.1 
            local new_val = e.graph_nodes[e.active_node].level + incr
            new_val = util.clamp(new_val, e.env_level_min, e.env_level_max)
            e.graph_nodes[graph_active_node].level = new_val
            local param_id = id == 1 and plow1_levels[graph_active_node] or plow2_levels[graph_active_node]
            params:set(param_id,new_val)
          end
        elseif e.active_node_param == 3 then
          local incr = alt_key_active and util.clamp(delta, -1, 1) * 0.1 or util.clamp(delta, -1, 1) * e.time_incr
          local new_val = e.graph_nodes[graph_active_node].curve + incr
          new_val = round_decimals(new_val, 2, "down")
          new_val = util.clamp(new_val, e.curve_min, e.curve_max)
          e.graph_nodes[graph_active_node].curve = new_val
          local param_id = id == 1 and plow1_curves[graph_active_node] or plow2_curves[graph_active_node]
          params:set(param_id,new_val)
        end
        e.graph:edit_graph(e.graph_nodes)
      end
    end
  end
  
  e.key = function(n, delta)
    local graph_active_node = e.active_node
    if n == 2 and e.active_node > 1 then
      e.remove_node()
    elseif n == 3 then
      --add a node to the graph
      if (alt_key_active) then
        if show_env_mod_params == true then show_env_mod_params = false else show_env_mod_params = true end
      elseif (e.active_node >= 1 and e.active_node < #e.graph_nodes and #e.graph_nodes < MAX_ENVELOPE_NODES) then
        e.add_node()
      end      
    end
  end
  

  --------------------------
  -- envelope modulation 
  --------------------------
  --note: get_control_label is called by flora_pages.lua
  e.get_control_label = function()
    local label = env_mod_param_labels[e.env_nav_active_control] .. " "
    local ac = e.env_nav_active_control
    local env_label = params:get(env_mod_param_ids[ac]..e.id)
    if ac == 1 or ac == 2 or ac == 4 or ac == 6 then
      label = label .. env_label .. "%"  
    else 
      label = label .. env_label
    end
    return label
  end
  
  e.set_modulation_probability = function(name, delta)
    
    local mod_param_name = name.. e.id
    local env_probability = params:get(mod_param_name)
    params:set(mod_param_name,env_probability+delta)
  end
  
  e.set_modulation_value = function(name, delta)
    local mod_param_name = name.. e.id
    local modulation_amount = params:get(mod_param_name)
    local param = params:lookup_param(mod_param_name)
    local min_val = param.min
    local max_val = param.max
    local increment = (max_val - min_val)/100 * delta
    params:set(mod_param_name,increment+modulation_amount)
  end
  
  e.set_env_nav_active_control = function(delta)
    e.env_nav_active_control = e.env_nav_active_control + delta
    e.env_nav_active_control = util.clamp(e.env_nav_active_control,1,#env_mod_param_labels)
  end
  
  e.set_modulation_params = function(delta)
    local id = env_mod_param_ids[e.env_nav_active_control]
    local ac = e.env_nav_active_control
    if ac == 1 or ac == 2 or ac == 4 or ac == 6 then
      e.set_modulation_probability(id, delta)
    else 
      e.set_modulation_value(id, delta)
    end
  end
  
  e.modulate_env = function()
  
    ------------------------------------
    -- envelope randomization
    ------------------------------------
    local time_probability = math.floor(params:get("time_probability"..e.id))
    local time_modulation_amount = time_probability > math.random()*100 and params:get("time_modulation"..e.id) or 0
    local level_probability = math.floor(params:get("level_probability"..e.id))
    local level_modulation_amount = level_probability > math.random()*100 and params:get("level_modulation"..e.id) or 0
    local curve_probability = math.floor(params:get("curve_probability"..e.id))
    local curve_modulation_amount = curve_probability > math.random()*100 and params:get("curve_modulation"..e.id) or 0
    local randomize_env_probability = params:get("randomize_env_probability"..e.id) 
    local randomize_envelopes = math.random()*100<randomize_env_probability
    if randomize_envelopes == true then
      local env_nodes = envelopes[e.id].graph_nodes
      for i=1,#env_nodes,1
      do
        local param_id_name, param_name, get_control_value_fn, min_val, max_val
  
        -- update times
        if i > 1 then
          param_id_name = "plow".. e.id.."_time" .. i
          param_name = "plow".. e.id.."-control" .. i .. "-time"
          local current_val = (env_nodes[1] and env_nodes[i].time) or 0
          local prev_val = (env_nodes[i-1] and env_nodes[i-1].time) or 0
          local next_val = env_nodes[i+1] and env_nodes[i+1].time or envelopes[e.id].env_time_max
          local control_range = next_val - prev_val
          local control_value = control_range*math.random(-1,1) * time_modulation_amount/10 + current_val
          control_value = util.clamp(control_value,prev_val, next_val)
          local controlspec = cs.new(prev_val,next_val,'lin',0,control_value,'')
          if env_nodes[i] then
            local param = params:lookup_param(param_id_name)
            param.controlspec = controlspec
            params:set(param.id, control_value) 
          end
        end
  
        -- update levels
        if i > 1 and i < #env_nodes then
          local current_val = (env_nodes[1] and env_nodes[i].level) or 0
          local new_value = current_val + (level_modulation_amount/10 * math.random(-1,1))
          new_value = util.clamp(new_value, 0, MAX_AMPLITUDE)
          params:set("plow".. e.id .. "_level"..i, new_value)
        end        
  
        -- update curves
        if i > 1 then
          local new_value = params:get("plow".. e.id .. "_curve"..i) + (curve_modulation_amount/10 * math.random()*math.random(-1,1)*10)
          new_value = util.clamp(new_value, -10, 10)
          params:set("plow".. e.id .. "_curve"..i, new_value)
          -- params:set("plow".. e.id .. "_curve"..i, math.random()*math.random(-10,10))
        end        
      end
    end
  end

  --------------------------
  -- modulation nav and redraw
  --------------------------
  e.draw_modulation_nav = function()
    screen.level(10)
    screen.rect(2,10, screen_size.x-2, 3)
    screen.fill()
    screen.level(0)
    local num_field_menu_areas = #env_mod_param_labels
    local area_menu_width = (screen_size.x-5)/num_field_menu_areas
    screen.rect(2+(area_menu_width*(e.env_nav_active_control-1)),10, area_menu_width, 3)
    screen.fill()
    screen.level(4)
    for i=1, num_field_menu_areas+1,1
    do
      if i < num_field_menu_areas+1 then
        screen.rect(2+(area_menu_width*(i-1)),10, 1, 3)
      else
        screen.rect(2+(area_menu_width*(i-1))-1,10, 1, 3)
      end
    end
    screen.fill()
  end

  e.redraw = function ()
    if screen_dirty == true then
      e.graph:redraw()
      local hightlight_style = "rect"
      local time_bar_percentage = e.env_time_max /e.x_max
      local level_bar_percentage = e.env_level_max / e.y_max
      if e.active_node == -1 then
        hightlight_style = "v_bar"
      elseif e.active_node == 0 then
        hightlight_style = "h_bar"
      elseif e.active_node_param == 1 then
        hightlight_style = "horizontal_lines"
      elseif e.active_node_param == 2 then
        hightlight_style = "vertical_lines"
      elseif e.active_node_param == 3 then
        hightlight_style = "top_right_corner"
      end
      e.graph:highlight(
        e.graph, 
        e.active_node,
        hightlight_style,
        time_bar_percentage,
        level_bar_percentage,
        e.show_level_time_bars
      )
      if pages.index == 4 and show_env_mod_params and active_plant == e.id then e.draw_modulation_nav() end
    end
  end
  return e
end

return Envelope
