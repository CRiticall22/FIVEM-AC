local explosionHash = joaat("WEAPON_EXPLOSION")

AC.runPeriodically(1000, function()
    local ped = PlayerPedId()

    if AC.isModuleEnabled(DetectionType.AMMO) then
        SetPedInfiniteAmmoClip(ped, false)
        if IsPedArmed(ped, 6) then
            local wHash = GetSelectedPedWeapon(ped)
            local _, clip = GetAmmoInClip(ped, wHash)
            local _, maxAmmo = GetMaxAmmo(ped, wHash)
            local total = GetAmmoInPedWeapon(ped, wHash)
            if not AC.whitelistedWeapons[wHash] then
                local cfg = AC.getModuleConfig(DetectionType.AMMO)
                local maxC = cfg.maxClip or 499
                local maxT = cfg.maxTotal or 499
                if clip > maxC or maxAmmo > maxT then
                    SetPedAmmo(ped, wHash, 0)
                    RemoveWeaponFromPed(ped, wHash)
                    AC.punish(DetectionType.AMMO, "Infinite ammo")
                end
                if total > maxAmmo or total == -1 then
                    SetPedAmmo(ped, wHash, 0)
                    RemoveWeaponFromPed(ped, wHash)
                    AC.punish(DetectionType.AMMO, "Excess ammo: " .. total)
                end
            end
        end
    end

    if AC.isModuleEnabled(DetectionType.WEAPON) then
        for h, _ in pairs(AC.blacklistedWeapons) do
            if HasPedGotWeapon(ped, h, false) then
                RemoveWeaponFromPed(ped, h)
                AC.punish(DetectionType.WEAPON, "Blacklisted weapon: " .. h)
            end
        end
    end

    if AC.isModuleEnabled(DetectionType.DAMAGE_CHANGER) then
        local wHash = GetSelectedPedWeapon(ped)
        if wHash then
            local wDmg = math.floor(GetWeaponDamage(wHash))
            local info = Config.WeaponDamageTable[wHash]
            if info and wDmg > info.damage then
                AC.punish(DetectionType.DAMAGE_CHANGER, "Modified " .. info.name .. " damage to " .. wDmg)
            end
        end
    end

    if AC.isModuleEnabled(DetectionType.EXPLOSIVE_WEAPON) then
        SetWeaponDamageModifier(explosionHash, 0.0)
        local wHash = GetSelectedPedWeapon(ped)
        local dt = GetWeaponDamageType(wHash)
        if dt == 4 or dt == 5 or dt == 6 or dt == 13 then
            AC.punish(DetectionType.EXPLOSIVE_WEAPON, "Explosive weapon damage")
        end
    end
end, "AntiWeapons")

AC.registerModule("anti_weapons", {
    activate = function()
        AC.waitForConfig()
        if AC.isModuleEnabled(DetectionType.DAMAGE_CHANGER) then
            for h, _ in pairs(AC.blacklistedWeapons) do
                SetWeaponDamageModifier(h, 0.0)
            end
        end
        if AC.isModuleEnabled("antiVDM") then
            SetWeaponDamageModifier(-1553120962, 0.0)
        end
    end,
    deactivate = function()
        AC.waitForConfig()
        if AC.isModuleEnabled(DetectionType.DAMAGE_CHANGER) then
            for h, _ in pairs(AC.blacklistedWeapons) do
                SetWeaponDamageModifier(h, -1.0)
            end
        end
        if AC.isModuleEnabled("antiVDM") then
            SetWeaponDamageModifier(-1553120962, -1.0)
        end
    end,
})
