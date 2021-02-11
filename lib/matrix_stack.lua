-- matrix_stack
-- from: https:--natureofcode.com/book/chapter-8-fractals/
-- more or less replicates the processing language's matrix stack, see:
--  https://processing.org/reference/pushMatrix_.html
--  https://processing.org/reference/popMatrix_.html

local matrix_stack = {}
matrix_stack.__index = matrix_stack

function matrix_stack:new()
  local ms = {}
  setmetatable(ms, matrix_stack)

  ms.stack = {}

  ms.push_matrix = function(v)
    table.insert(ms.stack, v)
  end

  ms.pop_matrix = function()
    -- make sure the stack isn't empty before 
    -- trying to remove an item
    if (#ms.stack > 0) then
      local stack_item = table.remove(ms.stack)
      return stack_item
    end
  end
  
  return ms
end

return matrix_stack
