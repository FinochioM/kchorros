local flash = {}

local shader = love.graphics.newShader[[
extern number amount;
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec4 p = Texel(tex, tc) * color;
    return vec4(mix(p.rgb, vec3(1.0), amount), p.a);
}
]]

flash.DURATION = 0.08

function flash.begin(amount)
    love.graphics.setShader(shader)
    shader:send("amount", amount or 1)
end

function flash.finish()
    love.graphics.setShader()
end

return flash