EAC.runPeriodically(1000, function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)
    if not vehicle then return end

    if EAC.isModuleEnabled(DetectionType.PLATE) then
        local plate = GetVehicleNumberPlateText(vehicle, false)
        for _, bp in ipairs(Config.BlacklistedPlates) do
            if plate == bp then
                EAC.punish(DetectionType.PLATE, "Blacklisted plate: " .. bp)
            end
        end
    end

    if EAC.isModuleEnabled(DetectionType.HORN_BOOST) then
        local vModel = GetEntityModel(vehicle)
        local allowed = { [989294410]=true, [884483972]=true, [-638562243]=true, [2069146067]=true }
        if GetHasRocketBoost(vehicle) and not allowed[vModel] then
            if IsVehicleRocketBoostActive(vehicle) then
                EAC.punish(DetectionType.HORN_BOOST, "Horn boost")
            end
        end
    end

    if EAC.isModuleEnabled(DetectionType.VEHICLE_WEAPONS)
       and IsPedInAnyVehicle(ped) and DoesVehicleHaveWeapons(vehicle) then
        local weps = {
            2971687502, 1945616459, 3450622333, 3530961278, 1259576109,
            4026335563, 1566990507, 1186503822, 2669318622, 3473446624,
            4171469727, 1741783703, 2211086889,
        }
        for _, w in ipairs(weps) do
            DisableVehicleWeapon(true, w, vehicle, ped)
        end
    end
end, "AntiVehicle")
