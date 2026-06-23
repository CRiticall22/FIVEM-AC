local teleportPosList = {}
local lastTeleportCheck
local lastTeleportTime = 0

AC.runPeriodically(300, function()
    if not AC.isModuleEnabled(DetectionType.TELEPORT) then return end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    if lastTeleportCheck and IsPedOnFoot(ped) then
        local d = #(vector2(coords.x, coords.y) - vector2(lastTeleportCheck.x, lastTeleportCheck.y))
        if d > 50.0 and not IsScreenFadedOut() and not IsScreenFadingIn()
           and not IsScreenFadingOut() then
            lastTeleportTime = GetGameTimer()
            table.insert(teleportPosList, 1, coords)
            if #teleportPosList >= 3 then
                local hashes = {}
                local unique = 0
                for _, p in ipairs(teleportPosList) do
                    local h = math.floor(p.x/15 + p.y/15 + p.z/15)
                    if not hashes[h] then hashes[h] = true; unique = unique + 1 end
                end
                if unique >= 4 then
                    teleportPosList = {}
                    AC.punish(DetectionType.TELEPORT, "Teleport hacks")
                end
            end
        end
    else
        teleportPosList = {}
    end
    if IsPlayerDead(AC.playerId) then teleportPosList = {} end
    if GetGameTimer() - lastTeleportTime > 20000 then teleportPosList = {} end
    lastTeleportCheck = coords
end, "AntiTeleport")

AC.runPeriodically(300, function()
    if not AC.isModuleEnabled(DetectionType.LICENSE_CLEAR) then return end
    if ForceSocialClubUpdate == nil then
        AC.punish(DetectionType.LICENSE_CLEAR, "License clear (social club)")
    end
    if ShutdownAndLaunchSinglePlayerGame == nil then
        AC.punish(DetectionType.LICENSE_CLEAR, "License clear (single player)")
    end
    if ActivateRockstarEditor == nil then
        AC.punish(DetectionType.LICENSE_CLEAR, "License clear (rockstar editor)")
    end
end, "AntiLicenseClear")
