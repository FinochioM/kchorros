local background = {}

local function round(v) return math.floor(v + 0.5) end

-- layer def: { path, speed, y = 0, tile_y = false, fit = false, scale = 1 }
-- speed: virtual pixels per second (screen space), positive scrolls left
-- fit: scale the image down so its height matches the view
function background.new(defs, view_w, view_h)
    local layers = {}
    for i = 1, #defs do
        local d = defs[i]
        local image = love.graphics.newImage(d.path)
        local w, h  = image:getDimensions()
        local tile_y = d.tile_y and true or false
        local scale  = d.scale or (d.fit and view_h / h) or 1

        image:setWrap("repeat", tile_y and "repeat" or "clamp")

        local src_w = view_w / scale
        local src_h = tile_y and (view_h / scale) or h

        layers[i] = {
            image  = image,
            quad   = love.graphics.newQuad(0, 0, src_w, src_h, w, h),
            w      = w,
            src_w  = src_w,
            src_h  = src_h,
            img_h  = h,
            scale  = scale,
            speed  = (d.speed or 0) / scale, -- store in source px/s
            y      = d.y or 0,
            offset = 0,
        }
    end
    return { layers = layers, view_w = view_w, view_h = view_h }
end

function background.update(bg, dt)
    local layers = bg.layers
    for i = 1, #layers do
        local l = layers[i]
        l.offset = (l.offset + l.speed * dt) % l.w
    end
end

function background.draw(bg)
    local layers = bg.layers
    for i = 1, #layers do
        local l = layers[i]
        l.quad:setViewport(l.offset, 0, l.src_w, l.src_h, l.w, l.img_h)
        love.graphics.draw(l.image, l.quad, 0, round(l.y), 0, l.scale, l.scale)
    end
end

function background.reset(bg)
    local layers = bg.layers
    for i = 1, #layers do layers[i].offset = 0 end
end

return background