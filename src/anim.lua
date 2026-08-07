local anim = {}

local function round(value)
    return math.floor(value + 0.5)
end

function anim.new_sheet(image, frame_w, frame_h)
    local image_w, image_h = image:getDimensions()
    local cols = math.floor(image_w / frame_w)
    local rows = math.floor(image_h / frame_h)

    assert(cols > 0 and rows > 0, string.format(
        "frame size %dx%d does not fit in a %dx%d image", frame_w, frame_h, image_w, image_h))

    local quads = {}
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            quads[#quads + 1] = love.graphics.newQuad(
                col * frame_w, row * frame_h, frame_w, frame_h, image_w, image_h)
        end
    end

    return {
        image    = image,
        quads    = quads,
        cols     = cols,
        rows     = rows,
        frame_w  = frame_w,
        frame_h  = frame_h,
        origin_x = frame_w * 0.5, -- pivot used when drawing
        origin_y = frame_h * 0.5,
    }
end

function anim.new_clip(sheet, frames, fps, loop)
    assert(#frames > 0, "a clip needs at least one frame")
    local max = #sheet.quads
    for i = 1, #frames do
        assert(frames[i] >= 1 and frames[i] <= max, string.format(
            "clip frame %d out of range (sheet has %d frames)", frames[i], max))
    end
    return {
        sheet      = sheet,
        frames     = frames,
        frame_time = (fps and fps > 0) and (1 / fps) or 0,
        loop       = loop and true or false,
    }
end

function anim.range(from, to)
    local out = {}
    for i = from, to do out[#out + 1] = i end
    return out
end

function anim.row(sheet, row)
    local first = (row - 1) * sheet.cols + 1
    return anim.range(first, first + sheet.cols - 1)
end

function anim.new_state(clip)
    return {
        clip     = clip,
        frame    = 1, -- index into clip.frames, not into sheet.quads
        time     = 0,
        speed    = 1,
        playing  = true,
        finished = false,
    }
end

function anim.play(state, clip, restart)
    if state.clip == clip and not restart then return end
    state.clip     = clip
    state.frame    = 1
    state.time     = 0
    state.playing  = true
    state.finished = false
end

function anim.set_frame(state, index)
    state.frame = index
    state.time  = 0
end

function anim.update(state, dt)
    local clip = state.clip
    if not state.playing or clip.frame_time <= 0 then return end

    local count = #clip.frames
    if count <= 1 then return end

    state.time = state.time + dt * state.speed
    while state.time >= clip.frame_time do
        state.time = state.time - clip.frame_time
        if state.frame < count then
            state.frame = state.frame + 1
        elseif clip.loop then
            state.frame = 1
        else
            state.playing  = false
            state.finished = true
            state.time     = 0
            break
        end
    end
end

function anim.draw(state, x, y, rotation, scale_x, scale_y)
    local clip  = state.clip
    local sheet = clip.sheet
    local quad  = sheet.quads[clip.frames[state.frame]]

    love.graphics.draw(sheet.image, quad,
        round(x), round(y),
        rotation or 0,
        scale_x or 1, scale_y or scale_x or 1,
        sheet.origin_x, sheet.origin_y)
end

function anim.duration(clip)
    return #clip.frames * clip.frame_time
end

return anim