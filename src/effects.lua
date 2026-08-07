local anim = require("src.anim")

local effects = {}

local pool   = {}
local active = 0

function effects.spawn(clip, x, y, scale)
    assert(clip, "effects.spawn: nil clip")
    active = active + 1
    local e = pool[active]
    if not e then
        e = { x = 0, y = 0, scale = 1, anim = nil }
        pool[active] = e
    end
    e.x, e.y = x, y
    e.scale  = scale or 1
    if e.anim then anim.play(e.anim, clip, true) else e.anim = anim.new_state(clip) end
    return e
end

function effects.update(dt)
    local i = 1
    while i <= active do
        local e = pool[i]
        anim.update(e.anim, dt)
        if e.anim.finished then
            pool[i], pool[active] = pool[active], pool[i]
            active = active - 1
        else
            i = i + 1
        end
    end
end

function effects.draw()
    for i = 1, active do
        local e = pool[i]
        anim.draw(e.anim, e.x, e.y, 0, e.scale)
    end
end

function effects.clear() active = 0 end

return effects