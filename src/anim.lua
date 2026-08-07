local anim8 = require("lib.anim8")

local anim = {}

local function round(value)
    return math.floor(value + 0.5)
end

-- frame index helpers -------------------------------------------------

function anim.range(from, to)
    local out = {}
    local step = from <= to and 1 or -1
    for i = from, to, step do out[#out + 1] = i end
    return out
end

function anim.stride(from, to, step)
    local out = {}
    for i = from, to, step do out[#out + 1] = i end
    return out
end

-- keep(i, frame) -> boolean; i is 1-based position in the input list
function anim.filter(frames, keep)
    local out = {}
    for i = 1, #frames do
        if keep(i, frames[i]) then out[#out + 1] = frames[i] end
    end
    return out
end

function anim.concat(...)
    local out = {}
    for _, list in ipairs({...}) do
        for i = 1, #list do out[#out + 1] = list[i] end
    end
    return out
end

-- sheets --------------------------------------------------------------

function anim.new_sheet(image, frame_w, frame_h)
    local image_w, image_h = image:getDimensions()
    local cols = math.floor(image_w / frame_w)
    local rows = math.floor(image_h / frame_h)

    assert(cols > 0 and rows > 0, string.format(
        "frame size %dx%d does not fit in a %dx%d image", frame_w, frame_h, image_w, image_h))

    local grid  = anim8.newGrid(frame_w, frame_h, image_w, image_h)
    local quads, ox, oy = {}, {}, {}
    for row = 1, rows do
        for col = 1, cols do
            local i = (row - 1) * cols + col
            quads[i] = grid(col, row)[1]
            ox[i], oy[i] = frame_w * 0.5, frame_h * 0.5
        end
    end

    return {
        image   = image,
        quads   = quads,
        ox      = ox,
        oy      = oy,
        cols    = cols,
        rows    = rows,
        count   = cols * rows,
        frame_w = frame_w,
        frame_h = frame_h,
    }
end

-- packed sheet: frames found by cutting on fully transparent rows/columns.
-- frames may differ in size; each is centered on its own bounds when drawn.
function anim.new_atlas(path, alpha_min)
    alpha_min = alpha_min or 0.004
    local data  = love.image.newImageData(path)
    local image = love.graphics.newImage(data)
    local w, h  = data:getDimensions()

    local row_used, col_used = {}, {}
    for y = 0, h - 1 do
        for x = 0, w - 1 do
            local _, _, _, a = data:getPixel(x, y)
            if a > alpha_min then
                row_used[y] = true
                col_used[x] = true
            end
        end
    end

    local function runs(used, n)
        local out, start = {}, nil
        for i = 0, n - 1 do
            if used[i] and not start then start = i end
            if not used[i] and start then out[#out + 1] = { start, i - 1 }; start = nil end
        end
        if start then out[#out + 1] = { start, n - 1 } end
        return out
    end

    local function band_col_runs(y0, y1)
        local used = {}
        for x = 0, w - 1 do
            if col_used[x] then
                for y = y0, y1 do
                    local _, _, _, a = data:getPixel(x, y)
                    if a > alpha_min then used[x] = true; break end
                end
            end
        end
        return runs(used, w)
    end

    local quads, ox, oy = {}, {}, {}
    for _, band in ipairs(runs(row_used, h)) do
        local y0, y1 = band[1], band[2]
        for _, span in ipairs(band_col_runs(y0, y1)) do
            local x0, x1 = span[1], span[2]
            local fw, fh = x1 - x0 + 1, y1 - y0 + 1
            local i = #quads + 1
            quads[i] = love.graphics.newQuad(x0, y0, fw, fh, w, h)
            ox[i], oy[i] = fw * 0.5, fh * 0.5
        end
    end

    assert(#quads > 0, "atlas has no visible frames")

    return {
        image = image,
        quads = quads,
        ox    = ox,
        oy    = oy,
        count = #quads,
    }
end

-- clips ---------------------------------------------------------------

function anim.new_clip(sheet, frames, fps, loop)
    assert(#frames > 0, "a clip needs at least one frame")
    assert(fps and fps > 0, "a clip needs a positive fps")

    local quads, ox, oy = {}, {}, {}
    for i = 1, #frames do
        local f = frames[i]
        assert(f >= 1 and f <= sheet.count, string.format(
            "clip frame %d out of range (sheet has %d frames)", f, sheet.count))
        quads[i] = sheet.quads[f]
        ox[i], oy[i] = sheet.ox[f], sheet.oy[f]
    end

    loop = loop and true or false

    return {
        sheet      = sheet,
        ox         = ox,
        oy         = oy,
        frame_time = 1 / fps,
        loop       = loop,
        template   = anim8.newAnimation(quads, 1 / fps, not loop and "pauseAtEnd" or nil),
        length     = #frames,
    }
end

function anim.row(sheet, row)
    local first = (row - 1) * sheet.cols + 1
    return anim.range(first, first + sheet.cols - 1)
end

-- state ---------------------------------------------------------------

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
    local clip = state.clip
    local p    = state.a.position
    state.a:draw(clip.sheet.image,
        round(x), round(y),
        rotation or 0,
        scale_x or 1, scale_y or scale_x or 1,
        clip.ox[p], clip.oy[p])
end

function anim.duration(clip)
    return clip.length * clip.frame_time
end

return anim