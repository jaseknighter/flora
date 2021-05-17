local save_load = {}

function save_load.collect_data_for_save()
  local current_instruction = plants[active_plant].get_current_instruction()
  return plants[active_plant].get_instructions(current_instruction)
end

function save_load.save_plant_to_nursery(plant_name)
  if plant_name then
    -- local dirname = _path.data.."cheat_codes/external-timing/"
    if os.rename(nursery_path, nursery_path) == nil then
      os.execute("mkdir " .. nursery_path)
    end
    
    local save_path = nursery_path .. plant_name  ..".flora"
    local data_for_save = save_load.collect_data_for_save(plant_name)
    -- print("saving plant " .. active_plant .. "...")
    -- print("to ..." .. save_path)
    -- tab.print(data_for_save)
    tab.save(data_for_save, save_path)
    -- params:write(save_path .. ".pset")
    print("saved!")
  else
    print("save cancel")
  end
end

function save_load.remove_plant_from_nursery(path)
   if string.find(path, 'flora') ~= nil then
    print("removing...")
    local data = tab.load(path)
    if data ~= nil then
      print("plant found", path)
      -- fn.load(data)
      -- params:read(norns.state.data .. gardening ..".pset")
      
      -- plant_to_plant = tab.load (path)
      local plant_to_remove = string.gsub(path,nursery_path,"")
      -- plant_to_remove.name=plant_filename
      garden.remove(plant_to_remove)
      os.execute("rm -rf "..path)


      -- print ('loaded ' .. norns.state.data .. data.arcology_name)
    else
      print("no data")
    end
  end
end


function save_load.add_plant_to_garden(path)
   if string.find(path, 'flora') ~= nil then
    print("adding...")
    local data = tab.load(path)
    if data ~= nil then
      print("plant found", path)
      -- fn.load(data)
      -- params:read(norns.state.data .. gardening ..".pset")
      plant_to_plant = tab.load (path)
      local plant_filename = string.gsub(path,nursery_path,"")
      plant_to_plant.name=plant_filename
      garden.add(plant_to_plant)

      -- print ('loaded ' .. norns.state.data .. data.arcology_name)
    else
      print("no data")
    end
  end
end

function save_load.remove_plant_from_garden(plant_to_remove)
  print("removing plant...", plant_to_remove)
  if plant_to_remove ~= "cancel" then
    if string.find(plant_to_remove, 'flora') ~= nil then
    -- local data = tab.load(path)
      -- if plant_to_remove ~= nil then
      -- local plant_filename = string.gsub(path,nursery_path,"")
      -- print("plant found", plant_filename)
      garden.remove(plant_to_remove)
  
       -- print ('loaded ' .. norns.state.data .. data.arcology_name)
    else
     print("no plant found")
    -- end
    end
 end
end


function save_load.init()
  params:add_separator()
  params:add_separator("COMMUNITY GARDENING")

  params:add_trigger("save_plant_to_nursery", "> SAVE PLANT TO NURSERY")
  params:set_action("save_plant_to_nursery", function(x) textentry.enter(save_load.save_plant_to_nursery) end)

  params:add_trigger("remove_plant_from_nursery", "< REMOVE PLANT FROM NURSERY")
  params:set_action("remove_plant_from_nursery", function(x) fileselect.enter(norns.state.data .. 'nursery/', save_load.remove_plant_from_nursery) end)

  params:add_trigger("add_plant_to_garden", "> ADD PLANT TO GARDEN" )
  params:set_action("add_plant_to_garden", function(x) fileselect.enter(norns.state.data .. 'nursery/', save_load.add_plant_to_garden) end)

  params:add_trigger("remove_plant_from_garden", "< REMOVE PLANT FROM GARDEN" )

  params:set_action("remove_plant_from_garden", function(x) 
    local planted_plants = tab.load(planted_plants_path) or {"no plants planted"}
    listselect.enter(planted_plants, save_load.remove_plant_from_garden) 
  end)

  -- params:set_action("remove_plant", function(x) fileselect.enter(norns.state.data .. 'nursery/', save_load.remove_plant) end)

  -- params:add_option("crypts_directory", "CRYPT(S)", filesystem.crypts_names, 1)
  -- params:set_action("crypts_directory", function(index) filesystem:set_crypt(index) end)


  -- params:default()
  -- params:bang()
end

return save_load