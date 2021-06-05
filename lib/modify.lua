-- modify.lua: modify the l-system algorithms

------------------------------
-- includes (found in includes.lua), todo list, and notes
--
-- includes: 
--
-- todo list:

-- notes:
-- screen name from modify -> mod
-- UI Fields
-- -- number of fields (num_fields): 9
-- -- field names (param_labels): 
-- -- -- num rulesets (modify.num_rulesets)
-- -- -- ruleset X
-- -- -- -- ruleset X predecessor (1 character)
-- -- -- -- ruleset X successor (1 or more characters)
-- -- -- axiom (1 or more characters)
-- -- -- starting generation
-- -- -- max generations 
-- -- -- initial length 
-- -- -- angle (angle) (-360 to 360)
-- -- -- initial turtle rotation 
-- -- -- start from X 
-- -- -- start from Y 
-- -- -- save


local modify = {}
modify.__index = water

modify.active_control = 1

local param_labels
local param_ids
local ruleset_labels
local ruleset_ids

-- local num_active_note_frequencies

-- local note_frequency_menu_index = nil

-- local note_frequency_id
-- local note_frequency
    

modify.nav_labels = {}
modify.mod_char_cursor = 1
modify.reset = function ()
  modify.active_field_menu_area = 1
  modify.num_rulesets = 1
  
  modify.clip_offsets = {}
  modify.clip_offsets[1] = {}
  modify.clip_offsets[2] = {}
  modify.instruction_cursor_indices = {}
  modify.instruction_cursor_indices[1] = {}
  modify.instruction_cursor_indices[2] = {}
  modify.filesystem_cursor_indices = {}
  modify.filesystem_cursor_indices[1] = {}
  modify.filesystem_cursor_indices[2] = {}
end

---------------------------
-- sentence adjustment code 
---------------------------

local alphabet = {'F','G','[',']','+','-','|', 'r','A','M','N','O','P','X','Y'}
-- local max_visible_chars = 22

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

-- p.increment_sentence_cursor = function(incr)
--     local new_index = p.sentence_cursor_index + incr
--     if new_index < 1 then 
--       p.sentence_cursor_index = 1
--     elseif new_index <= #p.sentence then
--       p.sentence_cursor_index = p.sentence_cursor_index + incr
--     end
--   end


modify.modify_sentence = function(sentence, index, new_letter, mode)
  local sentence_table = table_from_sentence(sentence)
  if mode == "replace" or mode == "remove" then table.remove(sentence_table, index) end
  if mode ~= "remove" then table.insert(sentence_table, index, new_letter) end
  local new_sentence = sentence_from_table(sentence_table)
  
  return new_sentence
end 

modify.update_ruleset = function(ruleset_id, predecessor, successor)
  plants[active_plant].update_ruleset(ruleset_id, predecessor, successor)
  local new_sentence = plants[active_plant].get_sentence()
  plants[active_plant].set_sentence(new_sentence)
  -- ls.generate(1)
  plants[active_plant].setup(
    plants[active_plant].current_instruction,
    plants[active_plant].current_generation, 
    true
  )
  
  -- clock.run(set_dirty)
end

modify.update_axiom = function(new_axiom)
  plants[active_plant].update_axiom(new_axiom)
  -- local new_sentence = plants[active_plant].get_sentence()
  -- plants[active_plant].set_sentence(new_sentence)
  modify.update_plant()
end
  
modify.update_plant = function()
  plants[active_plant].setup(
    plants[active_plant].current_instruction,
    plants[active_plant].get_current_generation()
  )
end

modify.add_letter = function()
  local cursor_index = modify.instruction_cursor_indices[active_plant][modify.active_control]
  cursor_index = cursor_index and cursor_index + 1 or 2
  local ruleset_id = math.floor(modify.active_control/2)
  modify.mod_char_cursor = modify.mod_char_cursor or 1
  local new_letter = alphabet[modify.mod_char_cursor] or alphabet[1]
  if modify.active_control <= modify.num_rulesets * 2 + 1 then
    local predecessor = modify.get_predecessor(ruleset_id)
    local successor = modify.get_successor(ruleset_id)
    if (modify.active_control - 1) % 2 == 1 then
      return
      -- predecessor = modify.modify_sentence(predecessor, cursor_index, new_letter,"add")
    else
      successor = modify.modify_sentence(successor, cursor_index, new_letter,"add")
      modify.update_ruleset(ruleset_id, predecessor, successor)
    end
    
  elseif modify.active_control <= modify.num_rulesets * 2 + 2 then
    local axiom = modify.get_axiom()
    axiom = modify.modify_sentence(axiom, cursor_index, new_letter,"add")
    modify.update_axiom(axiom)
  end
end

modify.remove_letter = function()
  local cursor_index = modify.instruction_cursor_indices[active_plant][modify.active_control] or 1
  local ruleset_id = math.floor(modify.active_control/2)
  if modify.active_control <= modify.num_rulesets * 2 + 1 then
    local predecessor = modify.get_predecessor(ruleset_id)
    local successor = modify.get_successor(ruleset_id)
    if (modify.active_control - 1) % 2 == 1 then
      return
    elseif #successor > 1 then
      successor = modify.modify_sentence(successor, cursor_index, nil,"remove")
    end
    
    modify.update_ruleset(ruleset_id, predecessor, successor)
  elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 3 then
  local axiom = modify.get_axiom()
  if #axiom > 1 then
    axiom = modify.modify_sentence(axiom, cursor_index, new_letter,"remove")
    modify.update_axiom(axiom)
    -- plants[active_plant].setup(
    --   plants[active_plant].current_instruction,
    --   nil, 
    --   true
    -- )
  end
end

end

--

modify.set_param_labels = function()
  param_labels = {
    "num rulesets",
    "axiom",
    "starting gen",
    "max gen",
    "init len",
    "angle",
    "init angle",
    "x start",
    "y start",
    -- "save"
  }
end


modify.set_param_ids = function()
  param_ids = {
    "num_rulesets",
    "axiom",
    "starting_gen",
    "max_gen",
    "init_len",
    "angle",
    "init_angle",
    "start_x",
    "start_y",
    -- "save"

  }
end

local filesystem_param_ids = {
  "save",
  "save_as",
  "delete"
}

modify.set_ruleset_labels = function()
  local labels = {}
  for i=1,modify.num_rulesets,1
  do
    table.insert(labels, "rs" .. i .. " pre")
    table.insert(labels, "rs" .. i .. " suc")
  end  
  ruleset_labels = labels
end


modify.set_ruleset_ids = function()
  local ids = {}
  for i=1,modify.num_rulesets,1
  do
    table.insert(ids, "rs_" .. i .. "predecessor")
    table.insert(ids, "rs_" .. i .. "successor")
  end  
  ruleset_ids = ids
end


--



--

function modify.get_num_rulesets()
  -- modify.num_rulesets = params:get("num_rulesets")
  modify.num_rulesets = plants[active_plant].get_num_rulesets()
  return modify.num_rulesets
end

function modify.set_num_rulesets(incr)
  -- params:set("num_rulesets",incr)
  plants[active_plant].set_num_rulesets(incr)
end

function modify.get_predecessor(ruleset_id)
  return plants[active_plant].get_predecessor(ruleset_id)
end

function modify.get_successor(ruleset_id)
  return plants[active_plant].get_successor(ruleset_id)
end

function modify.get_axiom()
  return plants[active_plant].get_axiom()
end

function modify.get_starting_gen()
  return plants[active_plant].get_starting_gen()
end

function modify.set_starting_gen(incr)
  return plants[active_plant].set_starting_gen(incr)
end

function modify.get_max_generations()
  return plants[active_plant].get_max_generations()
end

function modify.set_max_generations(incr)
  return plants[active_plant].set_max_generations(incr)
end

function modify.get_init_length()
  return plants[active_plant].get_init_length()
end


function modify.set_init_length(incr)
  plants[active_plant].set_init_length(incr)
  modify.update_plant()
end


function modify.get_angle()
  return plants[active_plant].get_angle()
end
  
function modify.set_angle(incr)
  plants[active_plant].set_angle(incr)
end

function modify.get_init_angle()
  return plants[active_plant].get_init_angle()
end

function modify.set_init_angle(incr)
  plants[active_plant].set_init_angle(incr)
  modify.update_plant()
end


function modify.get_start_from_x()
  return math.floor(plants[active_plant].get_start_from_x())
end

function modify.set_start_from_x(incr)
  plants[active_plant].set_start_from_x(incr)
  modify.update_plant()
end


function modify.get_start_from_y()
  return math.floor(plants[active_plant].get_start_from_y())
end

function modify.set_start_from_y(incr)
  plants[active_plant].set_start_from_y(incr)
  modify.update_plant()
end

--

function modify.set_control_labels_ids()
  modify.set_param_labels()
  modify.set_param_ids()
  -- num_active_note_frequencies = params:get("num_note_frequencies")
  -- num_active_note_frequencies = params:get("num_note_frequencies")

  
  modify.set_ruleset_labels()
  for i=1,#ruleset_labels,1
  do
    table.insert(
      param_labels,
      1 + i, -- replace magic number '1' with a constant
      ruleset_labels[i]
    )
  end

  modify.set_ruleset_ids()
  for i=1,#ruleset_ids,1
  do
    table.insert(
      ruleset_ids,
      1 + i, -- replace magic number '1' with a constant
      ruleset_ids[i]
    )
  end
  
end

function modify.init()
  modify.reset()
  modify.get_num_rulesets()
  modify.num_field_menu_areas = 9 + (modify.num_rulesets * 2)

  modify.set_control_labels_ids()
  -- fields.init(num_fields)
end

-- modify.clip_offset = 0
-- modify.instruction_cursor_index = 1
-- local max_visible_chars = 14




modify.get_clipped_instruction = function(instruction)
  modify.max_visible_chars = 25 - #modify.nav_labels[modify.active_control]
  local cursor_index = modify.instruction_cursor_indices[active_plant][modify.active_control]
  cursor_index = cursor_index == nil and 1 or cursor_index
  modify.instruction_cursor_indices[active_plant][modify.active_control] = cursor_index
  local letters_left_of_cursor = string_cut(instruction, 1, cursor_index-1)
  modify.selected_letter = string_cut(instruction, cursor_index, cursor_index)
  local letter_location = {}
  letter_location.x, letter_location.y = screen.text_extents(letters_left_of_cursor)
  local letter_offset = letter_location.x
  modify.clip_offsets[active_plant][modify.active_control] = cursor_index > modify.max_visible_chars and cursor_index - modify.max_visible_chars or 0
  local clipped_sentence = string_cut(instruction, 1 + modify.clip_offsets[active_plant][modify.active_control], modify.max_visible_chars + modify.clip_offsets[active_plant][modify.active_control])
  local clipped_sentence_len = screen.text_extents(clipped_sentence)
  local last_letter = string_cut(clipped_sentence,#clipped_sentence,#clipped_sentence)
  local last_letter_len = screen.text_extents(last_letter)
  local cursor_location_x = letter_offset < clipped_sentence_len and letter_offset or clipped_sentence_len - last_letter_len
  
  local cursor_index = modify.instruction_cursor_indices[active_plant][modify.active_control]
        
  if #clipped_sentence ~= #instruction and cursor_index ~= #instruction then 
    clipped_sentence = clipped_sentence .. "..." 
  end
  
  return {
    clipped_sentence,
    cursor_location_x
  }
end

modify.set_cursor = function()
  local label = "mod " .. param_labels[modify.active_control] .. " "
  if modify.active_control <= (modify.num_rulesets * 2) + 1 then
    if ((modify.active_control - 1)%2) ~= 1 then
      local instruction = modify.get_successor(math.floor(modify.active_control/2))
      local instruction_details = modify.get_clipped_instruction(instruction)
      local instructions = show_instructions == true and "instructions" or instruction_details[1]
      local cursor_location = instruction_details[2]
      cursor_location = cursor_location - screen.text_extents(instructions) - 1
      screen.text(label .. instructions)
      if show_instructions == false then
        screen.move_rel(cursor_location , 2)
        screen.text('_')
      end
    end
  elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 3 then
    -- axiom (axiom)
      local instruction = modify.get_axiom()
      local instruction_details = modify.get_clipped_instruction(instruction)
      local instructions = show_instructions == true and "instructions" or instruction_details[1]
      local cursor_location = instruction_details[2]
      cursor_location = cursor_location - screen.text_extents(instructions) - 1
      screen.text(label .. instructions)
      if show_instructions == false then
        screen.move_rel(cursor_location , 2)
        screen.text('_')
      end
  end
end

modify.get_control_labels = function()
  local label = param_labels[modify.active_control] .. " "
  local menu_index
  if modify.active_control == 1 then
    label = label .. modify.get_num_rulesets()
  elseif modify.active_control <= modify.num_rulesets * 2 + 1 then
    if ((modify.active_control - 1)%2) == 1 then
      local predecessor = modify.get_predecessor(math.floor(modify.active_control/2))
      label = label .. predecessor
      modify.nav_labels[modify.active_control] = "mod " .. label
    else
      modify.nav_labels[modify.active_control] = "mod " .. label
      local instruction = modify.get_successor(math.floor(modify.active_control/2))
      local instruction_details = modify.get_clipped_instruction(instruction)
      local instructions = show_instructions == true and "instructions" or instruction_details[1]
      label = label .. modify.get_successor(math.floor(modify.active_control/2))
    end
  elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 3 then
    -- axiom (axiom)
      modify.nav_labels[modify.active_control] = "mod " .. label
      local instruction = modify.get_axiom()
      local instruction_details = modify.get_clipped_instruction(instruction)
      local instructions = show_instructions == true and "instructions" or instruction_details[1]
      label = label .. modify.get_axiom()
  elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 4 then
    -- starting generation (starting_gen)
    label = label .. modify.get_starting_gen()
  elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 5 then
    -- max generations (max_gen)
    label = label .. modify.get_max_generations()
  elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 6 then
    -- initial length (init_len)
    label = label .. modify.get_init_length()
  elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 7 then
    -- angle (angle) (-360 to 360)
    label = label .. modify.get_angle()
  elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 8 then
    -- initial turtle rotation (init_angle)
    label = label .. ""
    label = label .. modify.get_init_angle()
  elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 9 then
    -- start from X (start_from_x)
    label = label .. modify.get_start_from_x()
  elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 10 then
    -- start from Y (start_from_y)
    label = label .. modify.get_start_from_y()
  end

  return label
  
end
  

modify.key = function (n,z)
  if modify.active_control > 1 and modify.active_control <= modify.num_rulesets * 2 + 2 then
    if show_instructions == false then
      if (n == 2 and z == 0 and alt_key_active == false)  then 
        -- plants[active_plant].remove_letter()
        modify.remove_letter()
      elseif (n == 3 and z == 0 and alt_key_active == false)  then 
        -- plants[active_plant].add_letter()
        modify.add_letter()
      end
    end
  end
end



modify.enc = function(n, delta, alt_key_active)
  -- set variables needed by each page/example
  if n == 1 then
    -- do nothing here
  elseif n == 2 then 
    local incr = util.clamp(delta, -1, 1)
    modify.active_control = util.clamp(incr + modify.active_control, 1, #param_ids+(modify.num_rulesets*2) )
    -- modify.active_control = util.clamp(incr + modify.active_control, 1, #param_ids+(modify.num_rulesets*2) + #filesystem_param_ids)
  elseif n == 3 and alt_key_active then 
    local incr = util.clamp(delta, -1, 1)
    if modify.active_control > 1 and modify.active_control <= modify.num_rulesets * 2 + 2 then
      modify.mod_char_cursor = modify.mod_char_cursor + incr
      modify.mod_char_cursor = modify.mod_char_cursor > #alphabet and 1 or modify.mod_char_cursor
      modify.mod_char_cursor = modify.mod_char_cursor < 1 and #alphabet or modify.mod_char_cursor
      
      local new_letter = alphabet[modify.mod_char_cursor] or alphabet[1]
      
      local cursor_index = modify.instruction_cursor_indices[active_plant][modify.active_control] or 1
      local ruleset_id = math.floor(modify.active_control/2)
      if modify.active_control <= modify.num_rulesets * 2 + 1 then
        local predecessor = modify.get_predecessor(ruleset_id)
        local successor = modify.get_successor(ruleset_id) 
        if (modify.active_control - 1) % 2 == 1 then
          predecessor = modify.modify_sentence(predecessor, cursor_index, new_letter,"replace")
        else
          successor = modify.modify_sentence(successor, cursor_index, new_letter,"replace")
        end
        
        modify.update_ruleset(ruleset_id, predecessor, successor)
      elseif modify.active_control <= modify.num_rulesets * 2 + 2 then
        local axiom = modify.get_axiom()
        axiom = modify.modify_sentence(axiom, cursor_index, new_letter,"replace")
        modify.update_axiom(axiom)
      end
    elseif modify.active_control == 1 then
      modify.set_num_rulesets(incr)
    elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 4 then
      -- starting generation (starting_gen)
      modify.set_starting_gen(incr)
    elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 5 then
      -- max generations (max_gen)
      modify.set_max_generations(incr)
    elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 6 then
      -- initial length (init_len)
      modify.set_init_length(incr)
    elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 7 then
      -- angle
      modify.set_angle(incr)
    elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 8 then
      -- initial turtle rotation (init_angle)
      modify.set_init_angle(incr)
    elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 9 then
      -- start from X (start_from_x)
      modify.set_start_from_x(incr)
    elseif modify.active_control - (modify.num_rulesets * 2) + 1 == 10 then
      -- start from Y (start_from_y)
      modify.set_start_from_y(incr)
    end 
  elseif n == 3 then 
    local incr = util.clamp(delta, -1, 1)
    if modify.active_control > 1 and modify.active_control <= modify.num_rulesets * 2 + 1 then
      if (modify.active_control - 1) % 2 == 0 then
        local cursor_index = modify.instruction_cursor_indices[active_plant][modify.active_control]
        cursor_index = cursor_index == nil and 1 or cursor_index + incr
        local current_sentence = modify.get_successor(math.floor(modify.active_control/2))
        cursor_index = util.clamp(cursor_index, 1, #current_sentence) 
        modify.instruction_cursor_indices[active_plant][modify.active_control] = cursor_index
      end
    elseif modify.active_control <= modify.num_rulesets * 2 + 2 then
      -- axiom (axiom)
      local cursor_index = modify.instruction_cursor_indices[active_plant][modify.active_control]
      cursor_index = cursor_index == nil and 1 or cursor_index + incr
      cursor_index = util.clamp(cursor_index, 1, #modify.get_axiom()) 
      modify.instruction_cursor_indices[active_plant][modify.active_control] = cursor_index
    end
  end
end

-- modify.draw_fields = function()
-- -- TODO: replace magic number 6 with constant

--   screen.level(5)
--   screen.aa(1)
--   fields:redraw(
--     modify.active_control - (8 + modify.num_rulesets),
--     note_frequency_menu_index,
--     modify.active_field_menu_area,
--     modify.active_control)
--   screen.update()
--   screen.aa(0)
-- end

modify.draw_modify_nav = function()
  if modify.active_control == 1 then 
    modify.active_field_menu_area = 1
    label = "mod " .. modify.get_control_labels()
    screen.text(label)
  elseif modify.active_control <= modify.num_rulesets * 2 + 1 then
    modify.active_field_menu_area = 2
    -- if modify.active_control < modify.num_rulesets * 2 + 1 then
    if ((modify.active_control - 1)%2) == 1 then
      label = "mod " .. modify.get_control_labels()
      screen.text(label)
    else
      label = "mod " .. modify.get_control_labels()
      modify.set_cursor()
    end
  elseif modify.active_control <= modify.num_rulesets * 2 + 2 then
    modify.active_field_menu_area = 3
    label = "mod " .. modify.get_control_labels()
    modify.set_cursor()
    -- screen.text(label)
  else 
    modify.active_field_menu_area = modify.active_control - (modify.num_rulesets*2) + 1
    label = "mod " .. modify.get_control_labels()
    screen.text(label)
  end
  screen.level(10)
  -- screen.move(0,10)  
  screen.rect(2,10, screen_size.x-2, 3)
  screen.fill()
  screen.level(0)
  if alt_key_active and modify.active_control > 1 and modify.active_control <= modify.num_rulesets * 2 + 2 then
    screen.rect(screen_size.x-7,1,7,8)
    screen.fill()
    screen.level(10)
    screen.move(screen_size.x-5,7)
    local character = alphabet[modify.mod_char_cursor] or alphabet[1]
    screen.text(character)
  end
  screen.level(0)
  local area_menu_width = (screen_size.x-5)/11
  screen.rect(2+(area_menu_width*(modify.active_field_menu_area-1)),10, area_menu_width, 3)
  screen.fill()
  screen.level(4)
  for i=1, 11,1
  do
    if i < 11 then
      screen.rect(2+(area_menu_width*(i-1)),10, 1, 3)
      screen.fill()
    else
      screen.rect(2+(area_menu_width*(i-1))-1,10, 1, 3)
    end
  end
  screen.fill()
end

modify.redraw = function ()
  if show_instructions ~= true then
    modify.get_num_rulesets()
    modify.set_control_labels_ids()
    
    -- modify.draw_water_nav()
    -- modify.draw_fields()
  end
end

modify.display = function()
  modify.redraw()
  -- fields.display()
end


return modify
