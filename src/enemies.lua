local anim = require("src.anim")

local enemies = {}

local pool   = {}
local active = 0

local function acquire()
    active = active + 1
    local e = pool[active]
    if not e then
        e = { x = 0, y = 0, vx = 0, vy = 0, hp = 0, radius = 0, fire_timer = 0, anim = nil, dead = false }
        pool[active] = e
    end
    return e
end

local function release(index)
    pool[index], pool[active] = pool[active], pool[index]
    active = active - 1
end

function enemies.spawn(clip, x, y, vx, vy, hp, radius)
    assert(clip, "enemies.spawn: nil clip")
    local e = acquire()
    e.x, e.y   = x, y
    e.vx, e.vy = vx, vy
    e.hp       = hp
    e.radius   = radius
    e.dead     = false
    e.fire_timer = 0

    if e.anim then
        anim.play(e.anim, clip, true)
    else
        e.anim = anim.new_state(clip)
    end
    return e
end

function enemies.update(dt, left, top, right, bottom)
    local i = 1
    while i <= active do
        local e = pool[i]
        e.x = e.x + e.vx * dt
        e.y = e.y + e.vy * dt
        anim.update(e.anim, dt)

        if e.dead or e.x < left or e.x > right or e.y < top or e.y > bottom then
            release(i)
        else
            i = i + 1
        end
    end
end

function enemies.draw()
    for i = 1, active do
        local e = pool[i]
        anim.draw(e.anim, e.x, e.y)
    end
end

function enemies.count() return active end
function enemies.get(index) return pool[index] end
function enemies.clear() active = 0 end

return enemies