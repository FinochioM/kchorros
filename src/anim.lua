local anim8 = require("lib.anim8")

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

    return {
        image    = image,
        grid     = anim8.newGrid(frame_w, frame_h, image_w, image_h),
        cols     = cols,
        rows     = rows,
        count    = cols * rows,
        frame_w  = frame_w,
        frame_h  = frame_h,
        origin_x = frame_w * 0.5,
        origin_y = frame_h * 0.5,
    }
end

function anim.new_clip(sheet, frames, fps, loop)
    assert(#frames > 0, "a clip needs at least one frame")
    assert(fps and fps > 0, "a clip needs a positive fps")

    local quads = {}
    for i = 1, #frames do
        local f = frames[i]
        assert(f >= 1 and f <= sheet.count, string.format(
            "clip frame %d out of range (sheet has %d frames)", f, sheet.count))
        local col = (f - 1) % sheet.cols + 1
        local row = math.floor((f - 1) / sheet.cols) + 1
        quads[i] = sheet.grid(col, row)[1]
    end

    loop = loop and true or false

    return {
        sheet      = sheet,
        frame_time = 1 / fps,
        loop       = loop,
        template   = anim8.newAnimation(quads, 1 / fps, not loop and "pauseAtEnd" or nil),
        length     = #frames,
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
        a        = clip.template:clone(),
        speed    = 1,
        finished = false,
    }
end

function anim.play(state, clip, restart)
    if state.clip == clip then
        if not restart then return end
        state.a:gotoFrame(1)
        state.a:resume()
    else
        state.clip = clip
        state.a    = clip.template:clone()
    end
    state.finished = false
end

function anim.set_frame(state, index)
    state.a:gotoFrame(index)
end

function anim.update(state, dt)
    local a = state.a
    if a.status ~= "playing" then return end
    a:update(dt * state.speed)
    if a.status ~= "playing" then state.finished = true end
end

function anim.draw(state, x, y, rotation, scale_x, scale_y)
    local sheet = state.clip.sheet
    state.a:draw(sheet.image,
        round(x), round(y),
        rotation or 0,
        scale_x or 1, scale_y or scale_x or 1,
        sheet.origin_x, sheet.origin_y)
end

function anim.duration(clip)
    return clip.length * clip.frame_time
end

return anim