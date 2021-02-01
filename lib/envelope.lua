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
--    fix confusing variable nomenclature (e.g. y_max vs env_level_max)
------------------------------

local updating_envelope = false

local add_nil_values_to_array = function(current_array, target_array_size)
  for i=#current_array+1,target_array_size,1
  do
    table.insert(current_array,0)
  end
  return current_array
end

local Envelope = {}
Envelope.__index = Envelope

function Envelope:new(id, num_plants, env_nodes)
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
  e.env_time_max = ENV_TIME_MAX
  e.curve_min = CURVE_MIN
  e.curve_max = CURVE_MAX
  
  e.node_params = {"time", "level", "curve"}
  
  e.updating_graph = false

  local default_graph_nodes = {}
  default_graph_nodes[1] = {}
  default_graph_nodes[1].time = 0.00
  default_graph_nodes[1].level = 0.00
  default_graph_nodes[1].curve = 0.00
  default_graph_nodes[2] = {}
  default_graph_nodes[2].time = 0.00
  default_graph_nodes[2].level = 1.0
  default_graph_nodes[2].curve = -10
  default_graph_nodes[3] = {}
  default_graph_nodes[3].time = 0.50
  default_graph_nodes[3].level = 0.50
  default_graph_nodes[3].curve = -10
  default_graph_nodes[4] = {}
  default_graph_nodes[4].time = 1.00
  default_graph_nodes[4].level = 1.5
  default_graph_nodes[4].curve = -10
  default_graph_nodes[5] = {}
  default_graph_nodes[5].time = 1.5
  default_graph_nodes[5].level = 0.00
  default_graph_nodes[5].curve = -10
  
  e.graph_nodes = env_nodes and env_nodes or default_graph_nodes
  e.active_node = 0
  e.active_node_param = 1
  
  e.update_engine = function()
    if (updating_envelope == false) then
      updating_envelope = true
      -- clock.sync(1)
      clock.sync(0.05)
      envelopes[active_plant].update_envelope()
      updating_envelope = false
    end
  end

  --------------------------
  -- init
  --------------------------
  e.init = function(num_plants)
    -- setup graph_node_params: each node_param contains an array of:
    --    graph_level: accepts e.y_min to e.y_max, defaults to 1.
    --    time: accepts e.x_min to e.x_max, defaults to 1.
    --    curve: accepts "lin", "exp" or a number where 0 is linear and positive and negative numbers curve the graph up and down, defaults to -4.
    -- setup starting point at 0, 0 

    e.graph = ArbGraph.new_graph(e.x_min, e.env_time_max, e.y_min, e.env_level_max, e.graph_nodes)
    e.cursor_location_x = (e.env_time_max/e.x_max) * e.x_max
    e.cursor_location_y = (e.env_level_max/e.y_max) * e.y_max

    local graph_x = 10 + screen_size.x/num_plants*(e.id-1)
    local graph_y = 15
    local graph_width = screen_size.x/num_plants - 10
    local graph_height = 35

    e.graph:set_position_and_size(graph_x, graph_y, graph_width, graph_height)
    e.graph:set_active(false)
    
    -- for some reason this a default env length needs to be set here at the end of init
    e.set_env_time(ENV_LENGTH_DEFAULT)
  end
  
  e.get_env_time = function()
    return e.env_time_max
  end

  e.set_env_time = function(env_time_max)
    -- e.env_time_max = env_time
    local old_time_max = e.env_time_max and e.env_time_max or 0.01 --0.5
    local min_time = alt_key_active and e.env_time_min or 0.01 --0.5
    e.env_time_max = util.clamp(env_time_max, min_time, e.x_max)
    for i=1, #e.graph_nodes, 1
      do
      local node_time = e.graph_nodes[i].time
      e.graph_nodes[i].time = node_time * (e.env_time_max / old_time_max)
    end
    e.graph:edit_graph(e.graph_nodes)
    e.graph:set_x_max(e.env_time_max)
  end

  e.get_env_level = function()
    return e.env_level_max
  end
  
  e.get_env_max_level = function()
    return e.x_max
  end

  e.set_env_max_level = function(new_level)
    local old_level_max = e.env_level_max
    e.env_level_max = new_level
    for i=1, #e.graph_nodes, 1
      do
      local node_level = e.graph_nodes[i].level
      e.graph_nodes[i].level = node_level * (e.env_level_max / old_level_max)
    end
    e.graph:edit_graph(e.graph_nodes)
    e.graph:set_y_max(e.env_level_max)  
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
    clock.run(set_dirty)

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
  --------------------------
  -- encoders and keys
  --------------------------
  e.enc = function(n, delta, alt_key_active)
    local graph_active_node = e.active_node
    
    -- set variables needed by each page/example
    if n == 1 then
      -- do nothing here
    elseif n == 2 then 
      local incr = util.clamp(delta, -1, 1)
      if (e.active_node == 0 
        or (e.active_node == -1 and incr > 0 )
        or (e.active_node_param == 1 and incr < 0)
        or (e.active_node_param == #e.node_params and incr > 0)) then
        if (e.active_node + incr >= -1  
          and e.active_node + incr <= #e.graph_nodes) then
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
    elseif n == 3 then 
      if (e.active_node == -1) then
        -- change the max level (amplitude) of the envelope and scale node level values accordingly
        local delta_clamp = util.clamp(delta, -1, 1)
        delta_clamp = alt_key_active and delta_clamp * 0.1 or delta_clamp
        local new_env_level_max = util.clamp(e.env_level_max + delta_clamp, 0.01, e.y_max)
        e.set_env_max_level(new_env_level_max)
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
      
      clock.run(e.update_engine, e.graph_nodes)
    end
  end
  
  e.key = function(n, delta, alt_key_active)
    local graph_active_node = e.active_node
    if n == 2 and e.active_node > 1 then
      --remove a node to the graph
      if (e.active_node > 1 and e.active_node < #e.graph_nodes and #e.graph_nodes > 3) then
        table.remove(e.graph_nodes, e.active_node)
        if id == 1 then
          params:set("num_plow1_controls",#e.graph_nodes)
        else
          params:set("num_plow2_controls",#e.graph_nodes)
        end

        e.graph:remove_point(e.active_node)
        
        e.graph:edit_graph(e.graph_nodes)
        -- clock.run(e.update_engine, e.graph_nodes)
      end
    elseif n == 3 and e.active_node >= 1 then
      --add a node to the graph
      if (alt_key_active) then
        -- randomize graph code needs some work
        --[[
        local nodes = e.graph_nodes
        for i=2, #nodes, 1
        do
          local time = i > 1
            and 
              math.random() * 
              e.x_max / 
              (#nodes-2) + 
              nodes[i-1].time 
            or 0
          nodes[i].time = time
          
          local level = (i > 1 and i < #nodes) and math.random() or 0
          nodes[i].level = level
          nodes[i].curve = math.random()*(e.x_max*2) - e.x_max
        end
        e.graph:edit_graph(e.graph_nodes)
        ]]
      elseif (e.active_node < #e.graph_nodes and #e.graph_nodes < MAX_ENVELOPE_NODES) then
        local new_node = e.active_node + 1
        table.insert(e.graph_nodes, new_node, {})
        if id == 1 then
          params:set("num_plow1_controls",#e.graph_nodes)
        else
          params:set("num_plow2_controls",#e.graph_nodes)
        end
        local new_node_time = (e.graph_nodes[new_node-1].time + e.graph_nodes[new_node+1].time)/2
        e.graph_nodes[new_node].time = new_node_time
        e.graph_nodes[new_node].level = 0.5
        e.graph_nodes[new_node].curve = -4
        e.graph:add_point(e.graph_nodes[new_node].time, e.graph_nodes[new_node].level, e.graph_nodes[new_node].curve, false, new_node)
      end      
      e.graph:edit_graph(e.graph_nodes)

    end
  end
  
  --------------------------
  -- redraw
  --------------------------
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
        level_bar_percentage
      )
    end
  end
  return e
end

return Envelope