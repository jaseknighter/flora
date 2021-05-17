-- garden/l_system_instructions (default)

------------------------------
-- notes:
-- see documentation on github for instructions on updating existing instructions and creating new ones:
--  https://github.com/jaseknighter/flora/blob/main/README.md
-- make sure the number_of_instructions variable is equal to the number of instructions listed 
--  in the l_system_instructions.get_instruction function
------------------------------

local garden = {}


-- local catalog = catalog_default
function garden.get_num_plants()
  return #garden_catalog
end

function garden.add(plant)
  table.insert(garden_catalog, plant)
  plant_name = plant.name
  -- local planted_plants_path = nursery_path .. "planted_plants"
  local planted_plants = tab.load(planted_plants_path) or {}
  table.insert(planted_plants, plant.name)
  tab.save(planted_plants, planted_plants_path)
end

function garden.remove(plant_name, author)
  -- remove from in memory plant catalog
  print("remove", plant_name, author)
  for i=1,#garden_catalog,1
  do
    -- print(garden_catalog[i].name)
    if garden_catalog[i].name and garden_catalog[i].name == plant_name then
      print("found plant_name to remove",plant_name)
      table.remove(garden_catalog, i)
    end
  end

  -- remove from saved file of planted plants
  local planted_plants = tab.load(planted_plants_path) or {}
  for i=1,#planted_plants,1
  do
    if planted_plants[i] == plant_name then
      print("found plant_name to remove in file",plant_name)
      table.remove(planted_plants, i)
      tab.save(planted_plants, planted_plants_path)
    end
  end


  table.insert(planted_plants, plant.name)
  tab.save(planted_plants, planted_plants_path)


end

function garden.get_instruction(instruction_id)
  -- local instruction = {}
  -- for i=1,1, garden.get_num_plants()
  -- do
  --   table.insert(instruction,default_instructions[instruction_id])
  -- end
  -- local instruction = default_instructions[instruction_id]
  return garden_catalog[instruction_id]
end

return garden
