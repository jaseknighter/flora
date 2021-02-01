-- l_system_instructions (community)

------------------------------
-- notes:
-- set default_to_community_garden = true in order to display the community garden
-- see documentation on github for instructions on updating existing instructions and creating new ones:
--  https://github.com/jaseknighter/flora/blob/main/README.md
-- make sure the number_of_instructions variable is equal to the number of instructions listed 
--  in the l_system_instructions.get_instruction function
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
    instruction.start_from = vector:new(81.5, 52)
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('X',"+YF-XFX-FY+")
    instruction.ruleset[2] = rule:new('Y',"-XF+YFY+FX-")
    instruction.axiom = "X"
    instruction.max_generations = 3
    instruction.length = 20
    instruction.angle = 90 
    instruction.initial_turtle_rotation = 90
    instruction.starting_generation = 1
  elseif (instruction_id == 2) then
    -- TEMPLATE
    -- author: <author>
    instruction.start_from = vector:new(48.5, 59)
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('F',"F--F--F--G")
    instruction.ruleset[2] = rule:new('G',"GG");
    instruction.axiom = "F--F--F"
    instruction.max_generations = 2
    instruction.length = screen_size.y/2
    instruction.angle = math.deg(math.pi/3)
    instruction.starting_generation = 1
    instruction.initial_turtle_rotation = 90
  end
  return instruction
end

return l_system_instructions
