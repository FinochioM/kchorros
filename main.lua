local screen = require("src.screen")
local anim   = require("src.anim")
local bullets = require("src.bullets")
local enemies = require("src.enemies")

local INV_SQRT2 = 1 / math.sqrt(2)
local TICK = 1 / 60
local accumulator = 0

local SHIP_FRAME_W = 32
local SHIP_FRAME_H = 32
local SHIP_BULLET_FRAME_W = 32
local SHIP_BULLET_FRAME_H = 32

local BULLET_SPEED = 150
local BULLET_LIFE = 2.0
local BULLET_MARGIN = 16
local PLAYER_FIRE_RATE = 0.12

local ENEMY_FRAME_W = 32
local ENEMY_FRAME_H = 32

local PLAYER_BULLET_RADIUS = 3
local ENEMY_BULLET_RADIUS  = 4
local ENEMY_RADIUS         = 12
local ENEMY_HP             = 3
local ENEMY_SPEED          = 60
local ENEMY_BULLET_SPEED   = 90
local ENEMY_FIRE_RATE      = 1.2

local spawn_timer = 0

local sheets = {}
local clips  = {}

local player = {
    x     = 0,
    y     = 0,
    speed = 180, -- virtual pixels per second
    fire_timer = 0,
    anim  = nil,
}

local function axis(negative, positive)
    local value = 0
    if love.keyboard.isDown(negative) then value = value - 1 end
    if love.keyboard.isDown(positive) then value = value + 1 end
    return value
end

local function clamp(value, low, high)
    return math.min(math.max(value, low), high)
end

local function collide_bullets_enemies()
    for bi = bullets.count(), 1, -1 do
        local b = bullets.get(bi)
        for ei = enemies.count(), 1, -1 do
            local e = enemies.get(ei)
            local dx, dy = b.x - e.x, b.y - e.y
            local r = b.radius + e.radius
            if dx * dx + dy * dy <= r * r then
                e.hp = e.hp - 1
                if e.hp <= 0 then e.dead = true end
                bullets.remove(bi)
                break
            end
        end
    end
end

local function update_enemy_fire()
    for i = 1, enemies.count() do
        local e = enemies.get(i)
        e.fire_timer = e.fire_timer - TICK
        if e.fire_timer <= 0 then
            e.fire_timer = ENEMY_FIRE_RATE
            bullets.spawn(clips.enemy_basic_bullet, e.x, e.y,
                -ENEMY_BULLET_SPEED, 0, BULLET_LIFE, ENEMY_BULLET_RADIUS)
        end
    end
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    screen.init(480, 336)

    local ship_image = love.graphics.newImage("assets/ship.png")
    sheets.ship = anim.new_sheet(ship_image, SHIP_FRAME_W, SHIP_FRAME_H)

    clips.ship_idle = anim.new_clip(sheets.ship, anim.range(1, 4), 12, true)
    clips.ship_move_down = anim.new_clip(sheets.ship, anim.range(13, 15), 12, false)
    clips.ship_move_up = anim.new_clip(sheets.ship, anim.range(25, 27), 12, false)

    player.x    = screen.width * 0.25
    player.y    = screen.height * 0.5
    player.anim = anim.new_state(clips.ship_idle)

    local ship_bullet_image = love.graphics.newImage("assets/ship_bullets.png")
    sheets.bullets = anim.new_sheet(ship_bullet_image, SHIP_BULLET_FRAME_W, SHIP_BULLET_FRAME_H)

    clips.basic_bullet = anim.new_clip(sheets.bullets, anim.range(1, 4), 12, true)

    local enemy_image = love.graphics.newImage("assets/enemies.png")
    sheets.enemies = anim.new_sheet(enemy_image, ENEMY_FRAME_W, ENEMY_FRAME_H)

    clips.enemy_basic = anim.new_clip(sheets.enemies, anim.range(1, 4), 12, true)
    clips.enemy_basic_bullet = anim.new_clip(sheets.enemies, anim.range(7, 10), 12, true)
end

local function fixed_update()
    spawn_timer = spawn_timer - TICK
    if spawn_timer <= 0 then
        spawn_timer = 1.5
        enemies.spawn(clips.enemy_basic, screen.width + 16,
            math.random(32, screen.height - 32),
            -ENEMY_SPEED, 0, ENEMY_HP, ENEMY_RADIUS)
    end

    local dx = axis("left", "right")
    local dy = axis("up", "down")

    if dy < 0 then
        anim.play(player.anim, clips.ship_move_up)
    elseif dy > 0 then
        anim.play(player.anim, clips.ship_move_down)
    else
        anim.play(player.anim, clips.ship_idle)
    end

    if dx ~= 0 and dy ~= 0 then
        dx, dy = dx * INV_SQRT2, dy * INV_SQRT2
    end

    local step   = player.speed * TICK
    local half_w = sheets.ship.frame_w * 0.5
    local half_h = sheets.ship.frame_h * 0.5

    player.x = clamp(player.x + dx * step, half_w, screen.width  - half_w)
    player.y = clamp(player.y + dy * step, half_h, screen.height - half_h)

    player.fire_timer = player.fire_timer - TICK
    if love.keyboard.isDown("z") and player.fire_timer <= 0 then
        player.fire_timer = PLAYER_FIRE_RATE
        bullets.spawn(clips.basic_bullet, player.x + 14, player.y, BULLET_SPEED, 0, BULLET_LIFE)
    end

    update_enemy_fire()

    bullets.update(TICK, -BULLET_MARGIN, -BULLET_MARGIN, screen.width + BULLET_MARGIN, screen.height + BULLET_MARGIN)
    enemies.update(TICK, -BULLET_MARGIN, -BULLET_MARGIN, screen.width + BULLET_MARGIN, screen.height + BULLET_MARGIN)
    collide_bullets_enemies()

    anim.update(player.anim, TICK)
end

function love.update(dt)
    accumulator = accumulator + math.min(dt, 0.25)
    while accumulator >= TICK do
        accumulator = accumulator - TICK
        fixed_update()
    end
end

function love.draw()
    screen.begin_draw()
        enemies.draw()
        bullets.draw()
        anim.draw(player.anim, player.x, player.y)
    screen.finish_draw()
end

function love.resize(w, h)
    screen.resize(w, h)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
end