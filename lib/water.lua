-- output controls 

------------------------------
-- includes (found in includes.lua), todo list, and notes
--
-- includes: 
--  fields
--  decimal_to_fraction
--
-- todo list:
--  figure out a way to display tempo_scalar_offset 
--  consider adding a popup warning when an attempt is made to reduce note frequency below 0.2
--  replace magic numbers identifying indexes (like 3 and 5) with variables

-- notes:
--  note frequency is limited to 0.2 to prevent loud noises 
--    see https://doc.sccode.org/Classes/BPF.html for details
--  active_field mapping:
--    1: amp
--    2: p1 note duration
--    3: p2 note duration
--    4: note_scalar
--    5: num_active_cf_scalars
--    5+num_active_cf_scalars: cf_scalarX 
--    6+num_active_cf_scalars: rqmin
--    7+num_active_cf_scalars: rqmax
--    8+num_active_cf_scalars: # note frequencies
--    9+num_active_cf_scalars: note_frequencyX
------------------------------

local water = {}
water.__index = water

water.num_fields = 6
water.active_control = 1

local param_labels

local scalar_control_labels
local scalar_control_ids

local note_frequency_labels
local note_frequency_control_ids
local num_active_note_frequencies

local note_frequency_menu_index = nil

local note_frequency_id
local note_frequency
    
local num_field_menu_areas = 6
local active_field_menu_area = 1

water.set_param_labels = function()
  param_labels = {
    "amp",
    "p1 note dur",
    "p2 note dur",
    "note scalar",
    "# cf scalars",
    "rq min",
    "rq max",
    "# note freqs"
  }
end


water.set_scalar_control_labels = function()
  local labels = {}
  for i=1,num_active_cf_scalars,1
  do
    table.insert(labels, "cf scalar" .. i)
  end  
  scalar_control_labels = labels
end


water.set_scalar_control_ids = function()
  local ids = {}
  for i=1,num_active_cf_scalars,1
  do
    table.insert(ids, cf_scalars[i])
  end  
  scalar_control_ids = ids
end

--

water.set_note_frequency_control_labels = function()
  local labels = {}
  for i=1,num_active_note_frequencies,1
  do
    table.insert(labels, "nf" .. i)
  end  
  note_frequency_control_labels = labels
end

water.set_note_frequency_control_ids = function()
  local ids = {}
  for i=1,num_active_note_frequencies,1
  do
    table.insert(ids, note_frequencies[i])
  end  
  note_frequency_control_ids = ids
end

--

water.set_param_ids = function()
  water.param_ids = {
    "amp",
    "rqmin",
    "rqmax",
    "note_scalar",
    "# cf scalars",
    "num_active_cf_scalars",
    "plant_1_note_duration",
    "plant_2_note_duration",
    "num_active_note_frequencies"
  }
end

function water.update_controls()
  water.set_param_labels()
  water.set_param_ids()
  num_active_note_frequencies = params:get("num_note_frequencies")
  num_active_cf_scalars = params:get("num_active_cf_scalars")
  num_active_cf_scalars = params:get("num_active_cf_scalars")
  num_active_note_frequencies = params:get("num_note_frequencies")

  water.set_scalar_control_labels()
  for i=1,#scalar_control_labels,1
  do
    table.insert(
      param_labels,
      5+i,
      scalar_control_labels[i]
    )
  end

  water.set_scalar_control_ids()
  for i=1,#scalar_control_ids,1
  do
    table.insert(
      water.param_ids,
      5+i, -- replace magic number '5' with a constant
      scalar_control_ids[i]
    )
  end
  
  --

  water.set_note_frequency_control_labels()
  for i=1,#note_frequency_control_labels,1
  do
    table.insert(
      param_labels,
      8+num_active_cf_scalars+i,
      note_frequency_control_labels[i]
    )
  end

  water.set_note_frequency_control_ids()
  for i=1,#note_frequency_control_ids,1
  do
    table.insert(
      water.param_ids,
      8+num_active_cf_scalars+i, -- replace magic number '8' with a constant
      note_frequency_control_ids[i]
    )
  end
end

function water.init(num_fields)
  water.update_controls()
  fields.init(num_fields)
end

water.get_control_label = function ()
  local label = param_labels[water.active_control] .. " "
  local menu_index
  if water.active_control == 1 then
    label = label .. round_decimals(params:get("amp"), 2, down)
  elseif water.active_control == 2 then
    local duration = options.NOTE_DURATIONS[params:get("plant_1_note_duration")]
    label = label .. duration
    -- label = label .. round_decimals(params:get("rqmin"), 2, down)
  elseif water.active_control == 3 then
    local duration = options.NOTE_DURATIONS[params:get("plant_2_note_duration")]
    label = label .. duration
    -- label = label .. round_decimals(params:get("rqmax"), 2, down)
  elseif water.active_control == 4 then
    label = label .. math.floor(params:get("note_scalar"))
  elseif water.active_control == 5 then
    label = label .. math.floor(num_active_cf_scalars)
  elseif water.active_control <= 5 + num_active_cf_scalars then
    
    local cf_scalar_id = (water.active_control-5)
    local cf_scalar = cf_scalars[cf_scalar_id]
    local current_value = params:get(cf_scalar)
    label = label .. options.SCALARS[current_value]
  elseif water.active_control == 6 + num_active_cf_scalars then
    label = label .. round_decimals(params:get("rqmin"), 2, down)
    -- local duration = options.NOTE_DURATIONS[params:get("plant_1_note_duration")]
    -- label = label .. duration
  elseif water.active_control == 7 + num_active_cf_scalars and 
    param_labels[water.active_control] then
    label = label .. round_decimals(params:get("rqmax"), 2, down)
    -- local duration = options.NOTE_DURATIONS[params:get("plant_2_note_duration")]
    -- label = label .. duration
  elseif water.active_control == 8 + num_active_cf_scalars then
    label = label .. num_active_note_frequencies
  elseif water.active_control > 8 + num_active_cf_scalars then
    note_frequency_id = (water.active_control - 8 - num_active_cf_scalars)
    note_frequency = note_frequencies[note_frequency_id]
        
    local nfn = params:get(note_frequency_numerators[note_frequency_id])
    local nfd = params:get(note_frequency_denominators[note_frequency_id])
    local nfo = params:get(note_frequency_offsets[note_frequency_id])
    nfo = nfo >= 0 and "+"..nfo or nfo
    
    -- local tempo_scalar_offset = params:get("tempo_scalar_offset")
    
    local note_frequency_fraction = decimal_to_fraction(note_frequency,1E-2)
    
    local note_frequency_fraction_label
    if type(note_frequency_fraction) == "number" then
      note_frequency_fraction_label = math.floor(note_frequency_fraction) .. "/" .. 1 
    else
      note_frequency_fraction_label = note_frequency_fraction[1] .. "/" .. note_frequency_fraction[2]
    end
    local note_frequency_label =  
        "["  .. 
        nfn .. 
        "/(" .. 
        math.floor(nfd) .. 
        nfo .. 
        ")] "
        -- .. "* " .. tempo_scalar_offset
        ..note_frequency_fraction_label
        
    label = label .. note_frequency_label
    menu_index = note_frequency_menu_index
  end
  return {label,menu_index}
  
end
  

water.key = function(n, delta, alt_key_active)
  -- do something?
end

water.enc = function(n, delta, alt_key_active)
  -- set variables needed by each page/example
  if n == 1 then
    -- do nothing here
  elseif n == 2 then 
    local incr = util.clamp(delta, -1, 1)
    if water.active_control <= 8 + num_active_cf_scalars then
      water.active_control = util.clamp(incr + water.active_control, 1, #water.param_ids)
    end
    if water.active_control > 8 + num_active_cf_scalars then
      if note_frequency_menu_index == nil and incr == 1 then
        note_frequency_menu_index = 1
      -- elseif incr == 1 and note_frequency_menu_index < 4 then
      elseif incr == 1 and note_frequency_menu_index < 3 then
        note_frequency_menu_index = note_frequency_menu_index + incr
      elseif incr == -1 and note_frequency_menu_index > 1 then
        note_frequency_menu_index = note_frequency_menu_index + incr
      elseif incr == -1 and  
        note_frequency_menu_index == 1 and 
        water.active_control > 9 + num_active_cf_scalars then
        water.active_control = util.clamp(incr + water.active_control, 1, #water.param_ids)
        note_frequency_menu_index = 3
      --   note_frequency_menu_index = 4
      -- elseif incr == 1 and note_frequency_menu_index == 4 
      elseif incr == 1 and note_frequency_menu_index == 3
        and param_labels[water.active_control+1] then
        water.active_control = incr + water.active_control
        note_frequency_menu_index = 1
      elseif incr == -1 then
        water.active_control = util.clamp(incr + water.active_control, 1, #water.param_ids)
        note_frequency_menu_index = nil
      end
    end
    
    if water.active_control == 1 then
      active_field_menu_area = 1
    elseif water.active_control == 2 or water.active_control == 3 then
      active_field_menu_area = 2
    elseif water.active_control == 4 then
      active_field_menu_area = 3
    elseif water.active_control == 5 then
      active_field_menu_area = 4
    elseif water.active_control < 6 + num_active_cf_scalars then
      active_field_menu_area = 4
    elseif water.active_control < 8 + num_active_cf_scalars then
      active_field_menu_area = 5
    else
      active_field_menu_area = 6
    end
    fields.display()

  elseif n == 3 then 
    local incr = util.clamp(delta, -1, 1)
    if water.active_control == 1 then
      incr = alt_key_active == true and incr * 0.1 or incr
      local amp = params:get("amp")
      local new_value = util.clamp(incr + amp, 0, 10)
      params:set("amp",new_value)

  
  
  elseif water.active_control == 2 then
      local current_value = params:get("plant_1_note_duration")
      local range = params:get_range("plant_1_note_duration")
      local new_value = util.clamp(incr + current_value, range[1], range[2])
      params:set("plant_1_note_duration",new_value)
    elseif water.active_control == 3 then
      local current_value = params:get("plant_2_note_duration")
      local range = params:get_range("plant_2_note_duration")
      local new_value = util.clamp(incr + current_value, range[1], range[2])
      params:set("plant_2_note_duration",new_value)
    elseif water.active_control == 4 then
      incr = alt_key_active == true and incr * 0.1 or incr
      local note_scalar = params:get("note_scalar")
      local new_value = util.clamp(incr + note_scalar, note_scalar_min, note_scalar_max)
      params:set("note_scalar",new_value)
    elseif water.active_control == 5 then
      local range = params:get_range("num_active_cf_scalars")
      local new_value = util.clamp(incr + num_active_cf_scalars, range[1], range[2])
      params:set("num_active_cf_scalars",new_value)
    elseif water.active_control <= 5 + num_active_cf_scalars then
      local cf_scalar_id = (water.active_control - 5)
      local cf_scalar = cf_scalars[cf_scalar_id]
      local current_value = params:get(cf_scalar)
      local range = params:get_range(cf_scalar)
      local new_value = util.clamp(incr + current_value, range[1], range[2])
      params:set(cf_scalar,new_value)
    elseif water.active_control == 6 + num_active_cf_scalars then
      incr = alt_key_active == true and incr * 0.1 or incr
      local current_value = params:get("rqmin")
      local new_value = incr + current_value
      new_value = util.clamp(new_value, rqmin_min, rqmin_max)
      if current_value == 0.1 and incr == 1 then new_value = 1 end
      params:set("rqmin",new_value)
    elseif water.active_control == 7 + num_active_cf_scalars then
      incr = alt_key_active == true and incr * 0.1 or incr
      local current_value = params:get("rqmax")
      local new_value = incr + current_value
      new_value = util.clamp(new_value, rqmax_min, rqmax_max)
      if current_value == 0.1 and incr == 1 then new_value = 1 end
      params:set("rqmax",new_value)
    elseif water.active_control == 8 + num_active_cf_scalars then
      local range = params:get_range("num_note_frequencies")
      local new_value = util.clamp(incr + num_active_note_frequencies, range[1], range[2])
      params:set("num_note_frequencies",new_value)
    elseif water.active_control > 8 + num_active_cf_scalars then
      local range
      local new_value
      
      
      local note_frequency_numerator = note_frequency_numerators[note_frequency_id]
      local nfn = params:get(note_frequency_numerator)
      
      local note_frequency_denominator = note_frequency_denominators[note_frequency_id]
      local nfd = params:get(note_frequency_denominator)
        
      local note_frequency_offset = note_frequency_offsets[note_frequency_id]
      local nfo = params:get(note_frequency_offset)
        
      if note_frequency_menu_index == 1 then
        new_value = util.clamp(incr + nfn, 1, NOTE_FREQUENCY_NUMERATOR_MAX)
        if (new_value/(nfd+nfo)>= 0.2) then
          params:set(note_frequency_numerator,new_value)
        else
          print("note frequency is limited to 0.2 to prevent loud noises!")
        end
      elseif note_frequency_menu_index == 2 then
        new_value = util.clamp(incr + nfd, 1, NOTE_FREQUENCY_DENOMINATOR_MAX)
        if (nfn/(new_value+nfo)>= 0.2) then
          params:set(note_frequency_denominator,new_value)
        else
          print("note frequency is limited to 0.2 to prevent loud noises!")
        end
      elseif note_frequency_menu_index == 3 then
        if ((incr == 1 and nfo == -0.99) or (incr == -1 and nfo == 0.99)) and 
          alt_key_active == false then 
            -- if alt_key is not active and current value is -0.99 or 0.99 increment by +/- 0.09 instead of 0.1 
            new_value = -incr * 0.9 
        else
          incr = alt_key_active == true and incr * 0.01 or incr * 0.1
          new_value = util.clamp(incr + nfo, note_frequencies_offset_min, note_frequencies_offset_max)
        end
        if (nfn/(nfd+new_value) >= 0.2) then
          params:set(note_frequency_offset,new_value)
        else
          print("note frequency is limited to 0.2 to prevent loud noises!")
        end
      end
    end
    fields.display()
  end
end

water.draw_fields = function()
-- TODO: replace magic number 6 with constant

  screen.level(5)
  screen.aa(1)
  fields:redraw(
    water.active_control - (8 + num_active_cf_scalars),
    note_frequency_menu_index,
    active_field_menu_area,
    water.active_control)
  screen.update()
  screen.aa(0)
end

water.display = function()
  water.redraw()
  fields.display()
end

water.draw_water_nav = function()
  screen.level(10)
  screen.rect(2,10, screen_size.x-2, 3)
  screen.fill()
  screen.level(0)
  local area_menu_width = (screen_size.x-5)/num_field_menu_areas
  screen.rect(2+(area_menu_width*(active_field_menu_area-1)),10, area_menu_width, 3)
  screen.fill()
  screen.level(4)
  for i=1, num_field_menu_areas+1,1
  do
    if i < num_field_menu_areas+1 then
      screen.rect(2+(area_menu_width*(i-1)),10, 1, 3)
    else
      screen.rect(2+(area_menu_width*(i-1))-1,10, 1, 3)
    end
  end
  screen.fill()
end

water.redraw = function ()
  if show_instructions ~= true then
    water.update_controls()
    water.draw_fields()
  end
end

return water
