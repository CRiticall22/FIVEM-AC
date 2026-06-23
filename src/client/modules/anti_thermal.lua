AC.runPeriodically(1000, function()
    local ped = PlayerPedId()

    if AC.isModuleEnabled(DetectionType.NIGHT_VISION) then
        if GetUsingnightvision(true) and not IsPedInAnyHeli(ped) then
            AC.punish(DetectionType.NIGHT_VISION, "Night vision")
        end
    end

    if AC.isModuleEnabled(DetectionType.THERMAL_VISION) then
        if GetUsingseethrough(true) and not IsPedInAnyHeli(ped) then
            AC.punish(DetectionType.THERMAL_VISION, "Thermal vision")
        end
    end

    if AC.isModuleEnabled(DetectionType.AIM_ASSIST) then
        if NetworkGetTargetingMode() ~= 3 or GetLocalPlayerAimState() ~= 3 then
            SetPlayerTargetingMode(3)
        end
    end
end, "AntiThermal")
