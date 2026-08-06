local screen = {
    width = 0,
    height = 0,
    scale = 1,
    offset_x = 0,
    offset_y = 0,
    canvas = nil,
}

function screen.init(width, height)
    screen.width = width
    screen.height = height
    screen.canvas = love.graphics.newCanvas(width, height)
    screen.resize(love.graphics.getDimensions())
end

function screen.resize(window_w, window_h)
    local fit = math.min(window_w / screen.width, window_h / screen.height)

    screen.scale = math.max(1, math.floor(fit))
    screen.offset_x = math.floor((window_w - screen.width * screen.scale) * 0.5)
    screen.offset_y = math.floor((window_h - screen.height * screen.scale) * 0.5)
end

function screen.begin_draw()
    love.graphics.setCanvas(screen.canvas)
    love.graphics.clear(0.05, 0.05, 0.08, 1)
end

function screen.finish_draw()
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(screen.canvas, screen.offset_x, screen.offset_y, 0, screen.scale, screen.scale)
end

return screen