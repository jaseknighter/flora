-- code to draw the pages (screens)

------------------------------
-- todo list
--  improve check_plant_position code 
--    (e.g. fit plants to fill up allocated screen space more precisely)
--------------------------

function check_plant_position()
  for i=1,#plants,1
  do
    local turtle_positions = plants[i].get_turtle_positions()
    local left_edge = 40 + ((screen_size.x/#plants) * (i-1))
    local right_edge = (screen_size.x / (#plants/i)) - 20
    local top_edge = 15
    local bottom_edge = screen_size.y - 5
    local center_point_x = (right_edge - left_edge)/2
    local center_point_y = (bottom_edge - top_edge)/2
    local center_point = vector:new(center_point_x,center_point_y)
    local leftmost_point, rightmost_point, topmost_point, bottommost_point
    
    for j=1, #turtle_positions,1
    do
      if (leftmost_point == nil and turtle_positions[j].x) then
        leftmost_point = turtle_positions[j].x
        rightmost_point = turtle_positions[j].x
        topmost_point = turtle_positions[j].y
        bottommost_point = turtle_positions[j].y
      end

      if (leftmost_point and turtle_positions[j].x) then
        if (turtle_positions[j].x < leftmost_point) then
          leftmost_point = turtle_positions[j].x
        end
        if (turtle_positions[j].x > rightmost_point) then
          rightmost_point = turtle_positions[j].x
        end
        if (turtle_positions[j].y < topmost_point) then
          topmost_point = turtle_positions[j].y
        end
        if (turtle_positions[j].y > bottommost_point) then
          bottommost_point = turtle_positions[j].y
        end
      end
    end
      
      if (leftmost_point) then
        local plant_width = rightmost_point - leftmost_point
        local plant_height = bottommost_point - topmost_point
        
        if plant_width > screen_size.x/#plants+15 or plant_height > screen_size.y - 30 then
          screen_dirty = true
          plants[i].set_node_length(0.9)
        end
        -- if plant_width < screen_size.x/10 or plant_height < screen_size.y/11 then
        --   screen_dirty = true
        --   plants[i].set_node_length(1.1)
        -- end
        if (plant_width < screen_size.x/#plants-25 and plant_height < screen_size.y-45) then
          screen_dirty = true
          plants[i].set_node_length(1.1)
        end
        if (leftmost_point < left_edge) then
          screen_dirty = true
          plants[i].set_offset(0.5, 0)
        end 
        if topmost_point+3 < top_edge  then
          screen_dirty = true
          plants[i].set_offset(0, 0.5)
        end
        if rightmost_point > right_edge then
          screen_dirty = true
          plants[i].set_offset(-0.5, 0)
        end
        if bottommost_point+3 > bottom_edge then
          screen_dirty = true
          plants[i].set_offset(0, -0.5)
        end
    end
  end
end

local draw_plants = function()
  local plant1_randomized = string.find(plants[1].sentence, "r")
  local plant2_randomized = string.find(plants[2].sentence, "r")
  if notes_only ~= true or plant1_randomized or plant2_randomized then
    screen.clear() 
    screen.level(plant1_screen_level)
    plants[1].redraw_fn()
    screen.level(plant2_screen_level)
    plants[2].redraw_fn()
  end  
end

local draw_notes_on_plants = function()
  local max_env_level = envelopes[1].get_env_max_level()
  local env_level1 = envelopes[1].get_env_level()
  local note_brightness1 = util.linlin (0, max_env_level, 10, 15, env_level1)
  note_brightness1 = math.floor(note_brightness1)
  
  local env_level2 = envelopes[2].get_env_level()
  local note_brightness2 = util.linlin (0, max_env_level, 10, 15, env_level2)
  note_brightness2 = math.floor(note_brightness2)
  
  local get_turtle_position = function(plant_id)
    local current_note_index = current_note_indices[plant_id]
    local turtle_pos = plants[plant_id].turtle.get_position(current_note_index)
    return turtle_pos
  end

  local set_previous_turtle_position = function(plant_id, turtle_position)
    plants[plant_id].note_position_previous = vector:new(turtle_position.x, turtle_position.y)
  end
  
  local get_previous_turtle_position = function(plant_id)
      return plants[plant_id].note_position_previous
  end
  
  if plants[1].show_note and env_level1 > 0.1 then
    local turtle_pos = get_turtle_position(1)
    local prev_turtle_pos = get_previous_turtle_position(1)
    -- clear the previous note highlight if it exists
    if prev_turtle_pos and prev_turtle_pos.x  then
      screen.level(plant1_screen_level)
      screen.move(prev_turtle_pos.x, prev_turtle_pos.y)
      screen.circle(prev_turtle_pos.x, prev_turtle_pos.y,1)
      screen.stroke()
      screen.update()
      screen.level(math.floor(note_brightness1))
    end
    
    -- highlight the current note 
    if turtle_pos and turtle_pos.x  then
      set_previous_turtle_position(1, turtle_pos)
      screen.level(math.floor(note_brightness1))
      screen.move(turtle_pos.x, turtle_pos.y)
      screen.circle(turtle_pos.x, turtle_pos.y,1)
      screen.stroke()
    end 
  end
  if plants[2].show_note and env_level2 > 0.1 then
    local turtle_pos = get_turtle_position(2)
    local prev_turtle_pos = get_previous_turtle_position(2)
    -- clear the previous note highlight if it exists
    if prev_turtle_pos and prev_turtle_pos.x  then
      screen.level(plant2_screen_level)
      screen.move(prev_turtle_pos.x, prev_turtle_pos.y)
      screen.circle(prev_turtle_pos.x, prev_turtle_pos.y,1)
      screen.stroke()
      screen.update()
      screen.level(math.floor(note_brightness2))
    end
    
    -- highlight the current note 
    if turtle_pos and turtle_pos.x  then
      set_previous_turtle_position(2, turtle_pos)
      screen.level(math.floor(note_brightness2))
      screen.move(turtle_pos.x, turtle_pos.y)
      screen.circle(turtle_pos.x, turtle_pos.y,1)
      screen.stroke()
    end 
  end  
end

local draw_top_nav = function()
  screen.level(15)
  screen.stroke()
  screen.rect(0,0,screen_size.x,10)
  screen.fill()
  screen.level(0)
  screen.move(4,7)

  if pages.index == 1 then
    local plant_info = show_instructions == true and "instructions" or plants[active_plant].get_plant_info()
    screen.text("plant " .. plant_info)
  elseif pages.index == 2 then
    local instruction_details = plants[active_plant].get_instructions_to_display()
    local instructions = show_instructions == true and "instructions" or instruction_details[1]
    local cursor_location = instruction_details[2]
    cursor_location = cursor_location - screen.text_extents(instructions) - 1
    screen.text("modify " .. instructions)
    if show_instructions == false then
      screen.move_rel(cursor_location , 2)
      screen.text('_')
    end
  elseif pages.index == 3 then
    if show_instructions == true then
      screen.text("observe instructions")
    else 
      screen.text("observe")
    end
  elseif pages.index == 4 then
    local graph_active_node = envelopes[active_plant].active_node
    local graph_node_text = ''
    if graph_active_node == -1 then 
      local env_level_text = envelopes[active_plant].get_env_level() 
      local mult = 10^2
      env_level_text = math.floor(env_level_text * mult + 0.5) / mult
      graph_node_text = 'env level ' .. env_level_text
    elseif graph_active_node == 0 then 
      graph_node_text = 'env length ' .. envelopes[active_plant].get_env_time() .. 's'
    else
      graph_node_text =  'node ' .. graph_active_node .. ': '
      if envelopes[active_plant].active_node_param == 1 then
        graph_node_text = graph_node_text.. ' time ' .. envelopes[active_plant].graph_nodes[graph_active_node].time .. 's'
      elseif envelopes[active_plant].active_node_param == 2 then
        local level = envelopes[active_plant].graph_nodes[graph_active_node].level 
        graph_node_text = graph_node_text.. ' level ' .. level
      elseif envelopes[active_plant].active_node_param == 3 then
        local curve = envelopes[active_plant].graph_nodes[graph_active_node].curve .. '°'
        graph_node_text = graph_node_text.. ' curve ' .. curve
      end
    end 
    graph_node_text = show_instructions == true and "instructions" or graph_node_text
    screen.text("plow " .. graph_node_text)
  elseif pages.index == 5 then
    if show_instructions == true then
      screen.text("water instructions")
    elseif menu_status == false then 
      local label_obj = water.get_control_label()
      label = "water " .. label_obj[1]
      screen.text(label)
      
      -- show note frequency info if there is data for label_obj[2] 
      if label_obj[2] then
        local open_bracket_loc = string.find(label, "%[")
        local backslash_loc = string.find(label, "%/")
        backslash_loc = string.find(label, "%/", backslash_loc)
        local open_paren_loc = string.find(label, "%(")
        local close_paren_loc = string.find(label, "%)")
        local plus_min_loc = string.find(label, "+")
        plus_min_loc = plus_min_loc ~= nil and plus_min_loc or string.find(label, "-")
        local star_loc = string.find(label, "*")
        local cursor_start, cursor_width
        local letters_left_of_cursor
        if label_obj[2] == 1 then
          cursor_start = string_cut(label, 1, open_bracket_loc+1)
          cursor_start_x = screen.text_extents(cursor_start)
          cursor_end_x = string_cut(label, 1, backslash_loc) 
          cursor_width = screen.text_extents(cursor_end_x)  - cursor_start_x
          screen.move(cursor_start_x,9)
          screen.line_rel(cursor_width,0)
        elseif label_obj[2] == 2 then
          cursor_start = string_cut(label, 1, open_paren_loc+1)
          cursor_start_x = screen.text_extents(cursor_start)
          cursor_end_x = string_cut(label, 1, plus_min_loc) 
          cursor_width = screen.text_extents(cursor_end_x)  - cursor_start_x
          screen.move(cursor_start_x,9)
          screen.line_rel(cursor_width+2,0)
        elseif label_obj[2] == 3 then
          cursor_start = string_cut(label, 1, plus_min_loc+1)
          cursor_start_x = screen.text_extents(cursor_start)
          cursor_end_x = string_cut(label, 1, close_paren_loc) 
          cursor_width = screen.text_extents(cursor_end_x)  - cursor_start_x
          screen.move(cursor_start_x,9)
          screen.line_rel(cursor_width+2,0)
        end
        screen.stroke()
      end
      water.draw_water_nav()
      water.redraw()
      
    end
  end
  -- navigation marks
  screen.level(0)
  screen.rect(0,(pages.index-1)/5*10,2,2)
  screen.fill()
  screen.update()
end

local draw_pages = function(notes_only)
  if initializing == false then
    if show_instructions == true then 
      screen.clear()
      instructions.display() 
    else
      if pages.index < 4 then
        if pages.index < 3 then check_plant_position() end
        draw_plants()
        draw_notes_on_plants()    
      elseif pages.index == 4 then
        screen.level(5)
        for i=1,num_plants,1
        do
          envelopes[i]:redraw()
        end
      elseif pages.index == 5 then
        water.display()
      end
      draw_top_nav()
    end
  end
end

return {
  draw_pages = draw_pages
}