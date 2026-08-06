function love.conf(t)
    t.identity = "thunder"
    t.version = "11.5"

    t.window.title = "untitled game"
    t.window.width = 320 * 3
    t.window.height = 224 * 3
    t.window.minwidth = 320
    t.window.minheight = 224
    t.window.resizable = true
    t.window.vsync = 1

    t.modules.physics = false
    t.modules.touch = false
end