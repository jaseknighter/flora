-- field layout
-- graphical representations of the following output parameters:
--    amplitude (all outputs)
--    note frequency (bandsaw)
--
-- v1.0.0 @author
-- llllllll.co/t/<insert reference id>
--

------------------------------
-- includes (found in includes.lua):
--  field_crop
------------------------------

local field_layout = {}
field_layout.__index = field_layout
field_layout.audio_parameters = {}

field_layout.crops = {}

local f_a_params = field_layout.audio_parameters
local f_g_params = field_layout.graphical_parameters

function field_layout:set_layout_params()
  f_a_params.amp = params:get("amp")
  f_a_params.p1 = {}
  f_a_params.p2 = {}
  f_a_params.p1.duration = options.NOTE_DURATIONS[params:get("plant_1_note_duration")]
  f_a_params.p2.duration = options.NOTE_DURATIONS[params:get("plant_2_note_duration")]
  f_a_params.num_active_note_frequencies = params:get("num_note_frequencies")
  f_a_params.note_frequencies={}
  for i=1, f_a_params.num_active_note_frequencies, 1
  do
    f_a_params.note_frequencies[i]={}
    local nfn = params:get(note_frequency_numerators[i])
    local nfd = params:get(note_frequency_denominators[i])
    local nfo = params:get(note_frequency_offsets[i])
    table.insert(f_a_params.note_frequencies[i], nfn)
    table.insert(f_a_params.note_frequencies[i], nfd)
    table.insert(f_a_params.note_frequencies[i], nfo)
  end

  f_a_params.num_active_cf_scalars = params:get("num_active_cf_scalars")
  f_a_params.cf_scalars = {}
  for i=1, f_a_params.num_active_cf_scalars,1
  do
      local cf_scalar = cf_scalars[i]
      table.insert(f_a_params.cf_scalars, params:get(cf_scalar))
  end
end

function field_layout:clear_field(field_id, plot_id, plot_origin, plot_size)
  screen.level(0) 
  screen.rect(plot_origin.x,plot_origin.y,plot_size.x, plot_size.y)
  screen.fill()
  
end

function field_layout:land_display(field_id, plot_id, plot_origin, plot_size, highlight_land)
    local num_active_fields = field_layout.audio_parameters.num_active_note_frequencies
    local amp_brightness_adj = math.floor(util.linlin (0, 10, 6, 0, f_a_params.amp))
    if field_id % 2 == 1 then
      field_layout.screen_level = 15 - amp_brightness_adj
    else
      field_layout.screen_level = 13 - amp_brightness_adj
    end

    --redraw the land
    -- local tempo_scalar_offset = params:get("tempo_scalar_offset")
    -- local tempo_scalar_screen_offset = util.linlin(0.1,2,-3,4,tempo_scalar_offset)
    -- tempo_scalar_screen_offset = plot_id == 1 and math.ceil(tempo_scalar_screen_offset) or 0
    -- screen.level(field_layout.screen_level + tempo_scalar_screen_offset) 
    
    screen.level(field_layout.screen_level) 
    screen.rect(plot_origin.x,plot_origin.y,plot_size.x, plot_size.y)
    screen.fill()
end

function field_layout:crop_display(field_id, plot_id, plot_origin, plot_size)

  -------
  -- field layout sub-functions
  -------
  function field_layout:get_total_crops_area(crops)
    local crops_area = 0
    for i=1,#field_layout.crops,1
    do
      local crop = field_layout.crops[i]
      local crop_size = crop.get_size()
      local crop_type = crop.get_type()
      local crop_areas
      if crop_type == "arc" then
        -- calculate area of a circle (A = pi * the radius squared)
        local crop_radius = crop.size.x/2
        crop_area = math.pi * (crop_radius * crop_radius) 
      else
       crop_area = crop_size.x * crop_size.y
      end
      crops_area = crops_area + crop_area
    end
    return crops_area
  end
  
function field_layout:crop_layout(crops, active_note_freq)
    -- resize the crops to fit the size of the plot and then space them out
    for i=#crops,1,-1
    do
      
      local crop = crops[i]
      local crop_type = crop.get_type()
      local open_space = true
      local size_vector
      local plot_area = plot_size.x * plot_size.y
      
      if crop_type == "arc" then
        if #crops == 1 then
          size_vector = vector:new(20,20)
        elseif #crops == 2 then
          size_vector = vector:new(12,12)
        else
          size_vector = vector:new(10,10)
        end
        crop.set_size(size_vector)
      elseif crop_type == "rect" then
        -- scale the crops  to fit
        if #crops == 1 then
          size_vector = vector:new(20,20)
        else
          size_vector = vector:new(10,10)
        end
        crop.set_size(size_vector)
      end
    end
    
    -- spread the crop out evenly within the plot
    for i=1,#crops,1
    do
      local crop = crops[i]
      local crop_id = crop.get_id()
      local crop_type = crop.get_type()
      if crop_type == "arc" then
        local radius = crop.get_size().x/2
        local new_origin
        if crop_id == 1 then
          new_origin = vector:new(radius,radius)
          -- new_origin = vector:new(1,1)
        elseif crop_id == 2 then
          new_origin = vector:new(plot_size.x-radius,plot_size.y-radius)
        elseif crop_id == 3 then
          new_origin = vector:new(radius,plot_size.y-radius)
        elseif crop_id == 4 then
          new_origin = vector:new(plot_size.x-radius,radius)
        end 
        crop.move_origin(new_origin)
      elseif crop_type == "rect" then
        local width = crop.get_size().x
        local new_origin
        if crop_id == 1 then
          new_origin = vector:new(0,0)
        elseif crop_id == 2 then
          new_origin = vector:new(plot_size.x/2,plot_size.x/2)
        elseif crop_id == 3 then
          new_origin = vector:new(plot_size.x/2,0)
        elseif crop_id == 4 then
          new_origin = vector:new(0,plot_size.x/2)
        end 
        crop.move_origin(new_origin)
      end
    end
  end

  -- crop divisions are based on the number and value of cf_scalars
  function field_layout:get_crop_divisions(crop_id, plot_id)
    local crop_divisions
    if crop_id == 1 and plot_id == 2 then
      local offset = f_a_params.note_frequencies[field_id][3]
      local offset_angle = util.linlin (-0.99, 0.99, 10, 350, offset)
      crop_divisions = vector:new(0,offset_angle)
    else 
      crop_divisions = vector:new(0,360)
    end
    return crop_divisions
  end

  ------- end field layout sub-functions -------
    
  field_layout.crops = {}
  -- if plot_id == 1 then 
  if field_id % 2 == 1 then 
    screen.level(5) 
  else 
    screen.level(10) 
  end
    
  -- set number of crops per plot based on the number of:
  --  note frequency numerators and denominators
  local nfn = f_a_params.note_frequencies[field_id][1]
  local nfd = f_a_params.note_frequencies[field_id][2]

  ---------
  -- set number/type of crops per plot based on nfn/nfd
  ---------
  local center
  
  num_crops_to_plant = plot_id == 1 and nfn or nfd

  screen.fill()

  -- plant the crops
  if num_crops_to_plant < 5 then
    for i=1,num_crops_to_plant,1
    do
      center = vector:new(plot_origin.x, plot_origin.y)
      -- local crop_divisions = vector:new(0,360)
      local crop_divisions = field_layout:get_crop_divisions(i, plot_id) 
      local arc_diameter = vector:new(2,2)
      new_crop = crop:new("arc", center, arc_diameter, crop_divisions)
      table.insert(field_layout.crops, new_crop)
      new_crop.set_id(#field_layout.crops)
    end
    field_layout:crop_layout(field_layout.crops)
    for i=1,#field_layout.crops,1
    do
      -- adjust screen level for each crop
      local rect_screen_Level_adj = i % 2 == 1 and 4 or 6
      local screen_level = (field_layout.screen_level - rect_screen_Level_adj)
      screen.level(screen_level)
      field_layout.crops[i]:display(screen_level)
      screen.level(field_layout.screen_level)
    end
  elseif num_crops_to_plant >= 5 then
    if num_crops_to_plant == 5 then 
      -- clear the field of old crops
      field_layout.crops = {} 
    end
    
    -- plant the crops
    for i=1,num_crops_to_plant-4,1
    do
      center = vector:new(plot_origin.x, plot_origin.y)
      local crop_divisions = field_layout:get_crop_divisions(i, plot_id) 
      local rect_size
      if num_crops_to_plant == 1 then
        rect_size = vector:new(plot_size.x, plot_size.y)
      else
        rect_size = vector:new(plot_size.x, plot_size.y)
      end
      new_crop = crop:new("rect", center, rect_size,crop_divisions)
      table.insert(field_layout.crops, new_crop)
      new_crop.set_id(#field_layout.crops)
    end
    field_layout:crop_layout(field_layout.crops)
    
    -- adjust screen level for each crop
    for i=1,#field_layout.crops,1
    do
      local rect_screen_Level_adj = i % 2 == 1 and 3 or 5
      local screen_level = (field_layout.screen_level - rect_screen_Level_adj)
      screen.level(screen_level)
      field_layout.crops[i]:display(screen_level)
      screen.level(field_layout.screen_level)
    end
  end
end

return field_layout
