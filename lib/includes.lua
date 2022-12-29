-- required and included files

-- required for multiple files
MusicUtil = require "musicutil"
tabutil = require "tabutil"
listselect = require 'listselect'
textentry= require 'textentry'
fileselect = require 'fileselect'


-- required for flora.lua
UI = require "ui"
-- polls = include "flora/lib/polls"

-- required for cloud.lua and save_load.lua
if util.file_exists(_path.code.."norns.online") then
  share=include("norns.online/lib/share")
end

-- required for lfos
Lattice = require 'lattice'


-- required for parameters.lua
cs = require 'controlspec'
w_slash = include("flora/lib/w_slash")

-- required for multiple files
include("flora/lib/midi_helper")
vector = include("flora/lib/vector")
globals = include("flora/lib/globals")
parameters = include("flora/lib/parameters")
save_load = include("flora/lib/save_load")
sharer = include("flora/lib/cloud")
instructions = include("flora/lib/instructions")
lfo = include("flora/lib/hnds")


-- required for flora.lua
encoders_and_keys = include("flora/lib/encoders_and_keys")
flora_pages = include("flora/lib/flora_pages")
plant = include("flora/lib/plant")
modify = include("flora/lib/modify")
envelope = include("flora/lib/envelope")
water = include("flora/lib/water")

-- required for plant.lua
plant_sounds = include("flora/lib/plant_sounds") 
-- l_system_instructions_default = include("flora/lib/gardens/".."garden_default")
-- l_system_instructions_community = include("flora/lib/gardens/".."garden_community")
garden = include("flora/lib/gardens/garden")
garden_catalog = include("flora/lib/gardens/garden_catalog_default")
l_system = include("flora/lib/l_system")
turtle_class = include("flora/lib/turtle")
matrix_stack = include("flora/lib/matrix_stack")
rule = include("flora/lib/rule")

-- required for plant_sounds.lua
plant_sounds_externals = include("flora/lib/plant_sounds_externals") 

-- required for modify.lua
-- fileselect = require 'fileselect'
-- textentry = require 'textentry'

-- required for envelope.lua
ArbGraph = include("flora/lib/ArbitraryGraph")

-- required for water.lua
fields = include("flora/lib/fields") 
decimal_to_fraction = include("flora/lib/decimal_to_fraction") 

-- required for fields.lua
field_irrigation = include("flora/lib/field_irrigation") 
field_layout = include("flora/lib/field_layout") 

-- required for field_layout.lua
crop = include "flora/lib/field_crop"

-- required for sequencing plant generations
p_gen_seq = include "flora/lib/plant_gen_sequencer"

-- required for sequencing psets
pset_seq = include "flora/lib/pset_sequencer"
