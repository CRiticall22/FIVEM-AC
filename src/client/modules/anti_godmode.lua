local godmodeDetections = 0

EAC.runPeriodically(1000, function()
    if not EAC.isModuleEnabled(DetectionType.GODMODE) then return end
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)

    if vehicle and not GetEntityCanBeDamaged(vehicle) then
        SetEntityCanBeDamaged(vehicle, true)
    end
    if not GetEntityCanBeDamaged(ped) then
        SetEntityCanBeDamaged(ped, true)
        godmodeDetections = godmodeDetections + 1
        if godmodeDetections > 3 then
            godmodeDetections = 0
            EAC.punish(DetectionType.GODMODE, "Godmode")
        end
    end
    if (GetPlayerInvincible(EAC.playerId) or GetPlayerInvincible_2(EAC.playerId))
       and not IsEntityPositionFrozen(ped) then
        SetEntityInvincible(ped, false)
        SetEntityCanBeDamaged(ped, true)
        godmodeDetections = godmodeDetections + 1
        if godmodeDetections > 3 then
            godmodeDetections = 0
            EAC.punish(DetectionType.GODMODE, "Godmode (invincible)")
        end
    end
    local bp, fp, ep, cp, mp, sp, p7, dp = GetEntityProofs(ped)
    if fp == 1 or ep == 1 or sp == 1 or p7 == 1 or dp == 1 then
        SetEntityProofs(ped, false, false, false, false, false, false, false, false)
    end

    if EAC.isModuleEnabled(DetectionType.HEALTH) then
        local health = GetEntityHealth(ped)
        local cfg = EAC.getModuleConfig(DetectionType.HEALTH)
        if health > (cfg.max or 200) then
            EAC.punish(DetectionType.HEALTH, "Health: " .. health)
        end
    end

    if EAC.isModuleEnabled(DetectionType.ARMOR) then
        local armor = GetPedArmour(ped)
        local cfg = EAC.getModuleConfig(DetectionType.ARMOR)
        if armor > (cfg.max or 100) then
            EAC.punish(DetectionType.ARMOR, "Armor: " .. armor)
        end
    end
end, "AntiGodmode")
