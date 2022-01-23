local instructions_default = {
  {
    -- daisy,
    start_from = vector:new(screen_size.x/2-10, screen_size.y - 10),
    ruleset = {{"F","F++F++F|F-F++F"}},
    axiom = "F++F++F++F++F++F",
    max_generations = 2,
    length = screen_size.y/8,
    angle = 36,
    initial_turtle_rotation = 0,
    starting_generation = 1
  },{
    start_from = vector:new(screen_size.x/2+10, screen_size.y),
    ruleset = {{"F", "FF+[+F-F-F]-[-F+F+F]"}},
    axiom = "F",
    max_generations = 2,
    length = screen_size.y/8,
    angle = 25,
    initial_turtle_rotation = 90,
    starting_generation = 1
  },{
    -- from: https://thebrickinthesky.wordpress.com/2013/03/17/l-systems-and-penrose-p3-in-inkscape/,
    start_from = vector:new(screen_size.x/2, 30),
    ruleset = {
      {"M","OA++pA----FA[-OA----MA]++"},
      {"F","+OA--PA[---MA--FA]+"},
      {"O","-MA++FA[+++OA++PA]-"},
      {"P","--OA++++MA[+PA++++FA]--FA"},
      {"A",""}
    },
    axiom = "[F]++[F]++[F]++[F]++[F]",
    max_generations = 10,
    length = 15,
    angle = 36,
    starting_generation = 1,
    initial_turtle_rotation = 0
  },{
    start_from = vector:new(screen_size.x/2 - 15, screen_size.y - 5),
    ruleset = {
      {"F","F--F--F--G"}, 
      {"G","GG"}
    },
    axiom = "F--F--F",
    max_generations = 2,
    length = screen_size.y/2,
    angle = math.deg(math.pi/3),
    starting_generation = 1,
    initial_turtle_rotation = 90
  },{
    start_from = vector:new(screen_size.x/2 + 18, screen_size.y/2 + 20), --"center",
    ruleset = {
      {"X","+YF-XFX-FY+"},
      {"Y","-XF+YFY+FX-"}
    },
    axiom = "X",
    max_generations = 3,
    length = 20,
    angle = 90 ,
    initial_turtle_rotation = 90,
    starting_generation = 1
  },{
    start_from = vector:new(screen_size.x/2+15, screen_size.y - 10),
    ruleset = {{"F","FF+F+F+F+FF"}},
    axiom = "F+F+F+F",
    max_generations = 2,
    length = screen_size.y/8,
    angle = 90,
    initial_turtle_rotation = 90,
    starting_generation = 1
  },{
    -- Levy Curve,
    start_from = vector:new(screen_size.x/2-3, screen_size.y - 5),
    ruleset = {{"F","-F++F-"}},
    axiom = "F",
    max_generations = 6, --15,
    length = screen_size.y/4,
    angle = 45,
    starting_generation = 2,
    initial_turtle_rotation = 90
  },{
    start_from = vector:new(screen_size.x/2-25, screen_size.y/2),
    ruleset = {{"F","FF-F-F-F-F-F+F"}},
    axiom = "F",
    max_generations = 2,
    length = screen_size.y/4,
    angle = 90,
    starting_generation = 1,
    initial_turtle_rotation = 0
  },{
    start_from = vector:new(screen_size.x/2, screen_size.y),
    ruleset = {{"F","[+FG-F]F[-FG+F]"}},
    axiom = "GGF",
    max_generations = 3,
    length = screen_size.y/10,
    angle = 25.7,
    starting_generation = 2,
    initial_turtle_rotation = 90
  },{
    start_from = vector:new(screen_size.x/2, screen_size.y), --"center",
    ruleset = {
      {"X", "FGG[+X][-X]GXF"},
      {"F","F"}
    },
    axiom = "X",
    max_generations = 3,
    length = screen_size.y/15,
    angle = 25.7,
    starting_generation = 2,
    initial_turtle_rotation = 90
  },{
    -- from: http://algorithmicbotany.org/papers/abop/abop-ch1.pdf (Figure 1.24(d),
    start_from = vector:new(screen_size.x/2+5, screen_size.y+12),
    ruleset = {
      {"F","G[+F]G[-F]+F"},
      {"G","GG"}
    },
    axiom = "F",
    max_generations = 3,
    length = 20,
    angle = 20,
    starting_generation = 1,
    initial_turtle_rotation = 90
  },{
    -- Minimal sequence,
    start_from = vector:new(screen_size.x/2-3, screen_size.y - 5),
    ruleset = {{"F","F+F"}},
    axiom = "F",
    max_generations = 10, --15,
    length = screen_size.y/4,
    angle = 0,
    starting_generation = 1,
    initial_turtle_rotation = 90
  },{
    -- staghorn coral, from: https://samuelllsvensson.github.io/files/Procedurella_projekt.pdf,
    start_from = vector:new(screen_size.x/2-3, screen_size.y - 5),
    ruleset = {
      {"A","[TF!A[+AF[FB][FB]]]"},
      {"B","[!FB][!FB]"}
      -- {"A","[TF!A[+AF[FB][FFB][FFFB]]]"},
      -- {"B","[!FFFB][!FFFB]"}
    },
    axiom = "F[!A][!A]",
    -- axiom = "FF[!A][!A][!A][!A]",
    -- axiom = "FF!FF[!A]",
    -- axiom = "FF[!A!A][!A!A]",
    max_generations = 2,
    length = 5,
    angle = 30,
    starting_generation = 1,
    initial_turtle_rotation = 90
  }
}

return instructions_default
