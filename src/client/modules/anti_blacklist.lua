local blacklistedPickups = {
    joaat("PICKUP_WEAPON_BULLPUPSHOTGUN"), joaat("PICKUP_WEAPON_ASSAULTSMG"),
    joaat("PICKUP_WEAPON_PISTOL50"), joaat("PICKUP_AMMO_BULLET_MP"),
    joaat("PICKUP_AMMO_MISSILE_MP"), joaat("PICKUP_AMMO_GRENADELAUNCHER_MP"),
    joaat("PICKUP_WEAPON_ASSAULTRIFLE"), joaat("PICKUP_WEAPON_CARBINERIFLE"),
    joaat("PICKUP_WEAPON_ADVANCEDRIFLE"), joaat("PICKUP_WEAPON_MG"),
    joaat("PICKUP_WEAPON_COMBATMG"), joaat("PICKUP_WEAPON_SNIPERRIFLE"),
    joaat("PICKUP_WEAPON_HEAVYSNIPER"), joaat("PICKUP_WEAPON_MICROSMG"),
    joaat("PICKUP_WEAPON_SMG"), joaat("PICKUP_ARMOUR_STANDARD"),
    joaat("PICKUP_WEAPON_RPG"), joaat("PICKUP_WEAPON_MINIGUN"),
    joaat("PICKUP_HEALTH_STANDARD"), joaat("PICKUP_WEAPON_PUMPSHOTGUN"),
    joaat("PICKUP_WEAPON_SAWNOFFSHOTGUN"), joaat("PICKUP_WEAPON_ASSAULTSHOTGUN"),
    joaat("PICKUP_WEAPON_GRENADE"), joaat("PICKUP_WEAPON_MOLOTOV"),
    joaat("PICKUP_WEAPON_SMOKEGRENADE"), joaat("PICKUP_WEAPON_STICKYBOMB"),
    joaat("PICKUP_WEAPON_PISTOL"), joaat("PICKUP_WEAPON_COMBATPISTOL"),
    joaat("PICKUP_WEAPON_APPISTOL"), joaat("PICKUP_WEAPON_GRENADELAUNCHER"),
    joaat("PICKUP_MONEY_VARIABLE"), joaat("PICKUP_WEAPON_STUNGUN"),
    joaat("PICKUP_WEAPON_PETROLCAN"), joaat("PICKUP_WEAPON_KNIFE"),
    joaat("PICKUP_WEAPON_BAT"), joaat("PICKUP_WEAPON_HAMMER"),
    joaat("PICKUP_WEAPON_CROWBAR"), joaat("PICKUP_WEAPON_RAILGUN"),
    joaat("PICKUP_WEAPON_HEAVYSHOTGUN"), joaat("PICKUP_WEAPON_MARKSMANRIFLE"),
    joaat("PICKUP_WEAPON_HOMINGLAUNCHER"), joaat("PICKUP_WEAPON_GUSENBERG"),
    joaat("PICKUP_WEAPON_FLAREGUN"), joaat("PICKUP_WEAPON_COMBATSHOTGUN"),
    joaat("PICKUP_WEAPON_MILITARYRIFLE"), joaat("PICKUP_WEAPON_COMPACTRIFLE"),
    joaat("PICKUP_WEAPON_DBSHOTGUN"), joaat("PICKUP_WEAPON_MACHETE"),
    joaat("PICKUP_WEAPON_MACHINEPISTOL"), joaat("PICKUP_WEAPON_REVOLVER"),
    joaat("PICKUP_WEAPON_AUTOSHOTGUN"), joaat("PICKUP_WEAPON_MINISMG"),
    joaat("PICKUP_WEAPON_POOLCUE"), joaat("PICKUP_WEAPON_WRENCH"),
    joaat("PICKUP_WEAPON_STONE_HATCHET"), joaat("PICKUP_WEAPON_TACTICALRIFLE"),
    joaat("PICKUP_WEAPON_PRECISIONRIFLE"), joaat("PICKUP_WEAPON_EMPLAUNCHER"),
    joaat("PICKUP_WEAPON_HEAVYRIFLE"), joaat("PICKUP_PARACHUTE"),
}

EAC.registerModule("anti_blacklist", {
    activate = function()
        EAC.waitForConfig()
        if EAC.isModuleEnabled(DetectionType.PICKUP) then
            for i = 1, #blacklistedPickups do
                ToggleUsePickupsForPlayer(EAC.playerId, blacklistedPickups[i], false)
            end
        end
    end,
})

EAC.runPeriodically(1000, function()
    local ped = PlayerPedId()

    if EAC.isModuleEnabled(DetectionType.PED_TASKS) then
        for _, tid in ipairs(Config.BlacklistedTasks) do
            if GetIsTaskActive(ped, tid) then
                ClearPedTasksImmediately(ped)
                ClearPedTasks(ped)
                ClearPedSecondaryTask(ped)
                EAC.punish(DetectionType.PED_TASKS, "Blacklisted task: " .. tid)
            end
        end
    end

    if EAC.isModuleEnabled(DetectionType.ANIMS) then
        for _, anim in ipairs(Config.BlacklistedAnims) do
            if IsEntityPlayingAnim(ped, anim[1], anim[2], 3) then
                ClearPedTasksImmediately(ped)
                EAC.punish(DetectionType.ANIMS, "Blacklisted anim: " .. anim[1])
            end
        end
    end
end, "AntiBlacklist")

local blEvents = { "neweden_garage:pay", "projektsantos:mandathajs", "esx_dmvschool:pay" }
for _, ev in ipairs(blEvents) do
    RegisterNetEvent(ev)
    AddEventHandler(ev, function(amount)
        if EAC.isModuleEnabled(DetectionType.MENU) then
            if type(amount) == "number" and amount < 0 then
                EAC.punish(DetectionType.MENU, "Negative pay event: " .. ev)
            end
        end
    end)
end

AddEventHandler("gameEventTriggered", function(name, args)
    if not EAC.active or not EAC.config then return end
    local ped = PlayerPedId()
    local pickupEvents = {
        ["CEventNetworkPlayerCollectedPickup"] = true,
        ["CEventNetworkPlayerCollectedAmbientPickup"] = true,
        ["CEventNetworkPlayerCollectedPortablePickup"] = true,
    }

    if EAC.isModuleEnabled(DetectionType.PICKUP) and pickupEvents[name] then
        EAC.punish(DetectionType.PICKUP, "Collected a pickup")
    end

    if EAC.isModuleEnabled(DetectionType.WEAPON_SPOOFER)
       and name == "CEventNetworkEntityDamage" then
        local victim, attacker = args[1], args[2]
        local wHash = args[4]
        local unarmed = joaat("WEAPON_UNARMED")
        if victim and attacker then
            local aWeapon = GetSelectedPedWeapon(attacker)
            if wHash ~= aWeapon and aWeapon == unarmed and wHash ~= unarmed then
                if attacker == ped and not IsPedInAnyVehicle(ped)
                   and attacker ~= victim and IsPedStill(ped) then
                    local d = #(GetEntityCoords(ped) - GetEntityCoords(attacker))
                    if d >= 10.0 then
                        EAC.punish(DetectionType.WEAPON_SPOOFER, "Weapon spoofing")
                    end
                end
            end
        end
    end
end)
