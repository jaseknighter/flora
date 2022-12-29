-- plant generation sequencer 
-- plants[1].set_instructions(0,1)
-- plants[1].set_instructions(0,-1)
-- plants[1].get_max_generations()
-- plants[1].get_current_generation()

local p_gen_seq = {}

------------------------------
-- main plant generation sequencer code
------------------------------
local ticks_per_seq_cycle = clock.get_tempo() * 1/1
local p_gen_seq_direction = "up"

local function set_p_gen_seq_timer()
  local arg_time = clock.get_tempo()
  p_gen_seq_ticks = 1

  p_gen_seq_timer = metro.init(function()       
    for i=1,2,1 do
      if (i==1 and params:get("p1_gen_seq_enabled") == 2) or (i==2 and params:get("p2_gen_seq_enabled") == 2) then
        local first = 1
        local last = plants[i].get_max_generations()
        local new_generation
        p_gen_seq_ticks = p_gen_seq_ticks + 1
        if p_gen_seq_ticks == ticks_per_seq_cycle then
          p_gen_seq_ticks = 1
          local num_gens = last --last - first + 1
          
          local current_gen = plants[i].get_current_generation()
          local mode = params:get("p_gen_seq_mode")
          if mode == 1 then
            new_generation = current_gen < last and 1 or (-1 * ((current_gen-1)))
            -- new_generation = current_gen < last and 1 or (-1 * (current_gen - (current_gen-1)))
          elseif mode == 2 then
            if p_gen_seq_direction == "up" then
              new_generation = current_gen < last and 1 or -1
              p_gen_seq_direction = current_gen < last and p_gen_seq_direction or "down"
            else
              new_generation = current_gen > first and -1 or 1
              p_gen_seq_direction =  current_gen > first and p_gen_seq_direction or "up"
            end
          elseif mode == 3 then
            local up_down = math.random() > 0.5 and 1 or - 1
            new_generation = util.clamp(1,last, math.random(1,num_gens) * up_down)
          end
          -- print("new gen", new_generation,current_gen, (-1 * (current_gen - (current_gen-1))))
          plants[i].set_instructions(0,new_generation)
        end

      end
    end  
    if clock.get_tempo() ~= arg_time and initializing_p_gen_seq_timer == false then
      initializing_p_gen_seq_timer = true
      metro.free(p_gen_seq_timer.props.id)
      set_p_gen_seq_timer()
      initializing_p_gen_seq_timer = false
    end
  end, 1/arg_time, -1)
  p_gen_seq_timer:start()
  initializing_p_gen_seq_timer = false
end

local function set_ticks_per_seq_cycle()
  ticks_per_seq_cycle = math.floor(clock.get_tempo() * (params:get("p_gen_seq_beats")/params:get("p_gen_seq_beats_per_bar")))
  p_gen_seq_ticks = 1
end 

p_gen_seq.set_save_paramlist = function(paramlist, state)
  if paramlist and #paramlist > 0  then
    for i=1,#paramlist,1
    do
      if paramlist[i] then
        params:set_save(paramlist[i],state)
      end
    end
  end
end

------------------------------
-- pset sequencer init
------------------------------
p_gen_seq.init = function ()
  
  params:add_group("plant gen sequencer",5)

  params:add_option("p1_gen_seq_enabled","p1 gen seq enabled", {"false", "true"})
  params:set_action("p1_gen_seq_enabled", function(x) 
    if x == 2 then
      initializing_p_gen_seq_timer = true
      metro.free(p_gen_seq_timer.props.id)
      set_p_gen_seq_timer()
      initializing_p_gen_seq_timer = false
    end
  end )

  params:add_option("p2_gen_seq_enabled","p2 gen seq enabled", {"false", "true"})
  params:set_action("p2_gen_seq_enabled", function(x) 
    if x == 2 then
      initializing_p_gen_seq_timer = true
      metro.free(p_gen_seq_timer.props.id)
      set_p_gen_seq_timer()
      initializing_p_gen_seq_timer = false
    end
  end )


  params:add_option("p_gen_seq_mode","pgen seq mode", {"loop", "up/down", "random"})
  

  params:add_number("p_gen_seq_beats", "pgen seq beats", 1, 16, 8)
  params:set_action("p_gen_seq_beats", function() 
    set_ticks_per_seq_cycle() 
  end )
  params:add_number("p_gen_seq_beats_per_bar", "pgen seq beats per bar", 1, 4, 1)
  params:set_action("p_gen_seq_beats_per_bar", function() set_ticks_per_seq_cycle() end )

  
  -- end pset sequence timer
  set_p_gen_seq_timer()
end

return p_gen_seq
