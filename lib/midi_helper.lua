-- midi helper global variables and functions 
--  including sysex code for the 16n faderbank

midi_out_device = midi.connect(1)

set_midi_channels = function()
  if pages.index == 4 then
    if active_plant == 1 then
      if device_16n then set_16n_channel_and_cc_values(plow1_cc_channel) end
    else
      if device_16n then set_16n_channel_and_cc_values(plow2_cc_channel) end
    end
  elseif pages.index == 5 then
    if device_16n then set_16n_channel_and_cc_values(water_cc_channel) end
  end
end

-------------------------------
-- code for the 16n faderbank
--
-- sysex handling code from from: https://llllllll.co/t/how-do-i-send-midi-sysex-messages-on-norns/34359/15
--
-- to get the current 16n configs, call: send_16n_sysex(midi,get_16n_data_table)
--
-- important hex values (with decimal equivalent:
-- `0xF0` - "start byte" (240) - midi_event_index table 1[1]
-- `0x7d` - "manufacturer is 16n" (125) - midi_event_index table 1[2]
-- `0x0F` - "c0nFig" (15) - midi_event_index table 2[2]
-- `0xf7` - "stop byte" (247) -- midi_event_index table 30[1] QUESTION: why is this sent in the middle of the message, before current slider cc values are sent
-- current usb midi channel values: midi_event_index  table 7[2] - 12[2]
-- current trs midi channel values: midi_event_index  table 12[3] - 17[3]
-- current usb cc values: midi_event_index table 20[1] - 27[3]
-- current usb channel/cc/value  midi_event_index table 29[1] - 43[3] QUESTION: why don't all 16 channels show up?

--------------------------------
  
-- @param m: a midi device 
-- @param d: a table of systex data, omitting the framing bytes
-- function send_sysex(m, d) 
-- state variables.
sysexDataFrame = {}
message_from_16n = false
receiving_configs_from_16n = false
cc_vals_16n = {}
channel_vals_16n = {}

-- note: this function isn't currently required
local process_16n_data = function(data)
  print("process 16n data")
  local msg_data = midi.to_msg(data)
  
  midi_event_index = midi_event_index + 1
  if midi_event_index == 46 then         -- this is the end of the syssex message from 16n
    cc_vals_16n = {}
    channel_vals_16n = {}
    local store_cc_vals_16n = false
    local store_channel_vals_16n = false
    for i=1,#sysexDataFrame,1
    do
      local val = sysexDataFrame[i]
      if val.type == "other" then 
        for j=1, #val.raw, 1
        do
          -- start collecting cc values
          if i==7 and j==2 then store_cc_vals_16n = true end 
          if store_cc_vals_16n == true then table.insert(cc_vals_16n, val.raw[j]) end
          if i==12 and j==2 then store_cc_vals_16n = false end
          -- start collecting channel values 
          if i==12 and j==3 then store_channel_vals_16n = true end
          if store_channel_vals_16n == true then table.insert(channel_vals_16n, val.raw[j]) end
          if i==17 and j==3 then store_channel_vals_16n = false end
        end
      end
    end -- sysex processing ended, reset midi_event_index
    midi_event_index = 1
    receiving_configs_from_16n = false 
  else   -- assuming this is a data byte
    table.insert(sysexDataFrame, msg_data)
  end
end

set_16n_channel_and_cc_values = function (channel)
  channel_vals_16n = {}
  cc_vals_16n = {}
  for i=1,16,1
  do
    table.insert(channel_vals_16n, channel)
    table.insert(cc_vals_16n, (midi_cc_starting_value-1)+i) 
  end
  update16n()
end

update16n = function()
  local data_table = {0x7d,0x00,0x00,0x0c}
  local m = midi

  for i=1,16,1
  do
    local hex_val = i<15 and "0x"..string.format("%x",channel_vals_16n[i]) or "0x01"
    table.insert(data_table,hex_val)
  end

  for i=1,16,1
  do
    local hex_val = "0x"..string.format("%x",cc_vals_16n[i])
    table.insert(data_table,hex_val)
  end
  send_16n_sysex(midi, data_table)
end

function send_16n_sysex(m,d) 
  m.send(device_16n,{0xf0})
  for i,v in ipairs(d) do
    m.send(device_16n,{d[i]})
  end
  m.send(device_16n,{0xf7})
end


get_16n_data_table = {0x7d,0x00,0x00,0x1F}
-- set_16n_data_usb_only = {
--   0x7D, 0x00, 0x00, 
--   0x0c, 
--   0x04, 0x02, 0x03, 
--   0x04, 0x05, 0x06, 
--   0x07, 0x08, 0x09, 
--   0x0A, 0x0B, 0x0C, 
--   0x0D, 0x0E, 0x0F, 
--   0x10, 0x20, 
--   0x22, 0x21, 0x23, 
--   0x24, 0x25, 0x26, 
--   0x27, 0x28, 0x29, 
--   0x2A, 0x2B, 0x2C, 
--   0x2D, 0x2E, 0x2F, 
--   0x20, 0x21, 0x22, 
--   0x23, 0x24, 0x25, 
--   0x26, 0x27, 0x28, 
--   0x29, 0x2A, 0x2B, 
--   0x2C, 0x2D, 0x2E, 
--   0x2F}

-------------------------------
-- midi handler functions
-------------------------------


midi.add = function(device)
  -- print("add midi device", device.id, device.name)
 if device.name == "16n" then 
    device_16n = device 
    -- send_16n_sysex(midi,get_16n_data_table)
  end
end
  
midi_event_index = 0
midi.event = function(data) 
  if message_from_16n and receiving_configs_from_16n then
    -- process_16n_data(data)
  else
    if data[1] == 240 and data[2] == 125 then        --- this is the start byte with a a message from the 16n faderbank 
      midi_event_index = 2
      -- print("received start byte from the 16n faderbank")
      message_from_16n = true
    elseif message_from_16n == true and data[2] == 15 and data[3] == 2 then        --- this is the start of a message with the 16n configs
      -- print("receiving of 16n configs. set receiving_configs_from_16n = true")
      receiving_configs_from_16n = true
    else
      -- handle other message types
    end
  end
end
