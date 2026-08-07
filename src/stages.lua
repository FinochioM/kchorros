local stages = {}

-- layers are drawn in order: index 1 is farthest back
stages.list = {
    {
        name = "stage_1",
        layers = {
            { path = "assets/bg/stage1/0.png", speed = 1,   fit = true, tile_y = true },
            { path = "assets/bg/stage1/1.png", speed = 5,  fit = true },
            { path = "assets/bg/stage1/2.png", speed = 20,  fit = true },
            { path = "assets/bg/stage1/3.png", speed = 40,  fit = true },
            { path = "assets/bg/stage1/4.png", speed = 200,  fit = true },
            { path = "assets/bg/stage1/5.png", speed = 850, fit = true },
        },
    },
}

return stages