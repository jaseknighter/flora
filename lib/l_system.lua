-- l-system class
-- from: https: natureofcode.com/book/chapter-8-fractals/

------------------------------
-- notes: 
--  an l-system has a starting sentence (axiom) and a ruleset
--  each generation recursively replaces characters in the sentence based on the rulset
--  sentence length is limited by the MAX_SENTENCE_LENGTH variable (currently 150 characters )
--
-- todo: improve efficiancy of code so MAX_SENTENCE_LENGTH can be increased
------------------------------


local l_system = {}
l_system.__index = l_system

-- construct an l-system with a starting sentence
-- and a ruleset
function l_system:new(axiom, r)
  local ls = {}
  setmetatable(ls, l_system)
  ls.axiom = axiom      -- the starting sentence (a string)
  ls.sentence = axiom   -- the sentence (a string)
  ls.ruleset = r        -- the ruleset (an array of rule objects)
  ls.generation = 0     -- keeping track of the generation #

  -- generate the next generation
  -- param dir can be -1 or 1
  ls.generate = function(dir)
    local direction
    if(dir == -1 or dir == 1) then
      direction = dir 
    else 
      direction = 1
    end
    -- an empty string buffer we will fill
    local next_gen = ''
    -- for every character in the sentence
    ls.generation = ls.generation + direction
    
    for i=1, #ls.sentence,1
    do
      -- what is the character
      -- we will replace it with itself unless it matches one of our rules
      local replace = string.sub(ls.sentence, i, i)
      -- check every rule
      for j=1, #ls.ruleset,1
      do
        local a = ls.ruleset[j].get_a()
        -- if we match the rule, get the replacement string out of the rule
        if (a == replace) then
          replace = ls.ruleset[j].get_b(ls.generation)
          break
        end
      end
      -- append replacement string
      next_gen = next_gen .. replace
    end
    
    -- limit sentence length to prevent norns from freezing up!
    local max_length = MAX_SENTENCE_LENGTH or 150

    local next_sentence = #next_gen < max_length and next_gen or string.sub(next_gen, 1, max_length)
    -- print("next_gen/next_sentence length",#next_gen,#next_sentence)
    ls.sentence = next_sentence
  end

  ls.get_sentence = function()
    return ls.sentence
  end
  
  ls.set_sentence = function(s)
    ls.sentence = s
  end
  
  ls.get_generation = function()
    return ls.generation
  end
  return ls
end

return l_system
