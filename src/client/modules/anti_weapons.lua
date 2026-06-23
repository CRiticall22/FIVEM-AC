local explosionHash = joaat("WEAPON_EXPLOSION")

EAC.runPeriodically(1000, function()
    local ped = PlayerPedId()

    if EAC.isModuleEnabled(DetectionType.AMMO) then
        SetPedInfiniteAmmoClip(ped, false)
        if IsPedArmed(ped, 6) then
            local wHash = GetSelectedPedWeapon(ped)
            local _, clip = GetAmmoInClip(ped, wHash)
            local _, maxAmmo = GetMaxAmmo(ped, wHash)
            local total = GetAmmoInPedWeapon(ped, wHash)
            if not EAC.whitelistedWeapons[wHash] then
                local cfg = EAC.getModuleConfig(DetectionType.AMMO)
                local maxC = cfg.maxClip or 499
                local maxT = cfg.maxTotal or 499
                if clip > maxC or maxAmmo > maxT then
                    SetPedAmmo(ped, wHash, 0)
                    RemoveWeaponFromPed(ped, wHash)
                    EAC.punish(DetectionType.AMMO, "Infinite ammo")
                end
                if total > maxAmmo or total == -1 then
                    SetPedAmmo(ped, wHash, 0)
                    RemoveWeaponFromPed(ped, wHash)
                    EAC.punish(DetectionType.AMMO, "Excess ammo: " .. total)
                end
            end
        end
    end

    if EAC.isModuleEnabled(DetectionType.WEAPON) then
        for h, _ in pairs(EAC.blacklistedWeapons) do
            if HasPedGotWeapon(ped, h, false) then
                RemoveWeaponFromPed(ped, h)
                EAC.punish(DetectionType.WEAPON, "Blacklisted weapon: " .. h)
            end
        end
    end

    if EAC.isModuleEnabled(DetectionType.DAMAGE_CHANGER) then
        local wHash = GetSelectedPedWeapon(ped)
        if wHash then
            local wDmg = math.floor(GetWeaponDamage(wHash))
            local info = Config.WeaponDamageTable[wHash]
            if info and wDmg > info.damage then
                EAC.punish(DetectionType.DAMAGE_CHANGER, "Modified " .. info.name .. " damage to " .. wDmg)
            end
        end
    end

    if EAC.isModuleEnabled(DetectionType.EXPLOSIVE_WEAPON) then
        SetWeaponDamageModifier(explosionHash, 0.0)
        local wHash = GetSelectedPedWeapon(ped)
        local dt = GetWeaponDamageType(wHash)
        if dt == 4 or dt == 5 or dt == 6 or dt == 13 then
            EAC.punish(DetectionType.EXPLOSIVE_WEAPON, "Explosive weapon damage")
        end
    end
end, "AntiWeapons")

EAC.registerModule("anti_weapons", {
    activate = function()
        EAC.waitForConfig()
        if EAC.isModuleEnabled(DetectionType.DAMAGE_CHANGER) then
            for h, _ in pairs(EAC.blacklistedWeapons) do
                SetWeaponDamageModifier(h, 0.0)
            end
        end
        if EAC.isModuleEnabled("antiVDM") then
            SetWeaponDamageModifier(-1553120962, 0.0)
        end
    end,
    deactivate = function()
        EAC.waitForConfig()
        if EAC.isModuleEnabled(DetectionType.DAMAGE_CHANGER) then
            for h, _ in pairs(EAC.blacklistedWeapons) do
                SetWeaponDamageModifier(h, -1.0)
            end
        end
        if EAC.isModuleEnabled("antiVDM") then
            SetWeaponDamageModifier(-1553120962, -1.0)
        end
    end,
})
