-- l_system_instructions (default)

------------------------------
-- notes:
-- see documentation on github for instructions on updating existing instructions and creating new ones:
--  https://github.com/jaseknighter/flora/blob/main/README.md
-- make sure the number_of_instructions variable is equal to the number of instructions listed 
--  in the l_system_instructions.get_instruction function
------------------------------

local l_system_instructions = {}
local number_of_instructions = 10

function l_system_instructions.get_num_instructions()
  return number_of_instructions
end

function l_system_instructions.get_instruction(instruction_id)
  local instruction = {}
  if (instruction_id == 1) then
    -- daisy
    instruction.start_from = vector:new(screen_size.x/2-10, screen_size.y - 10)
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('F',"F++F++F|F-F++F")
    instruction.axiom = "F++F++F++F++F++F"
    instruction.max_generations = 2
    instruction.length = screen_size.y/8
    instruction.angle = 36
    instruction.initial_turtle_rotation = 0
    instruction.starting_generation = 1
  elseif (instruction_id == 2) then
    instruction.start_from = vector:new(screen_size.x/2+10, screen_size.y)
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('F', "FF+[+F-F-F]-[-F+F+F]")
    instruction.axiom = "F"
    instruction.max_generations = 2
    instruction.length = screen_size.y/8
    instruction.angle = 25
    instruction.initial_turtle_rotation = 90
    instruction.starting_generation = 1
  elseif (instruction_id == 3) then
    instruction.start_from = vector:new(screen_size.x/2 - 15, screen_size.y - 5)
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('F',"F--F--F--G")
    instruction.ruleset[2] = rule:new('G',"GG");
    instruction.axiom = "F--F--F"
    instruction.max_generations = 2
    instruction.length = screen_size.y/2
    instruction.angle = math.deg(math.pi/3)
    instruction.starting_generation = 1
    instruction.initial_turtle_rotation = 90
  elseif (instruction_id == 4) then
    instruction.start_from = vector:new(screen_size.x/2 + 18, screen_size.y/2 + 20) --"center"
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('X',"+YF-XFX-FY+")
    instruction.ruleset[2] = rule:new('Y',"-XF+YFY+FX-")
    instruction.axiom = "X"
    instruction.max_generations = 3
    instruction.length = 20
    instruction.angle = 90 
    instruction.initial_turtle_rotation = 90
    instruction.starting_generation = 1
  elseif (instruction_id == 5) then
    instruction.start_from = vector:new(screen_size.x/2+15, screen_size.y - 10)
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('F',"FF+F+F+F+FF")
    instruction.axiom = "F+F+F+F"
    instruction.max_generations = 2
    instruction.length = screen_size.y/8
    instruction.angle = 90
    instruction.initial_turtle_rotation = 90
    instruction.starting_generation = 1
  elseif (instruction_id == 6) then
    -- Levy Curve
    instruction.start_from = vector:new(screen_size.x/2-3, screen_size.y - 5)
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('F',"-F++F-")
    instruction.axiom = "F"
    instruction.max_generations = 6 --15
    instruction.length = screen_size.y/4
    instruction.angle = 45
    instruction.starting_generation = 2
    instruction.initial_turtle_rotation = 90
  elseif (instruction_id == 7) then
    instruction.start_from = vector:new(screen_size.x/2-25, screen_size.y/2)
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('F',"FF-F-F-F-F-F+F")
    instruction.axiom = "F"
    instruction.max_generations = 2
    instruction.length = screen_size.y/4
    instruction.angle = 90
    instruction.starting_generation = 1
    instruction.initial_turtle_rotation = 0
  elseif (instruction_id == 8) then
    instruction.start_from = vector:new(screen_size.x/2, screen_size.y)
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('F',"[+FG-F]F[-FG+F]")
    instruction.axiom = "GGF"
    instruction.max_generations = 3
    instruction.length = screen_size.y/10
    instruction.angle = 25.7
    instruction.starting_generation = 2
    instruction.initial_turtle_rotation = 90
  elseif (instruction_id == 9) then
    instruction.start_from = vector:new(screen_size.x/2, screen_size.y) --"center"
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('X', "FGG[+X][-X]GXF")
    instruction.ruleset[2] = rule:new('F',"F")
    instruction.axiom = "X"
    instruction.max_generations = 3
    instruction.length = screen_size.y/15
    instruction.angle = 25.7
    instruction.starting_generation = 2
    instruction.initial_turtle_rotation = 90
  elseif (instruction_id == 10) then
    -- from: http://algorithmicbotany.org/papers/abop/abop-ch1.pdf (Figure 1.24(d)
    instruction.start_from = vector:new(screen_size.x/2+5, screen_size.y+12)
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('F',"G[+F]G[-F]+F")
    instruction.ruleset[2] = rule:new('G',"GG");
    instruction.axiom = "F"
    instruction.max_generations = 3
    instruction.length = 20
    instruction.angle = 20
    instruction.starting_generation = 1
    instruction.initial_turtle_rotation = 90
  elseif (instruction_id == 11) then
    -- from: https://thebrickinthesky.wordpress.com/2013/03/17/l-systems-and-penrose-p3-in-inkscape/
    instruction.start_from = vector:new(screen_size.x/2, screen_size.y/2)
    instruction.ruleset = {}
    instruction.ruleset[1] = rule:new('M',"OA++pA----FA[-OA----MA]++")
    instruction.ruleset[2] = rule:new('F',"+OA--PA[---MA--FA]+")
    instruction.ruleset[3] = rule:new('O',"-MA++FA[+++OA++PA]-")
    instruction.ruleset[4] = rule:new('P',"--OA++++MA[+PA++++FA]--FA")
    instruction.ruleset[5] = rule:new('A',"")
    instruction.axiom = "[F]++[F]++[F]++[F]++[F]"
    instruction.max_generations = 10
    instruction.length = 15
    instruction.angle = 36
    instruction.starting_generation = 1
    instruction.initial_turtle_rotation = 0
  end
  return instruction
end

return l_system_instructions
