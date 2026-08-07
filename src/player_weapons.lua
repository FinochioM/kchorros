local bullets = require("src.bullets")

local weapons = {}

-- bullet type: the projectile itself
weapons.bullet_types = {
    { name = "basic",  clip_name = "basic_bullet",
      speed = 200, life = 2.0, radius = 2, damage = 1 },

    { name = "rapid",  clip_name = "rapid_bullet",
      speed = 320, life = 1.4, radius = 2, damage = 1 },

    { name = "heavy",  clip_name = "heavy_bullet",
      speed = 140, life = 2.4, radius = 5, damage = 3 },
}

local function emit(pool, bt, x, y, angle)
    bullets.spawn(pool, bt.clip, x, y,
        math.cos(angle) * bt.speed, math.sin(angle) * bt.speed,
        bt.life, bt.radius, bt.damage)
end

-- shot type: the firing pattern, agnostic of bullet type
weapons.shot_types = {
    { name = "single", fire_rate = 0.28,
      fire = function(pool, s, bt, x, y)
          emit(pool, bt, x, y, 0)
      end },

    { name = "spread", fire_rate = 0.45, angle = 0.28, count = 3,
      fire = function(pool, s, bt, x, y)
          local half = (s.count - 1) * 0.5
          for i = 0, s.count - 1 do
              emit(pool, bt, x, y, (i - half) * s.angle)
          end
      end },

    { name = "twin", fire_rate = 0.24, offset = 6,
      fire = function(pool, s, bt, x, y)
          emit(pool, bt, x, y - s.offset, 0)
          emit(pool, bt, x, y + s.offset, 0)
      end },
}

function weapons.bind_clips(clips)
    for i = 1, #weapons.bullet_types do
        local bt = weapons.bullet_types[i]
        bt.clip = assert(clips[bt.clip_name], "missing clip: " .. bt.clip_name)
    end
end

function weapons.fire(pool, shot_index, bullet_index, x, y)
    local s  = weapons.shot_types[shot_index]
    local bt = weapons.bullet_types[bullet_index]
    s.fire(pool, s, bt, x, y)
    return s.fire_rate
end

function weapons.next_shot(i)   return i % #weapons.shot_types + 1 end
function weapons.next_bullet(i) return i % #weapons.bullet_types + 1 end

return weapons