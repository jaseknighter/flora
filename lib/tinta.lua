-- monome crow script for aug 2023 performances at patch point in berlin and blivande in stockholm
-- @jaseknighter
-- <insert lines link>

-- TODO
-- humanize rhythm and notes

-- s = sequins
-- tl = timeline

t = {}

function t.init()
  
  t.vel=s{3}
  t.oct=s{0} -- tinta octaves
  t.tin=s{1,3,5} --  tinta chords
  t.pat=tl.queue():loop{
    1,{t.tintabulate,t.tin},
    1,{t.tintabulate,t.tin},
    3, {t.tintabulate,t.tin},
  } --loop timeline
  if params:get("tin_enabled") == 2 then
    t.pat:play()     
  end
end


--set new rhyth
function t.set_rhythm(rhythm)
  t.pat:stop()
  rhythm_loop = {}
  for i=1,#rhythm do
    table.insert(rhythm_loop,rhythm[i])
    table.insert(rhythm_loop, {t.tintabulate,t.tin})
  end

  t.pat=tl.queue():loop{table.unpack(rhythm_loop)}
  t.pat:play()

end

local function find_note(n, scale)
  local note
  if n > 0 then
    local base_index = n % #scale == 0 and #scale or n % #scale
    local octave_shift = n % #scale == 0 and math.floor(n/#scale) - 1 or math.floor(n/#scale) 
    note = scale[base_index] + (octave_shift * 12)
    -- print(n,note)
    return note
  end
end

function t.set_tt_note(m_note)
  -- print("m_note",m_note)
  t.note_pre_oct = m_note
end

function t.find_index(t, item)
  for i,v in ipairs(t) do
    if v==item then return i end
  end
end

-- from: https://stackoverflow.com/questions/22185684/how-to-shift-all-elements-in-a-table
function t.wrap( t, l )
  for i = 1, l do
      table.insert( t, 1, table.remove( t, #t ) )
  end
end

t.note_names={"A","A#","B","C","C#","D","D#","E","E","F","F#","G","G#"}

function t.get_note_distance(note1,note2)
  local root = MusicUtil.note_num_to_name(params:get("root_note"))
  local rotated_notes=shallow_copy(t.note_names)
  t.wrap(rotated_notes,#rotated_notes-t.find_index(t.note_names,root)+1)
  local note1_idx=t.find_index(rotated_notes,note1)
  local note2_idx=t.find_index(rotated_notes,note2)
  return (note1_idx and note2_idx) and math.abs(note1_idx-note2_idx) or 5
end

function t.get_mel_tin_distances(m_note)
  local closest=1
  local furthest=1

  local m_name = MusicUtil.note_num_to_name(m_note)
  local last_distance
  for i=1,#t.tin do
    local t_name = MusicUtil.note_num_to_name(t.tin[i])
    local distance = t.get_note_distance(m_name,t_name)
    if last_distance then
      if distance < last_distance then closest=i end
      if distance > last_distance then furthest=i end
    end
    last_distance = distance
  end
  return closest, furthest
end 

function t.tintabulate()
  local chord_note
  
  if params:get("tin_method")==1 then
    chord_note = t.tin()
  else
    local closest, furthest = t.get_mel_tin_distances(t.note_pre_oct)
    -- print("closest,furthest",closest,furthest)
    if params:get("tin_method")==2 then
      t.tin:select(closest)
    elseif params:get("tin_method")==3 then
      t.tin:select(furthest)
    end
    chord_note = t.tin()
  end
  local oct = t.oct() * 12    
  if t.note_pre_oct+chord_note < 1 then return end
  local t_note,t_note_pre
  
  if params:get("tin_dancing_notes") == 2 then
    t_note_pre = find_note(t.note_pre_oct-24+chord_note, notes)+oct
    t_note = t_note_pre + oct
  else
    t_note_pre = find_note(chord_note, notes)+oct+12
    t_note = t_note_pre + oct+24
  end
  -- print("t_note",t_note)
  local output_tinta = params:get("output_tinta")
  if t_note and output_tinta == 2 then
    local vel = t.vel()
    local note_idx = plants[1].sounds.find_note(note_to_play) - 1
    if active_plant == 1 then
      plants[1].sounds.engine_tin_note_on(t_note,vel,1,note_idx)
    else
      plants[2].sounds.engine_tin_note_on(t_note,vel,1,note_idx)
    end
    clock.run(plants[1].sounds.externals1.note_on,1, t_note, MusicUtil.note_num_to_freq(t_note), 1,nil,"tt",vel)
  end
end

-------------------------------------
-- keyboard stuff
-------------------------------------
-- note check pattern will not catch format issues if there are multiple sequins in the pattern
function t.check_pat(input_string, start_pattern, end_pattern)
  local starts_with = string.sub(input_string, 1, #start_pattern) == start_pattern
  local ends_with = string.sub(input_string, -#end_pattern) == end_pattern
  local interior_seq_ok = true
  if input_string and starts_with and ends_with then -- check if there is an interior sequins
    local interior_str = string.sub(input_string,#start_pattern+1,-#end_pattern-1)
    if string.match(interior_str, 's{') or string.match(interior_str, '}') then
      interior_seq_ok = string.match(interior_str, 's{')~=nil and string.match(interior_str, '}')~=nil
    end
  end
  return starts_with and ends_with and interior_seq_ok
end

function t.get_args(input_string, start_pattern, end_pattern)
  local args=string.sub(input_string, #start_pattern+1, -#end_pattern-1)
  return args
end

t.str = ""
t.schr = "> "
t.history = {}
t.new_line = nil
t.cmds = {
  {"oct=s{","}"},
  {"tin=s{","}"},
  {"vel=s{","}"},
  {"rhy=s{","}"},
  {"pl","ay"},
  {"sto","p"},
  {"on","dance"},
  {"off","dance"},
}
t.cmds_idx=1
t.ctrl_down=false
t.cmd=nil
t.cmd_params=nil
t.cmd_ok=false

function t.str_to_tab(str)
  local tbl = {}
  local processing_int_seq = false
  local int_seq = {}
  for val in string.gmatch(str, '([^,]+)') do
    if string.sub(val,1,1)=="s" then
      processing_int_seq = true
      val=string.sub(val,3,#val)
      local num = tonumber(val)
      table.insert(int_seq,num)
    elseif processing_int_seq == true and string.sub(val,#val)~="}" then
      local num = tonumber(val)
      table.insert(int_seq,num)
    elseif processing_int_seq == true and string.sub(val,#val)=="}" then
      val=string.sub(val,1,#val-1)
      local num = tonumber(val)
      table.insert(int_seq,num)
      table.insert(tbl, s{table.unpack(int_seq)})
      processing_int_seq = false
    elseif processing_int_seq == false then
      local num = tonumber(val)
      table.insert(tbl,num and num or val)
    end
  end
  return tbl
end

function t.check_format()
  if t.str == "" then 
    return true 
  else
    local cmd, format_ok, args
    for i=1,#t.cmds do
      local cmd_type = string.sub(t.str,1,#t.cmds[i][1]) == t.cmds[i][1]
      if cmd_type then
        cmd = i
        format_ok = t.check_pat(t.str,t.cmds[i][1],t.cmds[i][2])
        if format_ok then
          args = t.get_args(t.str,t.cmds[i][1],t.cmds[i][2])
        end
      end
    end
    if cmd and format_ok then 
      t.cmd=cmd
      t.cmd_params = args
      if cmd>4 or #args > 0 then 
        t.schr = "> "
        t.cmd_ok=true
      else
        t.schr = "? "
        t.cmd_ok=false
      end
    else 
      t.cmd=nil
      t.cmd_params=nil
      t.cmd_ok=false
      t.schr = "? "
    end
  end

end

keyboard.char = function (character)
  if pages.index==6 then
    -- if #t.str < 20 then
      t.str = t.str .. character
      t.redraw()
    -- end
  end
end

keyboard.code = function (code, val)
  if pages.index==6 then
    if val == 0 then      
      if  string.sub(code,#code-3)  == "CTRL" then 
        t.ctrl_down = false
      end
      return 
    end
    if code == "BACKSPACE" then
      t.str = t.str:sub(1, -2)
    elseif code == "UP" then
      if t.ctrl_down == true then
        t.cmds_idx = util.wrap(t.cmds_idx-1,1,#t.cmds)
        t.str = t.cmds[t.cmds_idx][1]..t.cmds[t.cmds_idx][2]
      else
        if #t.history == 0 then return end
        if t.new_line then
          t.history_index = #t.history - 1
          t.new_line = false
        else
          t.history_index = util.clamp(t.history_index - 1, 0, #t.history)
        end
        t.str = t.history[t.history_index + 1]
      end
    elseif code == "DOWN" then
      if t.ctrl_down == true then
        t.cmds_idx = util.wrap(t.cmds_idx+1,1,#t.cmds)
        t.str = t.cmds[t.cmds_idx][1]..t.cmds[t.cmds_idx][2]
      else
        if #t.history == 0 or t.history_index == nil then return end
        t.history_index = util.clamp(t.history_index + 1, 0, #t.history)
        if t.history_index == #t.history then
          t.str = ""
          t.new_line = true
        else
          t.str = t.history[t.history_index + 1]
        end
      end
    elseif code == "ENTER" and t.cmd_ok == true then
      table.insert(t.history, t.str)
      t.str = ""
      t.history_index = #t.history
      t.new_line = true



      if t.cmd == 1 then -- update octaves
        local tbl = t.str_to_tab(t.cmd_params)
        -- for i=1,#tbl do -- IMPORTANT: keep octaves below 3 so things don't blow up
        --   if tbl[i] > 2 then tbl[i] = 2 end 
        -- end
        t.oct = s{table.unpack(tbl)}
      elseif t.cmd == 2 then -- update tinta melody
        local tbl = t.str_to_tab(t.cmd_params)
        t.tin = s{table.unpack(tbl)}
      elseif t.cmd == 3 then -- update velocities
        local tbl = t.str_to_tab(t.cmd_params)
        t.vel = s{table.unpack(tbl)}
      elseif t.cmd == 4 then -- update rhythm
        local tbl = t.str_to_tab(t.cmd_params)
        t.set_rhythm(tbl)
      elseif t.cmd == 5 then -- start the tinta pattern
        params:set("tin_enabled",2)
      elseif t.cmd == 6 then -- stop the tinta pattern
        params:set("tin_enabled",1)
      elseif t.cmd == 7 then -- dance on
        params:set("tin_dancing_notes",2)
      elseif t.cmd == 8 then -- dance off
        params:set("tin_dancing_notes",1)
      end
    elseif keyboard.ctrl() then
      if t.ctrl_down == false then
        t.ctrl_down = true
      end
      t.history_index = #t.history
      -- table.remove(t.history,#t.history)
      -- t.history_index = #t.history
      -- t.str = ""
    end
    t.redraw()
    -- grid_redraw()
  end
end

function t.redraw()
  if pages.index==6 then
    screen.clear()
    screen.level(10)
    screen.rect(2, 50, 125, 14)
    screen.stroke()
    screen.move(5, 59)
    -- t.schr = t.check_format() and "> " or "? "
    t.check_format() 
    screen.text(t.schr .. t.str)
    
    if t.history_index then
      for i = 1, 3 do
        if not (t.history_index - i >= 0) then break end
        screen.move(5, 55 - 10 * i)
        screen.text(t.history[t.history_index - i + 1])
      end
    end
    -- screen.update()
    
  end
end

return t