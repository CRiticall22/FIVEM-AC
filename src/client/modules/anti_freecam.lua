local freecamDetections = 0
local lastPedPos

EAC.runPeriodically(500, function()
    local ped = PlayerPedId()
    if not EAC.spawned then return end

    local camCoord = GetGameplayCamCoord()
    local pedCoord = GetEntityCoords(ped)
    local dist = #(camCoord - pedCoord)

    if dist > 200.0 and not IsPedInAnyVehicle(ped) and not IsScreenFadedOut()
       and not IsEntityDead(ped) and not IsCinematicCamRendering() then
        freecamDetections = freecamDetections + 1
        if freecamDetections >= 5 then
            freecamDetections = 0
            EAC.punish(DetectionType.NOCLIP, "Freecam detected (camera distance: " .. math.floor(dist) .. ")")
        end
    else
        freecamDetections = math.max(0, freecamDetections - 1)
    end

    if EAC.isModuleEnabled(DetectionType.SPECTATE) then
        if lastPedPos then
            local pedSpeed = #(pedCoord - lastPedPos)
            if pedSpeed > 500.0 and not IsScreenFadedOut() and not IsScreenFadingIn() then
                EAC.punish(DetectionType.TELEPORT, "Extreme movement detected")
            end
        end
        lastPedPos = pedCoord
    end
end, "AntiFreecam")
