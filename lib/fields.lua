-- fields 
-- graphical representations of the following output parameters:
-- contains fields/plots/crops

------------------------------
-- includes (found in includes.lua), notes, and todo list
--
-- includes (found in includes.lua):
--    field_irrigation
--    field_layout
--
-- notes: 
--  nomenclature:
--    fields:	made up of one or more field (default is 1 fields)
--      field:	made up of one or more plots plots (default is 2 plots)
--        plot:	made up of (one) land and (one or more) crop
--          land:	always the size of a plot 
--          crop:	one or more rectangular or circular shape. 
--  parameters -> graphics:
--    quality min/max: west side line length
--    note scalar: north central line length 
--    cf scalars: south central line segments
--    note1/2 duration: east side line length
--    note_frequency_offset: the arc angle or rect division of the field 2:crop 1 
--
-- todo list: 
--  move field, plot, land, crop classes into a separate file 
------------------------------

local fields = {}
-- local screen_dirty = false

local num_fields_default = 6
  
fields.get_active_fields = function()
  return params:get("num_note_frequencies")
end

--------------------------
-- classes used by fields (field, plot, land, crops)
-- see 'nomenclature' above for basic details
--------------------------

---------
-- plot class: 
--    contained by the field class
--    contains land and one or more crop
---------
plot = {}
plot.__index = plot

function plot:new(plot_origin, plot_size, p_id)
  p = {}
  p.index = 1
  setmetatable(p, plot)
  
  p.origin = plot_origin
  p.size = plot_size
  p.id = p_id
  
  p.land = {}

  function p.land:redraw (field_id, plot_id, plot_origin, plot_size)
    field_layout:land_display(field_id, plot_id, plot_origin, plot_size)
  end

  function p.land:clear_field(field_id, plot_id, plot_origin, plot_size)
    field_layout:clear_field(field_id, plot_id, plot_origin, plot_size)
  end
  
  function p.land:init()
    return p.land
  end

  p.crops = {}
  
  function p.crops:redraw(field_id, plot_id, plot_origin, plot_size)
    field_layout:crop_display(field_id, plot_id, plot_origin, plot_size)
  end
  -- p.crops.__index = p.crops

  ---------
  -- crop class: 
  --    contained by the plot class
  ---------
  
  p.crop = {}
  p.crop.__index = p.crop
  
  function p.crop:new()
    local c = {}
    c.index = 1
    setmetatable(c, p.crop)
    
    return c
  end
  
  --------- end crop class --------------
  
  p.add_crop = function()
    local c = p.crop:new()
    table.insert(crops,c)
  end
  
  function p:redraw (field_id, plot_id)
    if field_id <= num_active_fields then
      local origin = self.origin
      local size = self.size
      p.land:redraw(field_id, plot_id, origin, size, num_active_fields)
      p.crops:redraw(field_id, plot_id, origin, size, num_active_fields)
    else
      local origin = self.origin
      local size = self.size
      p.land:clear_field(field_id, plot_id, origin, size, num_active_fields)
    end
  end
  
  return p
end
--------- end plot --------------

--------- start field --------------
---------
-- field class: 
--    contained by fields table (fields is a singleton, not a class)
--    contains one or plot
--      plots in turn contain one land instance and one or more crop instance
---------

local field = {}
field.__index = field

function field:new(origin, size, num_plots, field_id)
  local f = {}
  f.index = 1
  setmetatable(f, field)

  f.id = field_id
  f.set_size = function (size)
    f.size = size
  end
  
  f.set_origin = function (vector)
    f.origin = vector
  end

  f.set_size(size)
  f.set_origin(origin)

    
  f.num_plots = num_plots or 2
  f.plots = {}
  
  for i=1,f.num_plots,1
  do
    local plot_origin = vector:new(
      f.origin.x+(
        (f.size.x/f.num_plots) * (i-1)
      ),
      f.origin.y
    )
    
    local plot_size = vector:new(
      (f.size.x/f.num_plots), 
      f.size.y 
    )
  
    local p = plot:new(plot_origin, plot_size, i)
    table.insert(f.plots,p)
    p.land:init(i)
  end
  
  function f:redraw (active_control)
    for i=1,f.num_plots,1
    do
      f.plots[i]:redraw(f.id, f.plots[i].id)
    end
    
    if f.id == fields.note_frequency_index then
      local marker_x, marker_y
      local marker_size_x, marker_size_y
      if fields.note_frequency_menu_index == 1 then
        marker_x = f.origin.x  + f.size.x/2 - 4
        marker_size_x = 3
      elseif fields.note_frequency_menu_index == 2 then
        marker_x = f.origin.x  + f.size.x/2
        marker_size_x = 3
      else 
        marker_x = f.origin.x  + f.size.x/2 - 1
        marker_size_x = 4
      end

      if fields.note_frequency_menu_index < 3 then
        marker_y = f.origin.y  + f.size.y/2 - 3
        marker_size_y = 5
      else
        marker_y = f.origin.y  + f.size.y/2
        marker_size_y = 3
      end
      
      screen.move(marker_x, f.origin.y + f.size.y/2)
      screen.line_rel(marker_size_x,0)
      screen.move(f.origin.x  + f.size.x/2, marker_y)
      screen.line_rel(0,marker_size_y)
      screen.level(15)
      screen.aa(0)
      screen.stroke()
      screen.aa(1)
    end    
  end
  return f
end

--------- end field --------------

--------------------------
-- end classes
--------------------------


  
fields.init = function(num_fields)
  fields.num_fields = num_fields or num_fields_default
  
  -- initialize the fields
  local size_vector = vector:new(field_width, field_height)

  for i=1,fields.num_fields,1
  do
    local origin_x = i < 4 and fields_origin.x + ((i-1)*field_width) or fields_origin.x + ((i-4)*field_width)
    local origin_y = i < 4 and fields_origin.y or fields_origin.y + field_height + field_row_spacing
    local origin_vector = vector:new(origin_x, origin_y) 
    local num_plots = 2
    local field_id = i
    local f = field:new(origin_vector, size_vector, num_plots ,field_id)
    table.insert(fields,f)
  end
  screen_dirty = true
end    

fields.display = function()
  -- screen_dirty = true
  -- print("sd")
end

function fields:redraw (note_frequency_index,note_frequency_menu_index, active_field_menu_area, active_control)
  fields.note_frequency_index = 
    note_frequency_index > 0 and 
      note_frequency_index or nil
  fields.note_frequency_menu_index = note_frequency_menu_index
  -- draw the fields if they are screen_dirty
  if fields.note_frequency_index ~= fields.prior_note_frequency_index or 
    fields.note_frequency_menu_index ~= fields.prior_note_frequency_menu_index then
    -- screen_dirty = true
  end
  fields.prior_note_frequency_index = fields.note_frequency_index
  fields.prior_note_frequency_menu_index = fields.note_frequency_menu_index
  
  if screen_dirty then
    -- screen_dirty = false
    field_layout:set_layout_params()
    num_active_fields = self.get_active_fields()
    
    -- redraw the fields
    for i=1,fields.num_fields,1
    do
      fields[i]:redraw(active_control)
    end

    -- if active_field_menu_area < 6 then clear and redraw the irrigation
    screen.level(10)
    field_irrigation:irrigate(active_field_menu_area)
    field_irrigation:highlight_irrigation_area(active_field_menu_area, active_control)
  end
end

return fields
