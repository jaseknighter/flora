-- l_system_instructions (community)

------------------------------
-- notes:
-- see documentation on github (https://github.com/jaseknighter/flora) for instructions on updating or creating new instruction sets
-- make sure number_of_instructions to equal the number of instructions listed 
--  in the l_system_instructions.get_num_instructions() function
-- screen_size.x = 63.5
-- screen_size.y = 32
------------------------------

default_to_community_garden = false

local l_system_instructions = {}
local number_of_instructions = 2

function l_system_instructions.get_num_instructions()
  return number_of_instructions
end

function l_system_instructions.get_instruction(instruction_id)
  local instruction = {}
  if (instruction_id == 1) then
    -- TEMPLATE
    -- author: <author>
    instruction.start_from = vector:new(screen_size.x/2 + 18, screen_size.y/2 + 20) --"center"
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('X',"+YF-XFX-FY+")
    instruction.ruleset[2] = rule:new('Y',"-XF+YFY+FX-")
    instruction.axiom = "X"
    instruction.max_generations = 3
    instruction.length = 20
    instruction.angle = 90 
    instruction.initial_turtle_rotation = 90
  elseif (instruction_id == 2) then
    -- TEMPLATE
    -- author: <author>
    instruction.start_from = vector:new(screen_size.x/2 + 18, screen_size.y/2 + 20) --"center"
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('X',"+YF-XFX-FY+")
    instruction.ruleset[2] = rule:new('Y',"-XF+YFY+FX-")
    instruction.axiom = "X"
    instruction.max_generations = 3
    instruction.length = 20
    instruction.angle = 90 
    instruction.initial_turtle_rotation = 90
  end
  return instruction
end

return l_system_instructions
