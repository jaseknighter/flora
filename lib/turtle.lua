-- l-system turtle class
-- from: https:natureofcode.com/book/chapter-8-fractals/

------------------------------
-- notes:
--  the code below extends the basic symbols used in the NOC book to include 
--    an extended set of symbols frequently used in more sophisticated l-systems.
--  basic symbols:
--    F: move forward and draw a line and a circle
--    G: same behavior as F without drawing a circle
--    [: save the current position
--    ]: restore the previously saved position
--    +: rotate forward (by t.theta)
--    -: rotate backward (by -t.theta)
--  extended symbols
--    f: move forward without drawing
--    |: turn around 180 degrees
--    r: randomly increase or decrease angle by one degree
------------------------------

local matrix_stack = include("floramx/lib/matrix_stack") 

local turtle = {}
turtle.__index = turtle

function turtle:new(s, l, th)
  local t = {}
  setmetatable(t, turtle)
  
  t.todo = s
  t.length = l
  t.theta = th
  t.rotation = 0
  t.start = vector:new(0,0)
  t.finish = vector:new(t.length, 0)
  t.positions = {}
  t.ms = matrix_stack:new()  
  t.previous_todo = {}
  t.set_previous_todo = function(p_todo)
    t.previous_todo = p_todo
  end

  t.get_positions = function()
    return t.positions
  end
  
  t.get_position = function(idx)
    local position = t.positions[idx]
    return position
  end

  -- render the current generation
  local position_start = vector:new(0,0)
  local position_end = vector:new(0,0)
  
  local render_amount = 10
  local render_start = 0
  local render_complete = 0
  
  local rotation = 0
  
  t.render = function(restart)
    if (restart) then 
      render_start = 0
      render_complete = 0
    end
  
    render_start = render_start + 1
    local render_end
    if (render_start + render_amount < #t.todo) then
      render_end = render_start + render_amount
    else 
      render_end = #t.todo
    end
    
    local first_angle_processed = false
    for i=1, #t.todo, 1
    do
      local c = string.sub(t.todo, i, i)
      table.remove(t.positions, i)
      table.insert(t.positions, i, {})
  
      if (c == 'F' or c == 'G' or c == 'f' ) then
        position_start.x = t.start.x
        position_start.y = t.start.y
        position_end.x = t.start.x+t.length
        position_end.y = t.start.y
        position_end:rotate_around(position_start, t.rotation)
        screen.move(position_start.x, position_start.y)
        
        if (c == 'F' or c == 'G') then
          screen.line(position_end.x, position_end.y)
          if (c == 'F') then
            table.remove(t.positions, i)
            table.insert(t.positions, i, vector:new(position_end.x,position_end.y))
            screen.move(position_end.x+1, position_end.y)
            screen.circle(position_end.x, position_end.y,1)
          end
          screen.stroke()
        end
        screen.stroke()
        t.translate(position_end.x, position_end.y)
      elseif (c == '+') then
        t.rotate(t.theta)
      elseif (c == '-') then
        t.rotate(-t.theta)
      elseif (c == 'r') then
        local new_theta = t.theta + (math.random() * math.random(-1,1) * 0.01)
        t.theta = new_theta > 0 and new_theta or t.theta
      elseif (c == '[') then
        t.push(t.start, t.rotation)
      elseif (c == ']') then
        t.pop()
      elseif (c == '|') then -- extended alphabet from http://paulbourke.net/fractals/lsys/
        t.rotate(math.rad(180))
      end
    end
   
    local render_percentage_completed = (render_start + render_amount) / #t.todo
        
    if (render_percentage_completed >= 1) then
      render_start = 0
      render_percentage_completed = 1
    else
      render_start = render_end
    end 
      
    local return_object = {}
    return_object.render_percentage_completed = render_percentage_completed 
    return return_object
  end

  t.set_length = function(l)
    t.length = l
  end
  
  t.change_length = function(min_length, pct)
    local percent = pct and pct or 0.5
    t.length = t.length * percent > 1 and t.length * percent or 1
      
    -- make sure t.length is not less than min_length (if min_length is provided)
    if (min_length and t.length < min_length) then
      t.length = min_length
    end
  end
  
  t.set_todo = function(s)
    t.todo = s
    render_amount = 2
    render_start = 0
    render_complete = 0
  end
  
  t.push = function(v, r)
    local vector_to_store = v or t.start
    local rotation_angle_to_store = r or t.rotation
    t.ms.push_matrix({vector_to_store, rotation_angle_to_store})
  end
  
  t.pop = function()
    local last_object_stored = t.ms.pop_matrix()
    if (last_object_stored) then
      local last_vector_stored = last_object_stored[1]
      local last_angle_stored = last_object_stored[2]
      t.translate(last_vector_stored.x, last_vector_stored.y)
      t.rotation = last_angle_stored
    else 
    end
  end
  
  t.translate = function(x,y)
    t.start = vector:new(x,y)
  end

  t.rotate = function(theta, reset_rotation)
    if (reset_rotation) then
      t.rotation = theta
    else
      t.rotation = t.rotation + theta
    end
  end
  
  return t
end

return turtle
