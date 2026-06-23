local fovViolations = 0

AC.runPeriodically(2000, function()
    local ped = PlayerPedId()

    if not IsPedArmed(ped, 6) then
        fovViolations = 0
        return
    end

    if not IsPlayerFreeAiming(AC.playerId) then return end

    local fov = GetGameplayCamFov()

    if fov < 20.0 and not IsPedInAnyVehicle(ped) then
        local wHash = GetSelectedPedWeapon(ped)
        local snipers = {
            [100416529]  = true,
            [205991906]  = true,
            [-952879014] = true,
            [177293209]  = true,
            [1785463520] = true,
        }
        if not snipers[wHash] then
            fovViolations = fovViolations + 1
            if fovViolations >= 3 then
                fovViolations = 0
                AC.punish(DetectionType.AIMBOT, "Suspicious FOV while aiming: " .. math.floor(fov))
            end
        end
    else
        fovViolations = 0
    end
end, "AntiFOV")
