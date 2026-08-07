local specials = {}

-- special: an ability def whose payload is data, not movement
specials.defs = {}

specials.defs.missile = {
    duration = 0, -- instant
    cooldown = 2.0,
    bullet = {
        clip_name = "heavy_bullet",
        speed = 120, life = 3.0, radius = 5, damage = 99,
        blast = { radius = 34, damage = 99, clip_name = "blast_explode", scale = 1.4 },
    },

    on_start = function(p, slot)
        p.fire_special(p, slot.def.bullet)
    end,
}

function specials.bind_clips(clips)
    for _, def in pairs(specials.defs) do
        local bt = def.bullet
        if bt then
            bt.clip = assert(clips[bt.clip_name], "missing clip: " .. bt.clip_name)
            if bt.blast then
                bt.blast.clip = assert(clips[bt.blast.clip_name], "missing clip: " .. bt.blast.clip_name)
            end
        end
    end
end

return specials