-- encoders and keys

local enc = function (n, delta)
  -- set variables needed by each page/example
  if show_instructions == false and initializing == false then
    if n == 1 then
      if (alt_key_active == false) then
        -- scroll pages
        local page_increment = util.clamp(delta, -1, 1)

        local next_page = pages.index + page_increment
        if (next_page <= num_pages and next_page > 0) then
          -- Page scroll
          for i=1,#plants,1
          do
            plants[i].set_current_page(next_page)
          end
          page_scroll(page_increment)
          set_midi_channels()
        end
        screen.clear()
        if (pages.index == 4 or pages.index == 6) then
        end
      end
      if (alt_key_active == true) then
        if delta == 1 or delta == -1 then
          plants[active_plant].switch_active_plant()
        end
      end
    elseif n == 2 then 
      screen.clear()
      if (pages.index == 1 and alt_key_active) then
        -- change instruction for active plant
        local rotate_by = util.clamp(delta, -1, 1)
        clock.run(plants[active_plant].set_instructions,rotate_by,0,true)
      elseif pages.index == 2 then
        local increment = util.clamp(delta, -1, 1)
        modify.enc(n, delta, alt_key_active)     
        -- plants[active_plant].increment_sentence_cursor(increment)
      elseif pages.index == 3 then
        -- move active plant along the x-axis
        plants[active_plant].set_offset(delta,0)
      elseif pages.index == 4 then
        envelopes[active_plant].enc(n, delta, alt_key_active)     
      elseif pages.index == 5 then
        water.enc(n, delta, alt_key_active)     
      end
    elseif n == 3 then 
      screen.clear()
      if pages.index == 1 then
        plants[active_plant].set_angle(util.clamp(delta, -1, 1))
      elseif pages.index == 2 then
        local incr = util.clamp(delta, -1, 1) 
        modify.enc(n, delta, alt_key_active)     
        -- plants[active_plant].change_letter(incr)
      elseif pages.index == 3 then
        -- move active plant along the y-axis
        plants[active_plant].set_offset(0,delta)
      elseif pages.index == 4 then
        envelopes[active_plant].enc(n, delta)     
      elseif pages.index == 5 then
        water.enc(n, delta, alt_key_active)  
      end
    end
  end
  set_dirty()
end

local key = function (n,z)
  if n == 1 then
    if z == 0 then alt_key_active = false else alt_key_active = true end
  end
  
  -- if ((n == 2 and alt_key_active == true) or show_instructions == true) then
    if n == 2 and alt_key_active == true and show_instructions == true then
      -- show_instructions = false
      screen.clear() 
      if pages.index == 5 then
        water.display()
      end
    elseif n == 2 and z== 1 and alt_key_active then
      show_instructions = true
    end
  -- end

  if n == 2 and z== 0 then
    show_instructions = false
  end
  
  -- if show_instructions == false then
    -- if (n == 2 and z == 1 and alt_key_active == false) then 
    if (n == 2 and z == 1) then 
      if (pages.index == 1) then
        plants[active_plant].set_instructions(0,-1)
      elseif (pages.index == 2) then
        modify.key(n, z)
      elseif(pages.index == 3) then
        plants[active_plant].set_node_length(0.9)
      elseif pages.index == 5 then
        -- water.key(n, delta, alt_key_active)
      end
    elseif (n == 2 and z == 0)  then 
      if pages.index == 2  and alt_key_active == false then
        modify.key(n, z)
      elseif pages.index == 4 then
        envelopes[active_plant].key(n, delta)
      elseif pages.index == 5 then
        water.key(n, delta, alt_key_active)
      end
    elseif (n == 3 and z == 0)  then 
      if pages.index == 1  and alt_key_active == false then
        plants[active_plant].set_instructions(0,1)
      elseif pages.index == 2  and alt_key_active == false then
        modify.key(n, z)
      elseif pages.index == 3  and alt_key_active == false then
        plants[active_plant].set_node_length(1.1)
      elseif pages.index == 4 then
        envelopes[active_plant].key(n, delta)
      elseif pages.index == 5 then
        water.key(n, delta, alt_key_active)
      end
    end
  -- end
  
  
  -- on pages 1-3 sync plants from start of sequences
  if (n == 3 and alt_key_active == true and pages.index < 4) then
    plants[1].set_instructions(0)
    plants[2].set_instructions(0)
  end
  set_dirty()
end

return{
  enc=enc,
  key=key
}
