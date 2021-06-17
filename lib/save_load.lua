local save_load = {}

function save_load.collect_data_for_save()
  local current_instruction = plants[active_plant].get_current_instruction()
  return plants[active_plant].get_instructions(current_instruction)
end

function save_load.save_plant_to_nursery(plant_name)
  if plant_name then
    if os.rename(nursery_path, nursery_path) == nil then
      os.execute("mkdir " .. nursery_path)
    end
    
    local save_path = nursery_path .. plant_name  ..".flora"
    local data_for_save = save_load.collect_data_for_save(plant_name)
    tab.save(data_for_save, save_path)
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
      local plant_to_remove = string.gsub(path,nursery_path,"")
      garden.remove(plant_to_remove)
      os.execute("rm -rf "..path)
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
      plant_to_plant = tab.load (path)
      local plant_filename = string.gsub(path,nursery_path,"")
      plant_to_plant.name=plant_filename
      garden.add(plant_to_plant)
    else
      print("no data")
    end
  end
end

function save_load.remove_plant_from_garden(plant_to_remove)
  print("removing plant...", plant_to_remove)
  if plant_to_remove ~= "cancel" then
    if string.find(plant_to_remove, 'flora') ~= nil then
      garden.remove(plant_to_remove)
  else
     print("no plant found")
    end
 end
end


--[[
-- code from norns_online lua (probably not needed)
function refresh_directory()
  if not refreshed_dir then
    refreshed_dir=true 
    uimessage="refreshing directory..."
    redraw()
    share.make_virtual_directory()
    uimessage=""
    redraw()
  end
end

function show_message(message)
  uimessage=message
  redraw()
  clock.run(function()
    clock.sleep(1)
    uimessage=""
    redraw()
  end)
end

function save_load.download_from_norns_online()
-- elseif mode==2 or mode ==3 then
  -- download
  local dirtogo=""
  -- if mode ==3 then 
  --   dirtogo=""
  -- end
  refresh_directory()
  fileselect.enter(share.get_virtual_directory(dirtogo),function(x)
    if x == "cancel" then 
      do return end 
    end 
    uimessage="downloading..."
    redraw()
    msg = share.download_from_virtual_directory(x)
    show_message(msg)
    redraw()
  end)
end

function redraw()
  if uimessage~="" then
    screen.level(15)
    local x=64
    local y=28
    local w=string.len(uimessage)*6
    screen.rect(x-w/2,y,w,10)
    screen.fill()
    screen.level(15)
    screen.rect(x-w/2,y,w,10)
    screen.stroke()
    screen.move(x,y+7)
    screen.level(0)
    screen.text_center(uimessage)
  end
end
]]

function save_load.init()
  params:add_separator()
  params:add_separator("GARDENING")

  params:add_trigger("save_plant_to_nursery", "> SAVE PLANT TO NURSERY")
  params:set_action("save_plant_to_nursery", function(x) textentry.enter(save_load.save_plant_to_nursery) end)

  params:add_trigger("remove_plant_from_nursery", "< REMOVE PLANT FROM NURSERY")
  params:set_action("remove_plant_from_nursery", function(x) fileselect.enter(_path.data .. "flora/" .. 'nursery/', save_load.remove_plant_from_nursery) end)

  params:add_trigger("add_plant_to_garden", "> ADD PLANT TO GARDEN" )
  params:set_action("add_plant_to_garden", function(x) fileselect.enter(_path.data .. "flora/" .. 'nursery/', save_load.add_plant_to_garden) end)

  params:add_trigger("remove_plant_from_garden", "< REMOVE PLANT FROM GARDEN" )

  params:set_action("remove_plant_from_garden", function(x) 
    local planted_plants = tab.load(planted_plants_path) or {"no plants planted"}
    listselect.enter(planted_plants, save_load.remove_plant_from_garden) 
  end)

  -- params:set_action("remove_plant", function(x) fileselect.enter(_path.data .. "flora/" .. 'nursery/', save_load.remove_plant) end)
end

return save_load
