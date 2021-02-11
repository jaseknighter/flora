-- required and included files

-- required for multiple files
MusicUtil = require "musicutil"
tabutil = require "tabutil"

-- required for flora.lua
UI = require "ui"
-- polls = include "flora/lib/polls"

-- required for parameters.lua
cs = require 'controlspec'

-- required for multiple files
vector = include("flora/lib/vector")
globals = include "flora/lib/globals"
include "flora/lib/midi_helper"
parameters = include "flora/lib/parameters"
instructions = include "flora/lib/instructions"

-- required for flora.lua
encoders_and_keys = include "flora/lib/encoders_and_keys"
flora_pages = include("flora/lib/flora_pages")
plant = include("flora/lib/plant")
envelope = include "flora/lib/envelope"
water = include "flora/lib/water"

-- required for plant.lua
plant_sounds = include("flora/lib/plant_sounds") 
l_system_instructions_default = include("flora/lib/gardens/".."garden_default")
l_system_instructions_community = include("flora/lib/gardens/".."garden_community")
l_system = include("flora/lib/l_system")
turtle_class = include("flora/lib/turtle")
matrix_stack = include("flora/lib/matrix_stack")
rule = include("flora/lib/rule")

-- required for plant_sounds.lua
plant_sounds_externals = include("flora/lib/plant_sounds_externals") 

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

-- required for sequencing psets
pset_seq = include "flora/lib/pset_sequencer"
