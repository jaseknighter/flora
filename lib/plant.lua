-- l-system execution and sound output

------------------------------
-- includes (found in includes.lua) and todo list
--
-- includes: 
--  plant_sounds = include("lib/plant_sounds") 
--  l_system_instructions = include("flora/lib/garden/garden_default.lua")
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
local alphabet = {'F','G','[',']','+','-','|', 'r'}
local max_visible_chars = 22

local get_alphabet_index = function (letter)
  for i=1, #alphabet, 1
  do
    if alphabet[i] == letter then
      return i
    end
  end
end

local table_from_sentence = function(s)
  local s_table={}
  s:gsub(".",function(c) table.insert(s_table,c) end)
  return s_table
end

local sentence_from_table = function(t)
  local new_sentence = ''
  for i=1, #t, 1
  do
    new_sentence = new_sentence .. t[i]
  end
  return new_sentence
end

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
  
  local turtle_data
  local turtle_min_length = 0.2

  engine.set_numSegs(5)

  p.current_instruction = starting_instruction
  
  p.changing_instructions = false
  p.current_sentence_id = 0
  p.initializing = true
  
  
  p.play_turtle = true
  p.sound_matrix = matrix_stack:new()
  p.sentence_cursor_index = 1
  p.selected_letter = nil

  p.set_current_page = function(idx)
    p.index = idx  
  end
  
  p.set_active = function(active)
    p.active = active == true and true or false
  end
  
  p.get_active = function()
    return p.active
  end
  
  p.set_offset = function(x,y)
    p.offset:add(vector:new(x,y))  
  end
  
  p.reset_offset = function()
    p.offset = (vector:new(0,0))  
  end
  
  p.get_offset = function()
    return p.offset
  end
  
  p.get_turtle_positions = function()
    return p.turtle.get_positions()
  end
  
  p.set_angle = function(angle_delta)
    p.angle = p.angle + angle_delta
    p.turtle.theta = math.rad(p.angle)
  end
  
  p.increment_sentence_cursor = function(incr)
    local new_index = p.sentence_cursor_index + incr
    if new_index < 1 then 
      p.sentence_cursor_index = 1
    elseif new_index <= #p.sentence then
      p.sentence_cursor_index = p.sentence_cursor_index + incr
    end
  end

  p.change_letter = function(delta)
    local sentence_table = table_from_sentence(p.sentence)
    local current_letter = sentence_table[p.sentence_cursor_index]
    local current_letter_index = get_alphabet_index(current_letter)
    local new_letter_index = nil
    if current_letter_index + delta < 1 then
      new_letter_index = #alphabet
    elseif current_letter_index + delta > #alphabet then
      new_letter_index = 1
    else 
      new_letter_index = current_letter_index + delta
    end
    local new_letter = alphabet[new_letter_index]
    table.remove(sentence_table, p.sentence_cursor_index)
    table.insert(sentence_table, p.sentence_cursor_index, new_letter)
    local new_sentence = sentence_from_table(sentence_table)
    p.lsys.set_sentence(new_sentence)
    p.sentence = p.lsys.get_sentence()
    p.turtle.set_todo(p.sentence)
  end
  
  p.add_letter = function(idx)
    local sentence_table = table_from_sentence(p.lsys.get_sentence())
    table.insert(sentence_table,p.sentence_cursor_index, alphabet[1])
    local new_sentence = sentence_from_table(sentence_table)
    p.lsys.set_sentence(new_sentence)
    p.sentence = p.lsys.get_sentence()
    p.turtle.set_todo(p.sentence)
    p.changing_instructions = true
  end

  p.remove_letter = function()
    local sentence_table = table_from_sentence(p.lsys.get_sentence())
    table.remove(sentence_table,p.sentence_cursor_index)
    local new_sentence = sentence_from_table(sentence_table)
    p.lsys.set_sentence(new_sentence)
    p.sentence = p.lsys.get_sentence()
    p.turtle.set_todo(p.sentence)
    p.changing_instructions = true
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
  
  p.get_instructions = function(instruction_number)
    return l_system_instructions.get_instruction(instruction_number)
  end 
  
  p.run_plant_code = function()
    local restart_rendering = false
    screen.line_width(1)
    p.current_generation = 0
    local ruleset = {}
    local axiom
    local initial_turtle_rotation = 90
    
    p.setup = function(instruction_number, target_generation)
      p.initializing = true
      p.current_generation = 0
      p.instr = p.get_instructions(instruction_number)

      if p.id == 1 then
        p.start_from = vector:new(
          p.instr.start_from.x - screen_size.x/4, 
          p.instr.start_from.y
        )
      else
        p.start_from = vector:new(
        p.instr.start_from.x + screen_size.x/4, 
        p.instr.start_from.y)
      end
      p.start_from:add(p.offset)
      ruleset = p.instr.ruleset
      axiom = p.instr.axiom
      p.max_generations = p.instr.max_generations
      p.length = p.instr.length
      p.angle = target_generation == nil and p.instr.angle or p.angle
      initial_turtle_rotation = p.instr.initial_turtle_rotation
      target_generation = target_generation and target_generation or p.instr.starting_generation

      p.lsys = l_system:new(axiom,ruleset)
      p.sentence = p.lsys.get_sentence()
      p.turtle = turtle_class:new(
        p.sentence, 
        p.length or 35, 
        math.rad(p.angle or 0))
      if (target_generation) then
        for i=1, target_generation, 1
          do
            p.generate(target_generation)
        end
      end
      
      p.initializing = false
      p.current_instruction = instruction_number
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
        local previous_sentence = p.lsys.get_sentence()
        p.turtle.set_previous_todo(previous_sentence)
        p.lsys.generate(direction)
        local new_sentence = p.lsys.get_sentence()
        p.turtle.set_todo(new_sentence)
        p.turtle.pop()
        p.current_generation = p.current_generation + direction
        restart_rendering = true
      end
    end
    
    p.setup(p.current_instruction)
    local render_percentage_completed = 0
    local show_petal = false
    local check_petal = 0
    
    p.reset_instructions = function()
      p.sentence_cursor_index = 1
      if (p.initializing == false and p.changing_instructions == false) then
        p.changing_instructions = true
        clock.run(p.change_instructions, 1)  
        p.reset_offset()
      end
    end 
    
    p.set_instructions = function(rotate_by, increment_generation_by)
      local increment_generation_by = increment_generation_by and increment_generation_by or 0
      p.sentence_cursor_index = 1
      local num_instructions = l_system_instructions.get_num_instructions()
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
          clock.run(p.change_instructions, next_instruction, target_generation)  
          p.reset_offset()
        end
      end
    end 
    
    p.change_instructions = function(next_instruction, target_generation)
      clock.sleep(0.1)
      if (p.initializing == false) then
        p.setup(next_instruction, target_generation)
        p.play_turtle = true
      else
        clock.run(p.change_instructions, next_instruction)  
      end
    end
    
    p.get_plant_info = function()
      local plant_info = ("i".. p.current_instruction ..
            " g" .. p.current_generation ..
            "/" .. p.instr.max_generations ..
            " a".. math.ceil(math.deg(p.turtle.theta)) .. "°(" .. round_decimals(p.turtle.theta,3,"up") .. "r)")
      return plant_info
    end

    p.clip_offset = 0

    p.get_instructions_to_display = function(clip_length)
      p.sentence = p.lsys.get_sentence()
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
      local time1 = os.clock() * 1000
      if (restart_rendering) then 
        p.turtle.rotate(0, true)
        p.turtle.translate(p.start_from.x + p.offset.x, p.start_from.y + p.offset.y)
        p.turtle.rotate(math.rad(initial_turtle_rotation))
        turtle_data = p.turtle.render(restart_rendering)
        if (turtle_data) then
          render_percentage_completed = turtle_data.render_percentage_completed
        end
        
        if (p.initializing == false) then
          restart_rendering = true
          if (p.play_turtle) then
            p.start_playing()
          end
          p.play_turtle = false
        end
      end
    end
  end
  return p
end

return plant

