local invisiDetections = 0

EAC.runPeriodically(1000, function()
    if not EAC.isModuleEnabled(DetectionType.INVISIBLE) then return end
    local ped = PlayerPedId()

    if (not IsEntityVisible(ped) or GetEntityAlpha(ped) == 0) and EAC.spawned then
        if HasModelLoaded(joaat("mp_f_freemode_01")) and HasModelLoaded(joaat("mp_m_freemode_01")) then
            SetEntityVisible(ped, true)
            ResetEntityAlpha(ped)
            invisiDetections = invisiDetections + 1
            if invisiDetections > 4 then
                invisiDetections = 0
                EAC.punish(DetectionType.INVISIBLE, "Invisibility")
            end
        end
    end

    if EAC.isModuleEnabled(DetectionType.PED) then
        local model = GetEntityModel(ped)
        if not EAC.whitelistedPeds[model] then
            EAC.punish(DetectionType.PED, "Changed ped model: " .. model)
        end
        if GetPedConfigFlag(ped, 223, true) then
            EAC.punish(DetectionType.PED, "Tiny ped")
        end
    end
end, "AntiInvisible")
