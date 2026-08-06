local anim = require("src.anim")

local bullets = {}

local pool   = {}
local active = 0

local function acquire()
    active = active + 1
    local b = pool[active]
    if not b then
        b = { x = 0, y = 0, vx = 0, vy = 0, life = 0, radius = 0, anim = nil }
        pool[active] = b
    end
    return b
end

local function release(index)
    pool[index], pool[active] = pool[active], pool[index]
    active = active - 1
end

function bullets.spawn(clip, x, y, vx, vy, life, radius)
    assert(clip, "bullets.spawn: nil clip")
    local b = acquire()
    b.x,  b.y  = x, y
    b.vx, b.vy = vx, vy
    b.life     = life
    b.radius   = radius or 3

    if b.anim then
        anim.play(b.anim, clip, true)
    else
        b.anim = anim.new_state(clip)
    end
    return b
end

function bullets.update(dt, left, top, right, bottom)
    local i = 1
    while i <= active do
        local b = pool[i]

        b.x    = b.x + b.vx * dt
        b.y    = b.y + b.vy * dt
        b.life = b.life - dt
        anim.update(b.anim, dt)

        if b.life <= 0 or b.x < left or b.x > right or b.y < top or b.y > bottom then
            release(i)
        else
            i = i + 1
        end
    end
end

function bullets.draw()
    for i = 1, active do
        local b = pool[i]
        anim.draw(b.anim, b.x, b.y)
    end
end

function bullets.clear()
    active = 0
end

function bullets.count()
    return active
end

function bullets.remove(index)
    release(index)
end

function bullets.get(index)
    return pool[index]
end

return bullets