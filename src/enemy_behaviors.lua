local behaviors = {}

-- behavior: { update(e, dt) } — sets e.vx / e.vy; integration stays in enemies.update

behaviors.linear = {
    update = function(e, dt) end,
}

behaviors.drifter = {
    update = function(e, dt)
        local v = e.vars
        e.t = e.t + dt
        if e.x > v.hold_x then
            e.vx, e.vy = -v.approach_speed, 0
        else
            e.vx = math.cos(e.t * v.rate_x) * v.amp_x
            e.vy = math.sin(e.t * v.rate_y) * v.amp_y
        end
    end,
}

return behaviors