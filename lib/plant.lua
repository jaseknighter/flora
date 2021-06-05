-- l-system execution and sound output

------------------------------
-- includes (found in includes.lua) and todo list
--
-- includes: 
--  plant_sounds = include("lib/plant_sounds") 
--  garden = include("flora/lib/garden/garden.lua")
--  l_system = include("flora/lib/l_system")
--  turtle_class = include("flora/lib/turtle")
--  matrix_stack = include("flora/lib/matrix_stack")
--  rule = include("flora/lib/rule")

-- todo list: 
--  should resetting the garden reset the plant notes to start at the root note?
--  think about renaming 'note' as 'node'
--  allow adjustment of l-system axiom/ruleset/max generations/etc. 
--  fix centering when plant is towards the bottom of the screen
--  replace 'p.sound_matrix' with 'node_matrix'
------------------------------

local center = vector:new(screen_size.x/2, screen_size.y/2)

local plant = {}
plant.__index = plant

function plant:new(p_id, starting_instruction)

  local p = {}
  p.index = 1
  setmetatable(p, plant)

  p.sounds = plant_sounds:new(p)
  p.id = p_id and p_id or 1   
  p.note_position = vector:new(-10,-10)
  p.show_note = false
  p.offset = vector:new(0,0)
  p.turtle = {}
  p.instr = {}
  
  engine.set_numSegs(5)

  p.current_instruction = starting_instruction
  p.changing_instructions = false
  p.current_sentence_id = 0
  p.initializing = true
  p.play_turtle = true
  p.sound_matrix = matrix_stack:new()
  p.sentence_cursor_index = 1
  p.selected_letter = nil
  p.restart_rendering = false
  screen.line_width(1)
  p.current_generation = 0
  p.ruleset = {}
  p.initial_turtle_rotation = 90




  p.update_ruleset = function(ruleset_id, predecessor, successor)
    p.lsys.set_ruleset(ruleset_id, predecessor, successor)
    -- p.setup(p.current_instruction)
    p.changing_instructions = true
    -- p.change_instructions(p.current_instruction)  
  end
  
  p.update_axiom = function(new_axiom)
    p.instr[p.get_current_instruction()].axiom = new_axiom
    p.lsys.set_axiom(new_axiom) 
  end
  
  p.get_sentence = function()
    local sentence = p.lsys.get_sentence()
    return sentence
  end

  p.set_sentence = function(new_sentence)
    p.sentence = p.lsys.set_sentence(new_sentence)
    p.turtle.set_todo(p.sentence)
    -- local plant_sentence_param = "plant".. p.id .. "_sentence"
    -- params:set(plant_sentence_param,new_sentence)
  end
  
  p.set_current_page = function(idx)
    p.index = idx  
  end
  
  p.set_active = function(active)
    p.active = active == true and true or false
    set_midi_channels()
  end
  
  p.get_active = function()
    return p.active
  end
  
  p.reset_offset = function()
    p.offset = (vector:new(0,0))  
  end
  
  p.get_offset = function()
    return p.offset
  end
  
  p.set_offset = function(x,y)
    p.offset:add(vector:new(x,y))  
  end

  p.get_turtle_positions = function()
    return p.turtle.get_positions()
  end
  
  p.set_angle = function(angle_delta, set_from_param)
    p.instr[p.get_current_instruction()].angle = p.instr[p.get_current_instruction()].angle + angle_delta
    p.turtle.theta = math.rad(p.instr[p.get_current_instruction()].angle)
    local p_angle = p.id == 1 and "plant1_angle" or "plant2_angle"
    if set_from_param ~= true then params:set(p_angle, p.instr[p.get_current_instruction()].angle) end
      
  end

  p.get_angle = function()
    return p.instr[p.get_current_instruction()].angle
  end
  
  
  ----------------------------
  -- start music stuff
  ----------------------------
  
  p.set_note_scalar = function(x)
    p.sounds.set_note_scalar(x)
  end

  -- call start_playing whenever a new plant is selected
  p.start_playing = function()
    if (p.initializing == false) then
      -- fs.set_note(last_index, last_note, last_s_id)
      p.sounds.set_note()
    end
  end
  
  ----------------------------
  -- end music stuff
  ----------------------------
  
  local node_length
  
  -- set the node length by given percentage
  p.set_node_length = function(node_length_pct)
    p.turtle.change_length(turtle_min_length, node_length_pct)
  end
  
  p.get_current_instruction = function()
    return p.current_instruction
  end
  
  p.get_instructions = function(instruction_number)
    if p.instr[instruction_number] then
      return p.instr[instruction_number]
    else 
      return garden.get_instruction(instruction_number)
    end
  end 
  
  p.get_num_rulesets = function()
    if p.lsys then return p.lsys.get_num_rulesets() end
  end

  p.set_num_rulesets = function(incr)
    p.lsys.set_num_rulesets(incr)
  end
  
  p.get_predecessor = function(ruleset_id)
    return p.lsys.get_predecessor(ruleset_id)
  end
  
  p.get_successor = function(ruleset_id)
    return p.lsys.get_successor(ruleset_id)
  end
  
  p.get_axiom = function()
    return p.lsys.get_axiom()
  end

  p.get_max_generations = function()
    return p.max_generations
  end
  
  p.set_max_generations = function(incr)
    if p.max_generations + incr > 0 and p.max_generations + incr >= p.current_generation then
      p.max_generations = p.max_generations + incr
      p.instr[p.get_current_instruction()].max_generations = p.max_generations
    end
  end
  
  p.get_init_length = function()
    return p.instr[p.get_current_instruction()].length
    -- return p.length
  end

  p.set_init_length = function(incr)
    local new_val = p.instr[p.get_current_instruction()].length + incr
    if new_val > 0 then
      p.instr[p.get_current_instruction()].length = new_val
    end
  end


  p.get_starting_gen = function(incr)
    return p.starting_generation
  end

  p.set_starting_gen = function(incr)
    local new_val = p.instr[p.get_current_instruction()].starting_generation + incr
    if new_val > 0 and new_val <= p.instr[p.get_current_instruction()].max_generations then
      p.instr[p.get_current_instruction()].starting_generation = new_val      
      p.starting_generation = new_val
    end
  end


  p.get_init_angle = function()
    -- p.initial_turtle_rotation = p.instr[instruction_number].initial_turtle_rotation
    return p.instr[p.get_current_instruction()].initial_turtle_rotation
  end

  p.set_init_angle = function(incr)
    local new_angle = p.instr[p.get_current_instruction()].initial_turtle_rotation + incr
    p.instr[p.get_current_instruction()].initial_turtle_rotation = new_angle
  end
  
  p.get_start_from_x = function()
    return p.start_from.x
  end

  p.set_start_from_x = function(incr)
    p.instr[p.get_current_instruction()].start_from.x = p.instr[p.get_current_instruction()].start_from.x + incr
  end

  p.get_start_from_y = function()
    return p.start_from.y
  end

  p.set_start_from_y = function(incr)
    p.instr[p.get_current_instruction()].start_from.y = p.instr[p.get_current_instruction()].start_from.y + incr
  end
  
  p.get_current_generation = function()
    return p.current_generation
  end
  
  p.setup = function(instruction_number, target_generation)
    initializing = true
    p.initializing = true
    p.current_instruction = instruction_number
    p.current_generation = 0
    p.instr[instruction_number] = p.get_instructions(instruction_number)
    -- print(">>>>>>>>>>")
    -- tab.print(p.instr[instruction_number])
    -- print(">>>>>>>>>>")
    if p.id == 1 then
      p.start_from = vector:new(
        p.instr[instruction_number].start_from.x - screen_size.x/4, 
        p.instr[instruction_number].start_from.y
      )
    else
      p.start_from = vector:new(
        p.instr[instruction_number].start_from.x + screen_size.x/4, 
        p.instr[instruction_number].start_from.y
      )
    end

    p.start_from:add(p.offset)
    p.ruleset = p.instr[instruction_number].ruleset
    p.axiom = p.instr[instruction_number].axiom
    p.max_generations = p.instr[instruction_number].max_generations
    p.length = p.instr[instruction_number].length

    local p_instr_num = p.id == 1 and "plant1_instructions" or "plant2_instructions"
    local p_angle = p.id == 1 and "plant1_angle" or "plant2_angle"

    params:set(p_instr_num, instruction_number)

    params:set(p_angle, p.instr[instruction_number].angle)
    
    p.initial_turtle_rotation = p.instr[instruction_number].initial_turtle_rotation
    target_generation = target_generation and target_generation or p.instr[instruction_number].starting_generation
    p.starting_generation = target_generation
    p.lsys = l_system:new(p.axiom,p.ruleset)
    
    p.sentence = p.get_sentence()
    p.turtle = turtle_class:new(
      p.sentence, 
      p.length or 35, 
      math.rad(p.instr[instruction_number].angle or 0))
    
    if (target_generation) then
      for i=1, target_generation, 1
        do
          p.generate(target_generation)
      end
    end
    
    p.initializing = false
    initializing = false
  end    
  
  p.generate = function(dir)
    local direction
    if (dir == -1 or dir == 1) then
      direction = dir 
    else 
      direction = 1
    end
    
    if (p.current_generation >= 0 and p.current_generation < p.max_generations) then
      p.turtle.push()
      local previous_sentence = p.get_sentence()
      p.turtle.set_previous_todo(previous_sentence)
      p.lsys.generate(direction)
      local new_sentence = p.get_sentence()
      p.turtle.set_todo(new_sentence)
      p.turtle.pop()
      p.current_generation = p.current_generation + direction
      p.restart_rendering = true
    end
  end
  
  -- local render_percentage_completed = 0
  -- local show_petal = false
  -- local check_petal = 0
  
  p.reset_instructions = function()
    p.sentence_cursor_index = 1
    if (p.initializing == false and p.changing_instructions == false) then
      p.changing_instructions = true
      p.change_instructions(1)  
      p.reset_offset()
    end
  end 
  
  p.set_instructions = function(rotate_by, increment_generation_by)
    local increment_generation_by = increment_generation_by and increment_generation_by or 0
    p.sentence_cursor_index = 1
    local num_instructions = garden.get_num_plants()
    local next_instruction = p.current_instruction + rotate_by
    local next_generation = p.current_generation + increment_generation_by
    if (next_generation > 0 and 
        next_generation <= p.max_generations and 
        next_instruction > 0 and 
        next_instruction <= num_instructions) then
      if (p.initializing == false and p.changing_instructions == false) then
        p.changing_instructions = true
        local target_generation = increment_generation_by ~= 0 and p.current_generation + increment_generation_by or 0
        target_generation = target_generation > 0 and target_generation or nil
        p.change_instructions(next_instruction, target_generation)  
        p.reset_offset()
      end
    end
  end 
  
  p.change_instructions = function(next_instruction, target_generation)
    -- clock.sleep(0.1)
    if (p.initializing == false) then
      print("CI", next_instruction, target_generation)
      p.setup(next_instruction, target_generation)
      p.play_turtle = true
      modify.reset()
    else
      p.change_instructions(next_instruction)  
    end
  end
  
  p.get_plant_info = function()
    local plant_info = ("i".. p.current_instruction ..
          " g" .. p.current_generation ..
          "/" .. p.instr[p.get_current_instruction()].max_generations ..
          " a".. math.ceil(math.deg(p.turtle.theta)) .. "°(" .. round_decimals(p.turtle.theta,3,"up") .. "r)")
    return plant_info
  end

  p.clip_offset = 0

  p.get_instructions_to_display = function(clip_length)
    p.sentence = p.get_sentence()
    local letters_left_of_cursor = string_cut(p.sentence, 1, p.sentence_cursor_index-1)
    p.selected_letter = string_cut(p.sentence, p.sentence_cursor_index, p.sentence_cursor_index)
    local letter_location = {}
    letter_location.x, letter_location.y = screen.text_extents(letters_left_of_cursor)
    local letter_offset = letter_location.x
    p.clip_offset = p.sentence_cursor_index > max_visible_chars and p.sentence_cursor_index - max_visible_chars or 0
    local clipped_sentence = string_cut(p.sentence, 1 + p.clip_offset, max_visible_chars + p.clip_offset)
    local clipped_sentence_len = screen.text_extents(clipped_sentence)
    local last_letter = string_cut(clipped_sentence,#clipped_sentence,#clipped_sentence)
    local last_letter_len = screen.text_extents(last_letter)
    local cursor_location_x = letter_offset < clipped_sentence_len and letter_offset or clipped_sentence_len - last_letter_len
    
    return {
      clipped_sentence,
      cursor_location_x
    }
  end

  p.redraw_fn = function ()
    -- local time1 = os.clock() * 1000
    if (p.restart_rendering) then 
      p.turtle.rotate(0, true)
      p.turtle.translate(p.start_from.x + p.offset.x, p.start_from.y + p.offset.y)
      p.turtle.rotate(math.rad(p.initial_turtle_rotation))
      p.turtle_data = p.turtle.render(p.restart_rendering)
      if (p.turtle_data) then
        render_percentage_completed = p.turtle_data.render_percentage_completed
      end
      
      if (p.initializing == false) then
        p.restart_rendering = true
        if (p.play_turtle) then
          p.start_playing()
        end
        p.play_turtle = false
      end
    end
  end
  return p
end

return plant
