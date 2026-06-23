local explosionCounts = {}
local nonSpamExplosions = { [13] = true, [30] = true }

AddEventHandler("explosionEvent", function(src, data)
    if not EACS.active then return end
    if not Config.Modules.antiExplosion.enabled then return end

    local etype = Config.ExplosionTypes[data.explosionType]
    if etype then
        if etype.ban then
            CancelEvent()
            PunishPlayer(src, DetectionType.EXPLOSION, "Blacklisted explosion: " .. etype.name)
            return
        end
    else
        CancelEvent()
        return
    end

    if not explosionCounts[src] then
        explosionCounts[src] = { count = 0, time = os.time() }
    end
    if os.time() - explosionCounts[src].time >= 10 then
        explosionCounts[src] = { count = 0, time = os.time() }
    end

    if not nonSpamExplosions[data.explosionType] then
        explosionCounts[src].count = explosionCounts[src].count + 1
        explosionCounts[src].time  = os.time()
    end

    if explosionCounts[src].count >= Config.Modules.antiExplosion.max then
        CancelEvent()
        PunishPlayer(src, DetectionType.EXPLOSION, "Explosion spam: " .. explosionCounts[src].count .. "x")
    end

    if data.damageScale and data.damageScale > 1.0 then
        CancelEvent()
        PunishPlayer(src, DetectionType.EXPLOSION, "Mortal explosion")
    end
    if data.isInvisible == true then
        CancelEvent()
        PunishPlayer(src, DetectionType.EXPLOSION, "Invisible explosion")
    end
    if data.isAudible == false then
        CancelEvent()
        PunishPlayer(src, DetectionType.EXPLOSION, "Silent explosion")
    end
end)

AddEventHandler("playerDropped", function()
    explosionCounts[source] = nil
end)
