local screen = require("src.screen")
local anim   = require("src.anim")
local bullets = require("src.bullets")
local enemies = require("src.enemies")
local flash = require("src.flash")
local abilities        = require("src.abilities")
local player_abilities = require("src.player_abilities")
local enemy_behaviors = require("src.enemy_behaviors")

local INV_SQRT2 = 1 / math.sqrt(2)
local TICK = 1 / 60
local accumulator = 0

local SHIP_FRAME_W = 32
local SHIP_FRAME_H = 32
local SHIP_BULLET_FRAME_W = 32
local SHIP_BULLET_FRAME_H = 32

local BULLET_SPEED = 200
local BULLET_LIFE = 2.0
local BULLET_MARGIN = 16
local PLAYER_FIRE_RATE = 0.5
local PLAYER_HP     = 3
local PLAYER_RADIUS = 8

local ENEMY_FRAME_W = 32
local ENEMY_FRAME_H = 32

local ENEMY_BULLET_RADIUS  = 4
local ENEMY_RADIUS         = 12
local ENEMY_HP             = 2
local ENEMY_SPEED          = 100
local ENEMY_BULLET_SPEED   = 110
local ENEMY_FIRE_RATE      = 1.6
local ENEMY_SCALE = 1.2

local player_bullets = bullets.new_pool()
local enemy_bullets  = bullets.new_pool()

local PLAYER_BULLET_RADIUS = 2
local ENEMY_BULLET_RADIUS  = 3
local ENEMY_RADIUS         = 9
local ENEMY_HOLD_X   = 0.55 -- fraction of screen width
local ENEMY_AMP_X    = 40
local ENEMY_AMP_Y    = 55
local ENEMY_RATE_X   = 1.7
local ENEMY_RATE_Y   = 1.1

local debug_hitboxes = false

local spawn_timer = 0

local sheets = {}
local clips  = {}

local player = {
    x     = 0,
    y     = 0,
    speed = 220,
    hp    = PLAYER_HP,
    radius = PLAYER_RADIUS,
    fire_timer  = 0,
    flash_timer = 0,
    invulnerable = false,
    state = "alive", -- "alive" | "dying" | "dead"
    anim  = nil,
    clips = nil,
    move  = nil,
    ability_set = abilities.new_set(),
}

local dash_pressed = false

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
    for bi = bullets.count(player_bullets), 1, -1 do
        local b = bullets.get(player_bullets, bi)
        for ei = enemies.count(), 1, -1 do
            local e = enemies.get(ei)
            local dx, dy = b.x - e.x, b.y - e.y
            local r = b.radius + e.radius
            if dx * dx + dy * dy <= r * r then
                e.hp = e.hp - 1
                e.flash_timer = flash.DURATION
                if e.hp <= 0 then e.dead = true end
                bullets.remove(player_bullets, bi)
                break
            end
        end
    end
end

local function update_enemy_fire()
    for i = 1, enemies.count() do
        local e = enemies.get(i)
        if e.x < screen.width then
            e.fire_timer = e.fire_timer - TICK
            if e.fire_timer <= 0 then
                e.fire_timer = ENEMY_FIRE_RATE
                local dx, dy = player.x - e.x, player.y - e.y
                local len = math.sqrt(dx * dx + dy * dy)
                if len > 0 then
                    bullets.spawn(enemy_bullets, clips.enemy_basic_bullet, e.x, e.y,
                        dx / len * ENEMY_BULLET_SPEED, dy / len * ENEMY_BULLET_SPEED,
                        BULLET_LIFE, ENEMY_BULLET_RADIUS)
                end
            end
        end
    end
end

local function kill_player()
    player.state = "dying"
    player.flash_timer = 0
    player.invulnerable = false
    abilities.clear(player.ability_set)
    anim.play(player.anim, clips.ship_explode, true)
end

local function damage_player()
    if player.state ~= "alive" then return end
    player.hp = player.hp - 1
    player.flash_timer = flash.DURATION
    if player.hp <= 0 then kill_player() end
end

local function move_player(p, dx, dy)
    local half_w = sheets.ship.frame_w * 0.5
    local half_h = sheets.ship.frame_h * 0.5
    p.x = clamp(p.x + dx, half_w, screen.width  - half_w)
    p.y = clamp(p.y + dy, half_h, screen.height - half_h)
end

local function collide_player()
    if player.state ~= "alive" or player.invulnerable then return end

    for i = bullets.count(enemy_bullets), 1, -1 do
        local b = bullets.get(enemy_bullets, i)
        local dx, dy = b.x - player.x, b.y - player.y
        local r = b.radius + player.radius
        if dx * dx + dy * dy <= r * r then
            bullets.remove(enemy_bullets, i)
            damage_player()
            return
        end
    end

    for i = enemies.count(), 1, -1 do
        local e = enemies.get(i)
        local dx, dy = e.x - player.x, e.y - player.y
        local r = e.radius + player.radius
        if dx * dx + dy * dy <= r * r then
            e.dead = true
            damage_player()
            return
        end
    end
end

local function reset_game()
    bullets.clear(player_bullets)
    bullets.clear(enemy_bullets)
    enemies.clear()
    abilities.clear(player.ability_set)

    player.x     = screen.width * 0.25
    player.y     = screen.height * 0.5
    player.hp    = PLAYER_HP
    player.state = "alive"
    player.fire_timer   = 0
    player.flash_timer  = 0
    player.invulnerable = false
    anim.play(player.anim, clips.ship_idle, true)

    spawn_timer = 0
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    screen.init(480, 360)

    local ship_image = love.graphics.newImage("assets/ship.png")
    sheets.ship = anim.new_sheet(ship_image, SHIP_FRAME_W, SHIP_FRAME_H)

    clips.ship_idle = anim.new_clip(sheets.ship, anim.range(1, 4), 12, true)
    clips.ship_move_down = anim.new_clip(sheets.ship, anim.range(13, 15), 12, false)
    clips.ship_move_up = anim.new_clip(sheets.ship, anim.range(25, 27), 12, false)
    clips.ship_explode = anim.new_clip(sheets.ship, anim.range(37, 46), 14, false)
    clips.ship_dash = anim.new_clip(sheets.ship, anim.range(50, 60), 24, false)

    player.x    = screen.width * 0.25
    player.y    = screen.height * 0.5
    player.clips = clips
    player.move = move_player
    player.anim = anim.new_state(clips.ship_idle)
    abilities.equip(player.ability_set, "dash", player_abilities.dash)

    reset_game()

    local ship_bullet_image = love.graphics.newImage("assets/ship_bullets.png")
    sheets.bullets = anim.new_sheet(ship_bullet_image, SHIP_BULLET_FRAME_W, SHIP_BULLET_FRAME_H)

    clips.basic_bullet = anim.new_clip(sheets.bullets, anim.range(1, 4), 12, true)

    local enemy_image = love.graphics.newImage("assets/enemies.png")
    sheets.enemies = anim.new_sheet(enemy_image, ENEMY_FRAME_W, ENEMY_FRAME_H)

    clips.enemy_basic = anim.new_clip(sheets.enemies, anim.range(1, 4), 5, true)
    clips.enemy_basic_bullet = anim.new_clip(sheets.enemies, anim.range(7, 10), 5, true)
end

local function fixed_update()
    if player.flash_timer > 0 then player.flash_timer = player.flash_timer - TICK end

    if player.state == "dying" then
        anim.update(player.anim, TICK)
        if player.anim.finished then player.state = "dead" end
    elseif player.state == "alive" then
        if dash_pressed then
            dash_pressed = false
            abilities.trigger(player.ability_set, "dash", player)
        end

        if not abilities.active(player.ability_set, "dash") then
            local dx = axis("left", "right")
            local dy = axis("up", "down")

            if dx ~= 0 or dy ~= 0 then
                player.face_x, player.face_y = dx, dy
            end

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

            local step = player.speed * TICK
            move_player(player, dx * step, dy * step)

            player.fire_timer = player.fire_timer - TICK
            if love.keyboard.isDown("z") and player.fire_timer <= 0 then
                player.fire_timer = PLAYER_FIRE_RATE
                bullets.spawn(player_bullets, clips.basic_bullet, player.x + 14, player.y,
                    BULLET_SPEED, 0, BULLET_LIFE, PLAYER_BULLET_RADIUS)
            end
        end

        abilities.update(player.ability_set, player, TICK)
        anim.update(player.anim, TICK)
    end

    if player.state == "dead" then return end

    spawn_timer = spawn_timer - TICK
    if spawn_timer <= 0 then
        spawn_timer = 1.5
        enemies.spawn(clips.enemy_basic, screen.width + 16,
            math.random(32, screen.height - 32),
            -ENEMY_SPEED, 0, ENEMY_HP, ENEMY_RADIUS,
            enemy_behaviors.drifter, {
                hold_x          = screen.width * ENEMY_HOLD_X,
                approach_speed  = ENEMY_SPEED,
                amp_x  = ENEMY_AMP_X, amp_y  = ENEMY_AMP_Y,
                rate_x = ENEMY_RATE_X, rate_y = ENEMY_RATE_Y,
            }, ENEMY_SCALE)
    end

    update_enemy_fire()

    bullets.update(player_bullets, TICK, -BULLET_MARGIN, -BULLET_MARGIN, screen.width + BULLET_MARGIN, screen.height + BULLET_MARGIN)
    bullets.update(enemy_bullets,  TICK, -BULLET_MARGIN, -BULLET_MARGIN, screen.width + BULLET_MARGIN, screen.height + BULLET_MARGIN)
    enemies.update(TICK, -BULLET_MARGIN, -BULLET_MARGIN, screen.width + BULLET_MARGIN, screen.height + BULLET_MARGIN)
    
    collide_bullets_enemies()
    collide_player()
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
        bullets.draw(enemy_bullets)
        bullets.draw(player_bullets)
        if player.state ~= "dead" then
            if player.flash_timer > 0 then
                flash.begin(1)
                anim.draw(player.anim, player.x, player.y)
                flash.finish()
            else
                anim.draw(player.anim, player.x, player.y)
            end
        end

        if player.state == "dead" then
            local text = "PRESS SPACE TO RESTART"
            local font = love.graphics.getFont()
            love.graphics.print(text,
                math.floor((screen.width - font:getWidth(text)) * 0.5),
                math.floor(screen.height * 0.5 - font:getHeight() * 0.5))
        end

        if debug_hitboxes then
            love.graphics.setColor(1, 0.2, 0.2, 0.7)
            for i = 1, enemies.count() do
                local e = enemies.get(i)
                love.graphics.circle("line", e.x, e.y, e.radius)
            end
            love.graphics.setColor(0.3, 1, 1, 0.7)
            for i = 1, bullets.count(player_bullets) do
                local b = bullets.get(player_bullets, i)
                love.graphics.circle("line", b.x, b.y, b.radius)
            end
            love.graphics.setColor(1, 1, 1, 1)
        end
    screen.finish_draw()
end

function love.resize(w, h)
    screen.resize(w, h)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "f1" then debug_hitboxes = not debug_hitboxes end
    if key == "x" then dash_pressed = true end
    if key == "space" and player.state == "dead" then reset_game() end
end