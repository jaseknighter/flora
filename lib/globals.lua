-- global functions and variables 

-------------------------------------------
-- global functions
-------------------------------------------

set_dirty = function()
  clock.sleep(0.1)
  -- clock.sleep(0.05)
  if (pages.index == 4) then
    screen.clear()
  end

  screen_dirty = true
  clock.sleep(0.5)
  -- clock.sleep(0.1)
  screen_dirty = true
end

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

switch_active_plant = function()
  active_plant = active_plant == 1 and 2 or 1
  local inactive_plant = active_plant == 1 and 2 or 1
  plant1_screen_level = active_plant == 1 and 3 or 1
  plant2_screen_level = active_plant == 2 and 3 or 1
  plants[active_plant].set_active(true)
  plants[inactive_plant].set_active(false)
  envelopes[active_plant].set_active(true)
  envelopes[inactive_plant].set_active(false)
  set_midi_channels()
end

-------------------------------------------
-- global variables
-------------------------------------------
engine.name = 'BandSaw'

-- for params.lua
updating_controls = false
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

ENV_TIME_MAX = 2 -- DO NOT CHANGE
MAX_AMPLITUDE = 10
AMPLITUDE_DEFAULT = 2
MAX_ENV_LENGTH = 5 --10
ENV_LENGTH_DEFAULT = 2
CURVE_MIN = -10 -- -50
CURVE_MAX = 10 --50
MAX_ENVELOPE_NODES = 20

rqmin_min = 0.1
rqmin_max = 30
rqmax_min = 0.1
rqmax_max = 40
note_scalar_min = 0
note_scalar_max = 20

cf_scalars = {"cfs1","cfs2","cfs3","cfs4"}
cf_scalars_map = {0.5,1,2,4}
num_cf_scalars = #cf_scalars 
note_frequencies = {}
tempo_offset_note_frequencies = {}

plow1_times = {"plow1_time1","plow1_time2","plow1_time3","plow1_time4","plow1_time5","plow1_time6","plow1_time7","plow1_time8","plow1_time9","plow1_time10","plow1_time11","plow1_time12","plow1_time13","plow1_time14","plow1_time15","plow1_time16","plow1_time17","plow1_time18","plow1_time19","plow1_time20"}
plow1_levels = {"plow1_level1","plow1_level2","plow1_level3","plow1_level4","plow1_level5","plow1_level6","plow1_level7","plow1_level8","plow1_level9","plow1_level10","plow1_level11","plow1_level12","plow1_level13","plow1_level14","plow1_level15","plow1_level16","plow1_level17","plow1_level18","plow1_level19","plow1_level20"}
plow1_curves = {"plow1_curve1","plow1_curve2","plow1_curve3","plow1_curve4","plow1_curve5","plow1_curve6","plow1_curve7","plow1_curve8","plow1_curve9","plow1_curve10","plow1_curve11","plow1_curve12","plow1_curve13","plow1_curve14","plow1_curve15","plow1_curve16","plow1_curve17","plow1_curve18","plow1_curve19","plow1_curve20"}

plow2_times = {"plow2_time1","plow2_time2","plow2_time3","plow2_time4","plow2_time5","plow2_time6","plow2_time7","plow2_time8","plow2_time9","plow2_time10","plow2_time11","plow2_time12","plow2_time13","plow2_time14","plow2_time15","plow2_time16","plow2_time17","plow2_time18","plow2_time19","plow2_time20"}
plow2_levels = {"plow2_level1","plow2_level2","plow2_level3","plow2_level4","plow2_level5","plow2_level6","plow2_level7","plow2_level8","plow2_level9","plow2_level10","plow2_level11","plow2_level12","plow2_level13","plow2_level14","plow2_level15","plow2_level16","plow2_level17","plow2_level18","plow2_level19","plow2_level20"}
plow2_curves = {"plow2_curve1","plow2_curve2","plow2_curve3","plow2_curve4","plow2_curve5","plow2_curve6","plow2_curve7","plow2_curve8","plow2_curve9","plow2_curve10","plow2_curve11","plow2_curve12","plow2_curve13","plow2_curve14","plow2_curve15","plow2_curve16","plow2_curve17","plow2_curve18","plow2_curve19","plow2_curve20"}

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

-- for plant_sounds.lua 
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
MAX_SENTENCE_LENGTH = 500 --150

-- fpr water.lua
num_active_cf_scalars = 4

-- fpr fields.lua
num_active_fields = 1
field_width = (screen_size.x-7)/3
field_height = (screen_size.y-12)/2 - 6
fields_origin = vector:new(3,15)
field_row_spacing = 8

