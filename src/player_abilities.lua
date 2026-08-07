local anim = require("src.anim")

local defs = {}

local DASH_DISTANCE = 90

defs.dash = {
    duration = 0, -- set from clip on_start
    cooldown = 0.60,

    on_start = function(p, slot)
        p.invulnerable = true
        anim.play(p.anim, p.clips.ship_dash, true)
        slot.active = anim.duration(p.clips.ship_dash)
        slot.speed  = DASH_DISTANCE / slot.active
    end,

    on_update = function(p, slot, dt)
        p.move(p, slot.speed * dt, 0)
    end,

    on_finish = function(p)
        p.invulnerable = false
        anim.play(p.anim, p.clips.ship_idle, true)
    end,
}

return defs