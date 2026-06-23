local invisiDetections = 0

AC.runPeriodically(1000, function()
    if not AC.isModuleEnabled(DetectionType.INVISIBLE) then return end
    local ped = PlayerPedId()

    if (not IsEntityVisible(ped) or GetEntityAlpha(ped) == 0) and AC.spawned then
        if HasModelLoaded(joaat("mp_f_freemode_01")) and HasModelLoaded(joaat("mp_m_freemode_01")) then
            SetEntityVisible(ped, true)
            ResetEntityAlpha(ped)
            invisiDetections = invisiDetections + 1
            if invisiDetections > 4 then
                invisiDetections = 0
                AC.punish(DetectionType.INVISIBLE, "Invisibility")
            end
        end
    end

    if AC.isModuleEnabled(DetectionType.PED) then
        local model = GetEntityModel(ped)
        if not AC.whitelistedPeds[model] then
            AC.punish(DetectionType.PED, "Changed ped model: " .. model)
        end
        if GetPedConfigFlag(ped, 223, true) then
            AC.punish(DetectionType.PED, "Tiny ped")
        end
    end
end, "AntiInvisible")
