-- field irrigation 
-- graphical representations of the following output parameters:
--    plant 1/2 note duration (all outputs)
--    note scalar (all outputs)
--    center frequency scalars (bandsaw)
--    rq min/max (bandsaw)

------------------------------
-- notes:
--  active_field mapping
--    1: amp
--    2: qmin
--    3: qmax
--    4: note_scalar
--    5: num_active_cf_scalars
--    5+num_active_cf_scalars: cf_scalarX 
--    6+num_active_cf_scalars: p1 note duration
--    7+num_active_cf_scalars: p2 note duration

--  nomenclature:
--    fields:	made up of one or more field (default is 6 fields)
--      field:	made up of one or more plots plots (default is 2 plots)
--        plot:	made up of (one) land and (one or more) crop
--          land:	always the size of a plot 
--          crop:	one or more rectangular or circular shape
------------------------------

local fields_irrigation = {}


fields_irrigation.get_west_irrigation_values = function()
  local top = params:get("plant_1_note_duration")
  local bottom = params:get("plant_2_note_duration")
  return({{top, 1, #options.NOTE_DURATIONS},{bottom, 1, #options.NOTE_DURATIONS}})
end

fields_irrigation.get_east_irrigation_values = function()
  local top = params:get("rqmin")
  local bottom = params:get("rqmax")
  return({{top, rqmin_min, rqmin_max},{bottom, rqmax_min, rqmax_max}})
end


fields_irrigation.get_central_irrigation_values = function()
  local west = params:get("note_scalar")
  local west_range_min = note_scalar_min
  local west_range_max = note_scalar_max
  local east = num_active_cf_scalars
  local east_values = {}
  for i=1,num_active_cf_scalars,1
  do
    local scalar_id = cf_scalars[i]
    local scalar_value = params:get(scalar_id)
    table.insert(east_values, scalar_value)
  end
  return{{west, west_range_min, west_range_max},{east, east_values}}
end

function fields_irrigation.clear_irrigation(x,y,w,h)
  -- clear old irrigation ditches
  screen.level(0)
  screen.rect(x,y,w,h)
  screen.fill()
end

function fields_irrigation:lay_irrigation(x,y,w,h, screen_level)
  -- draw new irrigation ditch
  screen.aa(0)
  screen.level(screen_level)
  screen.rect(x,y,w,h)
  screen.fill()
  screen.aa(1)
end

function fields_irrigation:irrigate(active_field_menu_area)
  -- get irrigation values
  local west_irrigation_values = fields_irrigation.get_west_irrigation_values()
  local north_west_irrigation_length = util.linlin (west_irrigation_values[1][2], west_irrigation_values[1][3], 1, field_height/2, west_irrigation_values[1][1])
  local south_west_irrigation_length = util.linlin (west_irrigation_values[2][2], west_irrigation_values[2][3], 1, field_height/2, west_irrigation_values[2][1])

  local east_irrigation_values = fields_irrigation.get_east_irrigation_values()
  local north_east_irrigation_length = util.linlin (east_irrigation_values[1][2], east_irrigation_values[1][3], 1, field_height/2, east_irrigation_values[1][1])
  local south_east_irrigation_length = util.linlin (east_irrigation_values[2][2], east_irrigation_values[2][3], 1, field_height/2, east_irrigation_values[2][1])

  local central_irrigation_values = fields_irrigation.get_central_irrigation_values()
  local north_central_width = num_active_fields < 4 and (field_width*num_active_fields) or (field_width*3)
  local north_central_irrigation_length = util.linlin (central_irrigation_values[1][2], central_irrigation_values[1][3], 1, north_central_width, central_irrigation_values[1][1])
  local south_central_irrigation_levels = central_irrigation_values[2][2]
  
  local fields_width = num_active_fields < 4 and field_width * num_active_fields or field_width * (num_active_fields-3)

  -- -- clear ditches irrigation
  -- --  clear west irrigation
  fields_irrigation.clear_irrigation(fields_origin.x-3, fields_origin.y-2, 3, 2+(field_height * 2) + field_row_spacing+6)
  
  --  clear east irrigation
  local irrigation_x = num_active_fields < 4 and field_width * num_active_fields or field_width * 3
  irrigation_x = irrigation_x + fields_origin.x
  fields_irrigation.clear_irrigation(irrigation_x, fields_origin.y-2, screen_size.x, (field_height * 2) + field_row_spacing + 6)
  
  --  clear central irrigation
  fields_irrigation.clear_irrigation(
    fields_origin.x, 
    fields_origin.y + field_height, 
    field_width * 4, 
    field_row_spacing)

  -- clear top and bottom
  local highlight_top_width = num_active_fields < 4 and field_width * num_active_fields or field_width * 3
  fields_irrigation.clear_irrigation(fields_origin.x, fields_origin.y-2, highlight_top_width, 2, 0)
  fields_irrigation.clear_irrigation(fields_origin.x, fields_origin.y+(field_height*2)+field_row_spacing, highlight_top_width, 1, 0)
  
  -- draw nw irrigation
  fields_irrigation:lay_irrigation(fields_origin.x-3, fields_origin.y+field_height/2-north_west_irrigation_length, 2, north_west_irrigation_length, 10)
  if num_active_fields > 3 then
    fields_irrigation:lay_irrigation(
      fields_origin.x-3,
      fields_origin.y+field_height+field_height/2 + field_row_spacing - north_west_irrigation_length, 
      2, 
      north_west_irrigation_length,
      10)
  end
  
  -- draw sw irrigation
  fields_irrigation:lay_irrigation(
    fields_origin.x-3,
    fields_origin.y+field_height/2,
    2, 
    south_west_irrigation_length,
    5
  )
    
  if num_active_fields > 3 then
    fields_irrigation:lay_irrigation(
      fields_origin.x-3,
      fields_origin.y+field_height+field_height/2 + field_row_spacing, 
      2, 
      south_west_irrigation_length,
      5
      )
  end
  
  local east_x = num_active_fields < 4 and fields_origin.x+fields_width+1 or fields_origin.x+(field_width*3) + 1
  
  -- draw ne irrigation
  fields_irrigation:lay_irrigation(
    east_x,
    fields_origin.y+field_height/2-north_east_irrigation_length, 
    2, 
    north_east_irrigation_length, 
    10)
  if num_active_fields > 3 then
    fields_irrigation:lay_irrigation(
      fields_origin.x+fields_width+1,
      fields_origin.y+field_height+field_height/2 + field_row_spacing - north_east_irrigation_length, 
      2, 
      north_east_irrigation_length,
      10)
  end
      
  -- draw se irrigation
    fields_irrigation:lay_irrigation(
      east_x,
      fields_origin.y+field_height/2,
      2, 
      south_east_irrigation_length,
      5
      )
  if num_active_fields > 3 then 
    fields_irrigation:lay_irrigation(
      fields_origin.x+(fields_width)+1,
      fields_origin.y+field_height+field_height/2 + field_row_spacing, 
      2, 
      south_east_irrigation_length,
      5
      )
  end
  
  -- draw north central irrigation
  fields_irrigation:lay_irrigation(
    fields_origin.x,
    fields_origin.y + field_height + 2,
    north_central_irrigation_length,
    2,
    5
  )
  -- draw tick marks
  for i=0, 1, 1
  do
    local x
    if i == 1 then
      x = num_active_fields < 4 and fields_origin.x + fields_width - 1 or fields_origin.x + (field_width * 3) - 1
    else 
      x = fields_origin.x
    end
    
    fields_irrigation:lay_irrigation(
      x,
      fields_origin.y + field_height + 2,
      1,
      2,
      15
    )
  end


  -- draw south central irrigation
  local width_multiplier = num_active_fields < 4 and num_active_fields or 3
  -- local segment_width = ((field_width / num_active_cf_scalars) * width_multiplier) / 2
  local segment_width = ((field_width / num_active_cf_scalars) * width_multiplier) 
  for i=1, num_active_cf_scalars, 1
  do
    fields_irrigation:lay_irrigation(
      fields_origin.x + (segment_width * (i-1)),
      fields_origin.y + field_height + 4,
      segment_width,
      2,
      (south_central_irrigation_levels[i]*3)
    )
  end
  
  -- draw tick marks
  local tick_height = active_field_menu_area == 4 and 3 or 2
  for i=0, num_active_cf_scalars, 1
  do
    local x
    if i == num_active_cf_scalars then
      x = fields_origin.x + (segment_width * i) - 1
    else 
      x = fields_origin.x + (segment_width * i)
    end
    
    fields_irrigation:lay_irrigation(
      x,
      fields_origin.y + field_height + 4,
      1,
      tick_height,
      15
    )
  end

  
end

function fields_irrigation:highlight_irrigation_area(active_field_menu_area, active_control)
  -- highlight active field
  if active_field_menu_area == 1 then
    -- do nothing
  elseif active_field_menu_area == 2 then
    --highlight west irrigation
    -- local irrigation_x
    if active_control == 2 then
      irrigation_y = fields_origin.y
    else
      irrigation_y = fields_origin.y + (field_height/2)
    end
    
    fields_irrigation:lay_irrigation(fields_origin.x-1,irrigation_y, 1, field_height/2, 12)
    fields_irrigation:lay_irrigation(fields_origin.x-3, fields_origin.y - 1, 3, 1, 12)
    fields_irrigation:lay_irrigation(fields_origin.x-3, fields_origin.y+field_height, 3, 1, 12)
    if num_active_fields > 3 then
      fields_irrigation:lay_irrigation(fields_origin.x-1, irrigation_y + field_height + field_row_spacing, 1, field_height/2, 15)

      fields_irrigation:lay_irrigation(fields_origin.x-3, fields_origin.y + field_height + field_row_spacing - 1, 3, 1, 12)
      fields_irrigation:lay_irrigation(fields_origin.x-3, fields_origin.y + (field_height*2) + field_row_spacing, 3, 1, 12)
    end
  elseif active_field_menu_area == 3 then
    -- highlight north central irrigation
    local highlight_width = num_active_fields < 4 and field_width * num_active_fields or field_width * 3
    fields_irrigation:lay_irrigation(fields_origin.x, fields_origin.y+field_height+1, highlight_width, 1, 12)
  elseif active_field_menu_area == 4 then
    -- highlight south central irrigation
    local highlight_width = num_active_fields < 4 and field_width * num_active_fields or field_width * 3
    if active_control == 5 then
      fields_irrigation:lay_irrigation(fields_origin.x, fields_origin.y+field_height+field_row_spacing - 2, highlight_width, 1, 12)
    else
      fields_irrigation:lay_irrigation(fields_origin.x + (highlight_width/num_active_cf_scalars*(active_control-6)), fields_origin.y+field_height+field_row_spacing - 2, highlight_width/num_active_cf_scalars, 1, 8)
    end
  elseif active_field_menu_area == 5 then
    --highlight east irrigation
    local irrigation_x = num_active_fields < 4 and field_width * num_active_fields or field_width * 3
    irrigation_x = irrigation_x + fields_origin.x
    if active_control == 6 + num_active_cf_scalars then
      irrigation_y = fields_origin.y
    else
      irrigation_y = fields_origin.y + (field_height/2)
    end
    
    fields_irrigation:lay_irrigation(irrigation_x,irrigation_y, 1, field_height/2, 12)
    fields_irrigation:lay_irrigation(irrigation_x, fields_origin.y - 1, 3, 1, 12)
    fields_irrigation:lay_irrigation(irrigation_x, fields_origin.y+field_height, 3, 1, 12)
    if num_active_fields > 3 then
      fields_irrigation:lay_irrigation(field_width * (num_active_fields-3) + 3, irrigation_y + field_height + field_row_spacing, 1, field_height/2, 15)
      fields_irrigation:lay_irrigation(field_width * (num_active_fields-3) + 3, fields_origin.y + field_height + field_row_spacing - 1, 3, 1, 12)
      fields_irrigation:lay_irrigation(field_width * (num_active_fields-3) + 3, fields_origin.y + (field_height*2) + field_row_spacing, 3, 1, 12)
    end
  elseif active_field_menu_area == 6 then
    --highlight note frequencies
    local highlight_top_width = num_active_fields < 4 and field_width * num_active_fields or field_width * 3
    fields_irrigation:lay_irrigation(fields_origin.x, fields_origin.y-2, highlight_top_width, 2, 15)
    if num_active_fields > 3 then
      fields_irrigation:lay_irrigation(fields_origin.x, fields_origin.y+field_height*2+field_row_spacing, field_width * (num_active_fields-3), 1, 15)
    end
    local num_active_note_frequencies = params:get("num_note_frequencies")
  end
end

return fields_irrigation