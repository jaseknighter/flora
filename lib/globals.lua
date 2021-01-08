-- global functions and variables (including midi stuff)

-------------------------------------------
-- global functions
-------------------------------------------

page_scroll = function (delta)
  pages:set_index_delta(util.clamp(delta, -1, 1), false)
end

string_cut = function(str, start, finish)
  return string.sub(str, start, finish)
end

round_decimals = function (value_to_round, num_decimals, rounding_direction)
  local rounded_val
  local mult = 10^num_decimals
  if rounding_direction == "up" then
    rounded_val = math.floor(value_to_round * mult + 0.5) / mult
  else
    rounded_val = math.floor(value_to_round * mult + 0.5) / mult
  end
  return rounded_val
end

-------------------------------------------
-- midi stuff
-------------------------------------------
midi_connected = midi.connect()
midi_connected.event = function(data) 
--   -- tab.print(midi.to_msg(data)) 
  water.display() 
end

midi_out_channel1 = 1
midi_out_channel2 = 2

-------------------------------------------
-- global variables
-------------------------------------------
engine.name = 'BandSaw'

-- for params.lua
OUTPUT_DEFAULT = 4
SCREEN_FRAMERATE = 1/15
INITIAL_PLANT_INSTRUCTIONS_1 = 1
INITIAL_PLANT_INSTRUCTIONS_2 = 2
menu_status = false
pages = 0
flora_params = {}
options = {}
options.OUTPUT = {"audio", "midi", "audio + midi", "audio, c ii JF, c out 1+2", "c ii JF"}
options.SCALARS = {0.5,1,2,4}
options.NOTE_DURATIONS = {0.125, 0.25,0.5,0.75,1,1.5,2,4,8,16}
NOTE_DURATION_INDEX_DEFAULT_1 = 5
NOTE_DURATION_INDEX_DEFAULT_2 = 5
NOTE_FREQUENCY_NUMERATOR_MAX = 8
NOTE_FREQUENCY_DENOMINATOR_MAX = 8
note_frequencies_min = 1
note_frequencies_max = 8
note_frequencies_offset_min = -0.99
note_frequencies_offset_max = 0.99
tempo_scalar_offset_min = 0.1
tempo_scalar_offset_max = 2
tempo_scalar_offset_default = 1.5

num_cf_scalars_max = 4
num_cf_scalars_default = 1

MAX_AMPLITUDE = 10
AMPLITUDE_DEFAULT = 2
MAX_ENV_LENGTH = 10
ENV_LENGTH_DEFAULT = 2

rqmin_min = 0.1
rqmin_max = 30
rqmax_min = 0.1
rqmax_max = 40
note_scalar_min = 0
note_scalar_max = 20

cf_scalars = {"cfs1","cfs2","cfs3","cfs4"}
num_cf_scalars = #cf_scalars 
note_frequencies = {}
note_frequency_numerators = {"nf_numerator1","nf_numerator2","nf_numerator3","nf_numerator4","nf_numerator5","nf_numerator6"}
note_frequency_denominators = {"nf_denominator1","nf_denominator2","nf_denominator3","nf_denominator4","nf_denominator5","nf_denominator6"}
note_frequency_offsets = {"nf_offset1","nf_offset2","nf_offset3","nf_offset4","nf_offset5","nf_offset6"}

-- fpr flora.lua
ENV_MAX_LEVEL_DEFAULT = 4
alt_key_active = false
screen_level_graphics = 16
screen_size = vector:new(127,64)
center = vector:new(screen_size.x/2, screen_size.y/2)
pages = 1 -- WHAT IS THIS FOR?!?!?
num_pages = 5

plant1_screen_level = 3
plant2_screen_level = 1


plants = {}
num_plants = 2
active_plant = 1
initializing = true

envelopes = {}

screen_dirty = true
show_instructions = false

-- for plant.lua
l_system_instructions = {}

-- for sounds.lua 
note_scalar = 3
scale_length = 24
root_note_default = 45
scale_names = {}
notes = {}
current_note_indices = {}

for i= 1, #MusicUtil.SCALES do
  table.insert(scale_names, string.lower(MusicUtil.SCALES[i].name))
end

build_scale = function()
  notes = {}
  notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), scale_length)
  local num_to_add = scale_length - #notes
  for i = 1, num_to_add do
    table.insert(notes, notes[scale_length - num_to_add])
  end
end

set_scale_length = function()
  scale_length = params:get("scale_length")
end

-- for l_system.lua
MAX_SENTENCE_LENGTH = 150

-- fpr water.lua
num_active_cf_scalars = 4

-- fpr fields.lua
num_active_fields = 1
field_width = (screen_size.x-7)/3
field_height = (screen_size.y-12)/2 - 6
fields_origin = vector:new(3,15)
field_row_spacing = 8

