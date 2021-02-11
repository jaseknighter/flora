-- Arbitrary line and point graph drawing module.
-- Subclass of Graph for drawing common envelope graphs. .
-- Based on Mark Wheeler's (@markeats) envgraph: https://github.com/monome/norns/blob/main/lua/lib/envgraph.lua 

------------------------------
--  includes (found in includes.lua): Graph
--  todo: enable commented out getters 
------------------------------

local ArbGraph = {}
ArbGraph.__index = ArbGraph

local Graph = require "graph"

local show_bars = true

-------- Private utility methods --------

local function new_arb_graph(x_min, x_max, y_min, y_max)
  local graph = Graph.new(x_min, x_max, "lin", y_min, y_max, "lin", "line_and_point", false, false)
  setmetatable(ArbGraph, {__index = Graph})
  setmetatable(graph, ArbGraph)
  return graph
end

local function set_env_values(self, node_params)
  if not self._env then self._env = {} end
end


-------- Public methods --------

--- Create a new ArbGraph object.
-- All arguments optional.
-- @tparam number x_min Minimum value for x axis, defaults to 0.
-- @tparam number x_max Maximum value for x axis, defaults to 1.
-- @tparam number y_min Minimum value for y axis, defaults to 0.
-- @tparam number y_max Maximum value for y axis, defaults to 1.
-- @tparam table node_params: each node_param contains an array of:
--    level: accepts y_min to y_max, defaults to 0.5.
--    time: accepts x_min to x_max, defaults to 0 for the first node and 0.25 for the rest.
--    curve: accepts "lin", "exp" or a number where 0 is linear and positive and negative numbers curve the envelope up and down, defaults to -4.
-- @treturn ArbGraph Instance of ArbGraph.

-- function ArbGraph.new_adsr(x_min, x_max, y_min, y_max, attack, decay, sustain, release, level, curve)
function ArbGraph.new_graph(x_min, x_max, y_min, y_max, node_params)
  local arb_graph = new_arb_graph(x_min, x_max, y_min, y_max)
  
  -- graph:add_point(0, 0)
  for i=1,#node_params,1
  do
    arb_graph:add_point(
      node_params[i].time or 0.25 * (i-1), 
      node_params[i].level or 0.5, 
      node_params[i].curve or -4
    )
  end
  return arb_graph
end

--- Edit an ArbGraph object.
-- All arguments optional.
-- @tparam number x_min Minimum value for x axis, defaults to 0.
-- @tparam number x_max Maximum value for x axis, defaults to 1.
-- @tparam number y_min Minimum value for y axis, defaults to 0.
-- @tparam number y_max Maximum value for y axis, defaults to 1.
-- @tparam table node_params: each node_param contains an array of:
--    level: accepts y_min to y_max, defaults to 1.
--    time: accepts x_min to x_max, defaults to 1.
--    curve: accepts "lin", "exp" or a number where 0 is linear and positive and negative numbers curve the envelope up and down, defaults to -4.
function ArbGraph:edit_graph(node_params)
  for i=1,#node_params,1
  do
    local node_time = node_params[i].time ~= nil and node_params[i].time or nil
    local node_level = node_params[i].level ~= nil and node_params[i].level or nil
    local node_curve = node_params[i].curve ~= nil and node_params[i].curve or nil
    self:edit_point(i, node_time, node_level, node_curve)
  end
end

function ArbGraph:draw_bars(h_bar_percentage, v_bar_percentage)
  screen.line_width(1)

  screen.level(3)
  screen.move(self:get_x()-5, self:get_y()+self:get_height()+8)
  local line_width = util.linlin (1, self:get_width(), 1, self:get_width(), self:get_width() * h_bar_percentage)
  screen.line_rel(line_width+3,0)
  screen.stroke()

  screen.level(2)
  screen.move(self:get_x()-5, self:get_y()+self:get_height()+8)
  local line_height = util.linlin (1, self:get_height(), 1, self:get_height(), self:get_height() * v_bar_percentage)
  screen.line_rel(0,-line_height)
  screen.stroke()

  screen.level(10)
  screen.move(self:get_x()-7, self:get_y()+self:get_height()+10)
  screen.line_rel(0,-self:get_height()-4)
  screen.stroke()
  
  if self:get_x() < 20 then
    screen.move(self:get_x()-8, self:get_y()+6)
  else
    screen.move(self:get_x()-7, self:get_y()+6)
  end
  screen.line_rel(5,0)
  screen.stroke()
  screen.move(self:get_x()-3, self:get_y()+6)
  screen.line_rel(0,self:get_height())
  screen.move(self:get_x()-3, self:get_y()+self:get_height()+6)
  screen.line_rel(self:get_width()+3,0)
  screen.stroke()
  screen.move(self:get_x() + self:get_width(), self:get_y()+self:get_height()+5)
  screen.line_rel(0,5)
  screen.stroke()
  screen.move(self:get_x() + self:get_width(), self:get_y()+self:get_height()+10)
  screen.line_rel(-self:get_width()-8,0)
  screen.stroke()
end

function ArbGraph:highlight(self, active_point, highlight_style, h_bar_percentage, v_bar_percentage)
  local hs = highlight_style and highlight_style or "rect"
  if self:get_active() then
    if show_bars then
      self:draw_bars(h_bar_percentage, v_bar_percentage)  
    end
    if active_point > 0 then
      screen.level(3) 
      local sx, sy = self._points[active_point].sx, self._points[active_point].sy
      if hs == "rect" then
        screen.rect(sx - 2.5, sy - 2.5, 7, 7)
        screen.fill()
        screen.stroke()
      elseif hs == "horizontal_lines" then
        screen.move(sx - 2.5, sy - 2.5)
        screen.line_rel(7,0)
        screen.move(sx - 2.5, sy + 3.5)
        screen.line_rel(7,0)
        screen.stroke()
      elseif hs == "vertical_lines" then
        screen.move(sx - 2.5, sy - 2.5)
        screen.line_rel(0,7)
        screen.move(sx + 3.5, sy - 2.5)
        screen.line_rel(0,7)
        screen.stroke()
      elseif hs == "top_right_corner" then
        screen.move(sx - 2.5, sy - 2.5)
        screen.line_rel(7,0)
        screen.move(sx - 2.5, sy - 2.5)
        screen.line_rel(0,7)
        screen.stroke()
      end

      screen.level(3)
      -- screen.move(self:get_x()-6, self:get_y()+2)
      screen.move(self:get_x()-5, self:get_y()+self:get_height()+8)
      local line_width = util.linlin (1, self:get_width(), 1, self:get_width(), self:get_width() * h_bar_percentage)
      -- local width = util.linexp (slo, shi, dlo, dhi, f)
      screen.line_rel(line_width+3,0)
      screen.stroke()
    elseif hs == "h_bar" then
      screen.level(15)
      screen.move(self:get_x()-5, self:get_y()+self:get_height()+8)
      local line_width = util.linlin (1, self:get_width(), 1, self:get_width(), self:get_width() * h_bar_percentage)
      screen.line_rel(line_width+3,0)
      screen.stroke()
    elseif hs == "v_bar" then
      screen.level(15)
      screen.move(self:get_x()-5, self:get_y()+self:get_height()+8)
      local line_height = util.linlin (1, self:get_height(), 1, self:get_height(), self:get_height() * v_bar_percentage)
      screen.line_rel(0,-line_height)
      screen.stroke()
    end
  end
end

-- Getters

--[[
--- Get delay value.
-- @treturn number Delay value.
function ArbGraph:get_delay() return self._env.delay end

--- Get attack value.
-- @treturn number Attack value.
function ArbGraph:get_attack() return self._env.attack end

--- Get decay value.
-- @treturn number Decay value.
function ArbGraph:get_decay() return self._env.decay end

--- Get sustain value.
-- @treturn number Sustain value.
function ArbGraph:get_sustain() return self._env.sustain end

--- Get release value.
-- @treturn number Release value.
function ArbGraph:get_release() return self._env.release end

--- Get level value.
-- @treturn number Level value.
function ArbGraph:get_level() return self._env.level end

--- Get curve value.
-- @treturn string|number Curve value.
function ArbGraph:get_curve() return self._env.curve end
]]

return ArbGraph
