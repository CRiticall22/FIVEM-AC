local inCombat = false
local lastDamageTime = 0
local COMBAT_TIMEOUT = 15000
local lastHealth = 200

AC.registerModule("combatLog", {
    activate = function()
        AC.runPeriodically(500, function()
            local ped = PlayerPedId()
            local health = GetEntityHealth(ped)

            if health < lastHealth and lastHealth > 0 then
                lastDamageTime = GetGameTimer()
                if not inCombat then
                    inCombat = true
                    TriggerServerEvent(EncodeEvent("AC:combatState"), true)
                end
            end

            lastHealth = health

            if IsPedShooting(ped) then
                lastDamageTime = GetGameTimer()
                if not inCombat then
                    inCombat = true
                    TriggerServerEvent(EncodeEvent("AC:combatState"), true)
                end
            end

            if inCombat and (GetGameTimer() - lastDamageTime) > COMBAT_TIMEOUT then
                inCombat = false
                TriggerServerEvent(EncodeEvent("AC:combatState"), false)
            end
        end, "CombatLog")
    end,
    deactivate = function()
        inCombat = false
    end,
})
