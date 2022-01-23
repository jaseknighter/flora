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
  ls.rulesets_raw = r        -- the rulesets (an array of raw rule objects)
  ls.generation = 0     -- keeping track of the generation #
  ls.rulesets = {}
  ls.random_angles = ls.random_angles and ls.random_angles or {} 
  
  for i=1,#ls.rulesets_raw,1
  do
    ls.rulesets[i] = rule:new(ls.rulesets_raw[i][1],ls.rulesets_raw[i][2])
  end
  ls.num_rulesets = #ls.rulesets
  
  
  ls.get_num_rulesets = function()
    return ls.num_rulesets
  end

  ls.update = function(axiom,r)
    ls.axiom = axiom      -- the starting sentence (a string)
    ls.sentence = axiom   -- the sentence (a string)
    ls.rulesets_raw = r        -- the rulesets (an array of raw rule objects)
    ls.generation = 0     -- keeping track of the generation #
    ls.rulesets = {}
    ls.random_angles = ls.random_angles and ls.random_angles or {} 
    
    for i=1,#ls.rulesets_raw,1
    do
      ls.rulesets[i] = rule:new(ls.rulesets_raw[i][1],ls.rulesets_raw[i][2])
    end
    ls.num_rulesets = #ls.rulesets  
  end
  
  ls.set_num_rulesets = function(incr)
    if incr == - 1 then
      if ls.num_rulesets == 1 and ls.rulesets[ls.num_rulesets] then return else 
        table.remove(ls.rulesets_raw,ls.num_rulesets)
        table.remove(ls.rulesets,ls.num_rulesets)
        ls.num_rulesets = ls.num_rulesets + incr 
      end 
    else
      if ls.num_rulesets < #ls.rulesets then
        ls.num_rulesets = ls.num_rulesets + incr
      else
        ls.num_rulesets = ls.num_rulesets + incr
        local i = ls.num_rulesets
        ls.rulesets_raw[i] = {"F","F"}
        ls.rulesets[i] = rule:new(ls.rulesets_raw[i][1],ls.rulesets_raw[i][2])
      end
    end
  end
  

  ls.get_predecessor = function(ruleset_id)
    return ls.rulesets[ruleset_id].get_a()
  end

  ls.get_successor = function(ruleset_id)
    return ls.rulesets[ruleset_id].get_b()
  end

  ls.get_ruleset = function(ruleset_id)
    return ls.rulesets[ruleset_id]  
  end
  
  ls.set_ruleset = function(ruleset_id, predecessor, successor)
    -- ls.rulesets[ruleset_id] = rule:new(predecessor, successor)
    ls.rulesets_raw[ruleset_id] = {predecessor, successor}
    ls.rulesets[ruleset_id] = rule:new(ls.rulesets_raw[ruleset_id][1],ls.rulesets_raw[ruleset_id][2])
  end

  ls.get_axiom = function()
    return ls.axiom
  end

  ls.set_axiom = function(new_axiom)
    ls.axiom = new_axiom
  end

  ls.reset_random_angles = function()
    ls.random_angles = {}
  end

  ls.get_random_angle = function (ix)
    local random_angle
    -- print("num rands",#ls.random_angles)
    if ls.random_angles[ix] then
      -- print("found existing", ix,ls.random_angles[ix])
      random_angle = ls.random_angles[ix] 
    else
      random_angle = math.random(RANDOM_ANGLE_MAX)*math.random(-1,1)
      table.insert(ls.random_angles,random_angle)
      -- print("new ix", ix,random_angle,#ls.random_angles)
    end
    return random_angle
  end

  -- generate the next generation
  -- param dir: can be -1 or 1
  -- param rang: table of random angles to add to and `!` operator 
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

    local random_angles_ix = 1
    for i=1, #ls.sentence,1
    do
      -- what is the character
      -- we will replace it with itself unless it matches one of our rules
      local replace = string.sub(ls.sentence, i, i)
      if replace == "!" then 
        local after_punct = string.sub(ls.sentence, i+1, i+1)
        if after_punct ~= "_" and type(tonumber(after_punct))~="number" then
          local random_angle = ls.get_random_angle(random_angles_ix)
          random_angles_ix = random_angles_ix + 1
          local polarity = random_angle < 0 and -1 or 1
          random_angle = math.abs(random_angle)
          if random_angle > -10 and random_angle < 10 then
            replace = "00" .. random_angle
          elseif random_angle > -100 and random_angle < 100 then
            replace = "0" .. random_angle
          else
            replace = random_angle
          end
          if polarity == -1 then
            replace = "!-" .. replace
          else 
            replace = "!" .. replace
          end
        end
        
      end
      -- if i < 10 then print("replace",replace) end

      -- check every rule
      for j=1, #ls.rulesets,1
      do
        local a = ls.rulesets[j].get_a()
        -- if we match the rule, get the replacement string out of the rule
        if (a == replace) then
          replace = ls.rulesets[j].get_b(ls.generation)
          local punct_check = ls.check_for_punct(replace, random_angles_ix)
          replace = punct_check[1]
          random_angles_ix = punct_check[2]
          break
        end
      end
      -- append replacement string
      next_gen = next_gen .. replace
    end
    
    -- limit sentence length to prevent norns from freezing up!
    local max_length = MAX_SENTENCE_LENGTH or 150

    local next_sentence = #next_gen < max_length and next_gen or string.sub(next_gen, 1, max_length)
    -- print("next_sentence",next_sentence)
    ls.sentence = next_sentence
  end

  ls.check_for_punct = function (ruleset, random_angles_ix)
    local updated_ruleset = ''
    for i=1, #ruleset,1
    do
      -- what is the character
      -- we will replace it with itself unless it matches one of our rules
      local replace = string.sub(ruleset, i, i)
      if replace == "!" then 
        local after_punct = string.sub(ruleset, i+1, i+1)
        if after_punct ~= "_" and type(tonumber(after_punct))~="number" then
          local random_angle = ls.get_random_angle(random_angles_ix)
          random_angles_ix = random_angles_ix + 1
          local polarity = random_angle < 0 and -1 or 1
          random_angle = math.abs(random_angle)
          if random_angle > -10 and random_angle < 10 then
            replace = "00" .. random_angle
          elseif random_angle > -100 and random_angle < 100 then
            replace = "0" .. random_angle
          else
            replace = random_angle
          end
          if polarity == -1 then
            replace = "!_" .. replace
          else 
            replace = "!" .. replace
          end
        end
      end
      -- append replacement string
      updated_ruleset = updated_ruleset .. replace
    end
    return {updated_ruleset,random_angles_ix}
  end

  ls.get_sentence = function()
    return ls.sentence
  end
  
  ls.set_sentence = function(s)
    ls.sentence = s
    return ls.sentence
  end
  
  ls.get_generation = function()
    return ls.generation
  end
  return ls
end

return l_system
