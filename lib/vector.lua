-- 2d vector class
-- based on: 
--  processing: https://processing.org/reference/PVector.html
--  Tom Armitage @infovore: https://github.com/infovore/chimes/blob/master/lib/vector2.lua

------------------------------
-- todo: add methods:
--       replace() - replace one vector with another
--       lerp() — linear interpolation to another vector
--       angle_between() — find the angle between two vectors

------------------------------

local vector = {}
vector.__index = vector

-- make a new vector
function vector:new(x,y)
  local v = {}
  setmetatable(v, vector)
  v.x = x or 0
  v.y = y or 0
  return v
end

-- clone a vector
function vector:clone(vc)
  return vector:new(vc.x,vc.y)
end

-- replace a vector
function vector:replace(vr)
  self = vector:new(vr.x,vr.y)
  return self
end

-- add vectors
function vector:add(va)
  self.x = self.x + va.x
  self.y = self.y + va.y
end

-- subtract vectors
function vector:subtract(vs)
  self.x = self.x - vs.x
  self.y = self.y - vs.y
end

-- scale the vector with multiplication
function vector:mult(vm)
  self.x = self.x * vm.x
  self.y = self.y * vm.y
end

-- scale the vector with division
function vector:div(vd)
  self.x = self.x / vd.x
  self.y = self.y / vd.y
end

-- get the magnitude of the vector 
function vector:get_mag()
  return math.sqrt(self.x^2 + self.y^2)
end

-- set the magnitude of the vector 
function vector:set_mag(mag)
  local current_mag = self:get_mag()
  self.x = self.x * mag / current_mag
  self.y = self.y * mag / current_mag
end

-- normalize the vector 
function vector:norm()
  if self:get_mag() ~= 0 then
    mag = self:get_mag()
    self:div(vector:new(mag,mag)) 
  end
end

-- limit the magnitude of a vector
--  return false if limit isn't reached
--  return true if limit is reached
function vector:limit(max)
  if self:get_mag() > max then
    self = self:set_mag(max)
    return true
  else 
    self = self
    return false
  end
end

-- get the heading of the vector
function vector:heading()
  return -math.atan2(self.y, self.x)
end

-- rotate the vector around another vector
--  central_vector: the point the rotating_vector is rotating around
--  angle: the angle of rotation (in radians)
function vector:rotate_around(central_vector, angle)
  local a = vector:new(central_vector.x, central_vector.y)
  local v = vector:new(self.x,self.y)
  v:subtract(a) 
  v = v:rotate(angle) -- rotate 
  a:add(v) -- point after rotation
  self.x = a.x
  self.y = a.y
end

-- rotate the vector by an angle (in radians)
function vector:rotate(angle)
  m = self:get_mag(self.x,self.y)
  fa = from_angle(self:heading() + angle)
  self = vector:new(fa.x,fa.y)
  self:set_mag(m)
  return self
end

-- return a vector from an angle (in radians)
function from_angle(angle)
  local fa = vector:new(math.cos(angle), -math.sin(angle))
  return fa
end

--  the Euclidean distance between two vectors (considered as points)
function vector:dist(a, b) 
  return math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2)
end

-- the dot product of two vectors
function vector:dot(v) 
  return self.x * v.x + self.y * v.y
end

-- the dot product of two vectors
function vector:random2d()
  random_x = math.random() > 0.5 and -1 or 1
  random_y = math.random() > 0.5 and -1 or 1
  return vector:new(random_x,random_y)
end

return vector
