-- l-system rule class
-- from: https:natureofcode.com/book/chapter-8-fractals/

local rule = {}
rule.__index = rule

function rule:new(a_, b_)
  local r = {}
  setmetatable(r, rule)

  r.a = a_
  r.b = b_
  r.min_generations = 1
  
  r.get_a = function()
    return r.a
  end

  r.get_b = function(generation)
    if type(r.b) == "string" then
      return r.b
    else
      local b_rule = ""
      for i=1, #r.b, 1
      do 
        if (generation >= r.b[i].starting_generation and
           generation <= r.b[i].ending_generation) then
          b_rule = r.b[i].rule
        end
      end
      return b_rule
    end
  end
  
  return r
end

return rule
