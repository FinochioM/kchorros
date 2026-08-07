local abilities = {}

-- def: { duration, cooldown, on_start(owner, slot), on_update(owner, slot, dt), on_finish(owner, slot) }

function abilities.new_set()
    return {}
end

function abilities.equip(set, name, def)
    set[name] = { def = def, active = 0, cooldown = 0 }
end

function abilities.ready(set, name)
    local s = set[name]
    return s ~= nil and s.active <= 0 and s.cooldown <= 0
end

function abilities.active(set, name)
    local s = set[name]
    return s ~= nil and s.active > 0
end

function abilities.trigger(set, name, owner)
    if not abilities.ready(set, name) then return false end
    local s = set[name]
    s.active = s.def.duration
    if s.def.on_start then s.def.on_start(owner, s) end
    if s.active <= 0 then -- instant: finish immediately
        s.active   = 0
        s.cooldown = s.def.cooldown
        if s.def.on_finish then s.def.on_finish(owner, s) end
    end
    return true
end

function abilities.update(set, owner, dt)
    for _, s in pairs(set) do
        if s.active > 0 then
            s.active = s.active - dt
            if s.def.on_update then s.def.on_update(owner, s, dt) end
            if s.active <= 0 then
                s.active   = 0
                s.cooldown = s.def.cooldown
                if s.def.on_finish then s.def.on_finish(owner, s) end
            end
        elseif s.cooldown > 0 then
            s.cooldown = s.cooldown - dt
        end
    end
end

function abilities.clear(set)
    for _, s in pairs(set) do s.active, s.cooldown = 0, 0 end
end

return abilities