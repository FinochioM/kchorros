local anim = require("src.anim")

local bullets = {}

function bullets.new_pool()
    return { items = {}, active = 0 }
end

local function acquire(pool)
    pool.active = pool.active + 1
    local b = pool.items[pool.active]
    if not b then
        b = { x = 0, y = 0, vx = 0, vy = 0, life = 0, radius = 0, damage = 1, anim = nil }
        pool.items[pool.active] = b
    end
    return b
end

local function release(pool, index)
    local items = pool.items
    items[index], items[pool.active] = items[pool.active], items[index]
    pool.active = pool.active - 1
end

function bullets.spawn(pool, clip, x, y, vx, vy, life, radius, damage)
    assert(clip, "bullets.spawn: nil clip")
    local b = acquire(pool)
    b.x,  b.y  = x, y
    b.vx, b.vy = vx, vy
    b.life     = life
    b.radius   = radius or 3
    b.damage   = damage or 1

    if b.anim then
        anim.play(b.anim, clip, true)
    else
        b.anim = anim.new_state(clip)
    end
    return b
end

function bullets.update(pool, dt, left, top, right, bottom)
    local i = 1
    while i <= pool.active do
        local b = pool.items[i]

        b.x    = b.x + b.vx * dt
        b.y    = b.y + b.vy * dt
        b.life = b.life - dt
        anim.update(b.anim, dt)

        if b.life <= 0 or b.x < left or b.x > right or b.y < top or b.y > bottom then
            release(pool, i)
        else
            i = i + 1
        end
    end
end

function bullets.draw(pool)
    for i = 1, pool.active do
        local b = pool.items[i]
        anim.draw(b.anim, b.x, b.y)
    end
end

function bullets.clear(pool)  pool.active = 0 end
function bullets.count(pool)  return pool.active end
function bullets.remove(pool, index) release(pool, index) end
function bullets.get(pool, index)    return pool.items[index] end

return bullets