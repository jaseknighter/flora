-- required and included files

-- required for multiple files
MusicUtil = require "musicutil"
tabutil = require "tabutil"
listselect = require 'listselect'
textentry= require 'textentry'
fileselect = require 'fileselect'


-- required for flora.lua
UI = require "ui"
-- polls = include "floramx/lib/polls"

-- required for cloud.lua and save_load.lua
if util.file_exists(_path.code.."norns.online") then
  share=include("norns.online/lib/share")
end

-- required for parameters.lua
cs = require 'controlspec'
w_slash = include("floramx/lib/w_slash")

-- required for multiple files
include("floramx/lib/midi_helper")
vector = include("floramx/lib/vector")
globals = include("floramx/lib/globals")
parameters = include("floramx/lib/parameters")
save_load = include("floramx/lib/save_load")
sharer = include("floramx/lib/cloud")
instructions = include("floramx/lib/instructions")

-- required for flora.lua
encoders_and_keys = include("floramx/lib/encoders_and_keys")
flora_pages = include("floramx/lib/flora_pages")
plant = include("floramx/lib/plant")
modify = include("floramx/lib/modify")
envelope = include("floramx/lib/envelope")
water = include("floramx/lib/water")

-- required for plant.lua
plant_sounds = include("floramx/lib/plant_sounds") 
-- l_system_instructions_default = include("floramx/lib/gardens/".."garden_default")
-- l_system_instructions_community = include("floramx/lib/gardens/".."garden_community")
garden = include("floramx/lib/gardens/garden")
garden_catalog = include("floramx/lib/gardens/garden_catalog_default")
l_system = include("floramx/lib/l_system")
turtle_class = include("floramx/lib/turtle")
matrix_stack = include("floramx/lib/matrix_stack")
rule = include("floramx/lib/rule")

-- required for plant_sounds.lua
plant_sounds_externals = include("floramx/lib/plant_sounds_externals") 

-- required for modify.lua
-- fileselect = require 'fileselect'
-- textentry = require 'textentry'

-- required for envelope.lua
ArbGraph = include("floramx/lib/ArbitraryGraph")

-- required for water.lua
fields = include("floramx/lib/fields") 
decimal_to_fraction = include("floramx/lib/decimal_to_fraction") 

-- required for fields.lua
field_irrigation = include("floramx/lib/field_irrigation") 
field_layout = include("floramx/lib/field_layout") 

-- required for field_layout.lua
crop = include "floramx/lib/field_crop"

-- required for sequencing psets
pset_seq = include "floramx/lib/pset_sequencer"
