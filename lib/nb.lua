local nb = require "nb/lib/nb"

g = grid.connect()

grid_dirty = true

function init()
    nb:init()
    nb:add_param("voice", "voice")
    nb:add_player_params()
    clock.run(function()
        while true do
            if grid_dirty then
                grid_redraw()
            end
            clock.sync(1/32)
        end
    end)
    clock.run(function()
        clock.sleep(2)
        params:bang()
    end)
end

function g.key(x, y, z)
    local note = 24
    note = note + x
    note = note + 5 * (8 - y)
    local player = params:lookup_param("voice"):get_player()
    if z == 1 then
        player:note_on(note, 1)
    else
        player:note_off(note)
    end
end

function grid_redraw()
    g:all(0)
    for x=1,16,1 do
        for y=1,8,1 do
            local note = 24
            note = note + x
            note = note + 5 * (8 - y)
            local hs = note % 12
            if hs == 0 then
                g:led(x, y, 6)
            elseif hs == 2 or hs == 4 or hs == 5 or hs == 7 or hs == 9 or hs == 11 then
                g:led(x, y, 3)
            end
        end
    end
    g:refresh()
end