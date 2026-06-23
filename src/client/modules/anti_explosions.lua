local recentExplosions = {}
local EXPLOSION_WINDOW = 5000

EAC.runPeriodically(500, function()
    if not EAC.isModuleEnabled(DetectionType.EXPLOSION) then return end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local now = GetGameTimer()
    local newList = {}
    for _, entry in ipairs(recentExplosions) do
        if now - entry.time < EXPLOSION_WINDOW then
            newList[#newList + 1] = entry
        end
    end
    recentExplosions = newList

    local dangerousTypes = { 2, 4, 5, 26, 29, 30 }
    for _, eType in ipairs(dangerousTypes) do
        if IsExplosionInArea(eType, coords.x - 5, coords.y - 5, coords.z - 5,
                                     coords.x + 5, coords.y + 5, coords.z + 5) then
            local found = false
            for _, entry in ipairs(recentExplosions) do
                if entry.type == eType and now - entry.time < 1000 then
                    found = true
                    break
                end
            end
            if not found then
                recentExplosions[#recentExplosions + 1] = { type = eType, time = now }
            end
        end
    end
end, "AntiExplosions")
