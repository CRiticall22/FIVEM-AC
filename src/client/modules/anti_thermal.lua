EAC.runPeriodically(1000, function()
    local ped = PlayerPedId()

    if EAC.isModuleEnabled(DetectionType.NIGHT_VISION) then
        if GetUsingnightvision(true) and not IsPedInAnyHeli(ped) then
            EAC.punish(DetectionType.NIGHT_VISION, "Night vision")
        end
    end

    if EAC.isModuleEnabled(DetectionType.THERMAL_VISION) then
        if GetUsingseethrough(true) and not IsPedInAnyHeli(ped) then
            EAC.punish(DetectionType.THERMAL_VISION, "Thermal vision")
        end
    end

    if EAC.isModuleEnabled(DetectionType.AIM_ASSIST) then
        if NetworkGetTargetingMode() ~= 3 or GetLocalPlayerAimState() ~= 3 then
            SetPlayerTargetingMode(3)
        end
    end
end, "AntiThermal")
