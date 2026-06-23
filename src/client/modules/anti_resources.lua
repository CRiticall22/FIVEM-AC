local weaponComponents = {
    joaat("COMPONENT_COMBATPISTOL_CLIP_01"), joaat("COMPONENT_COMBATPISTOL_CLIP_02"),
    joaat("COMPONENT_APPISTOL_CLIP_01"),     joaat("COMPONENT_APPISTOL_CLIP_02"),
    joaat("COMPONENT_MICROSMG_CLIP_01"),     joaat("COMPONENT_MICROSMG_CLIP_02"),
    joaat("COMPONENT_SMG_CLIP_01"),          joaat("COMPONENT_SMG_CLIP_02"),
    joaat("COMPONENT_ASSAULTRIFLE_CLIP_01"), joaat("COMPONENT_ASSAULTRIFLE_CLIP_02"),
    joaat("COMPONENT_CARBINERIFLE_CLIP_01"), joaat("COMPONENT_CARBINERIFLE_CLIP_02"),
    joaat("COMPONENT_ADVANCEDRIFLE_CLIP_01"),joaat("COMPONENT_ADVANCEDRIFLE_CLIP_02"),
    joaat("COMPONENT_MG_CLIP_01"),           joaat("COMPONENT_MG_CLIP_02"),
    joaat("COMPONENT_COMBATMG_CLIP_01"),     joaat("COMPONENT_COMBATMG_CLIP_02"),
    joaat("COMPONENT_PUMPSHOTGUN_CLIP_01"),  joaat("COMPONENT_SAWNOFFSHOTGUN_CLIP_01"),
    joaat("COMPONENT_ASSAULTSHOTGUN_CLIP_01"),joaat("COMPONENT_ASSAULTSHOTGUN_CLIP_02"),
    joaat("COMPONENT_PISTOL50_CLIP_01"),     joaat("COMPONENT_PISTOL50_CLIP_02"),
    joaat("COMPONENT_ASSAULTSMG_CLIP_01"),   joaat("COMPONENT_ASSAULTSMG_CLIP_02"),
    joaat("COMPONENT_AT_RAILCOVER_01"),      joaat("COMPONENT_AT_AR_AFGRIP"),
    joaat("COMPONENT_AT_PI_FLSH"),           joaat("COMPONENT_AT_AR_FLSH"),
    joaat("COMPONENT_AT_SCOPE_MACRO"),       joaat("COMPONENT_AT_SCOPE_SMALL"),
    joaat("COMPONENT_AT_SCOPE_MEDIUM"),      joaat("COMPONENT_AT_SCOPE_LARGE"),
    joaat("COMPONENT_AT_SCOPE_MAX"),         joaat("COMPONENT_AT_PI_SUPP"),
}

AC.runPeriodically(10000, function()
    local ped = PlayerPedId()

    if AC.isModuleEnabled(DetectionType.FOLDER) then
        for i = 1, #weaponComponents do
            local dm = GetWeaponComponentDamageModifier(weaponComponents[i])
            local am = GetWeaponComponentAccuracyModifier(weaponComponents[i])
            if dm > 1.1 or am > 1.2 then
                AC.punish(DetectionType.FOLDER, "Folder cheats detected")
            end
        end
    end

    if AC.isModuleEnabled(DetectionType.NO_HEADSHOT) then
        if GetPedConfigFlag(ped, 2, false) then
            AC.punish(DetectionType.NO_HEADSHOT, "Headshot disabled")
        end
    end

    if AC.isModuleEnabled(DetectionType.SILENT_AIM) then
        local model = GetEntityModel(ped)
        local minD, maxD = GetModelDimensions(model)
        if minD.y < -0.29 or maxD.z > 0.98 then
            AC.punish(DetectionType.SILENT_AIM, "Hitbox extended")
        end
    end

    if AC.isModuleEnabled(DetectionType.COMMANDS) then
        local cmdLookup = {}
        for _, c in ipairs(Config.BlacklistedCommands) do cmdLookup[c] = true end
        for _, cmd in ipairs(GetRegisteredCommands()) do
            if cmdLookup[cmd.name] then
                AC.punish(DetectionType.COMMANDS, "Blacklisted command: " .. cmd.name)
            end
        end
    end

    if AC.isModuleEnabled(DetectionType.VARIABLE) then
        for _, var in ipairs(Config.BlacklistedVariables) do
            if _G[var] ~= nil then
                _G[var] = nil
                AC.punish(DetectionType.VARIABLE, "Blacklisted variable: " .. var)
            end
        end
    end
end, "AntiResources")
