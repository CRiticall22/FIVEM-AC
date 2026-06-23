local combatPlayers = {}

RegisterNetEvent(EncodeEvent("AC:combatState"), function(inCombat)
    local src = source
    if not ACS or not ACS.active then return end

    local cfg = Config.Modules.combatLog
    if not cfg or not cfg.enabled then return end

    if inCombat then
        combatPlayers[src] = GetGameTimer()
    else
        combatPlayers[src] = nil
    end
end)

AddEventHandler("playerDropped", function(reason)
    local src = source
    local cfg = Config.Modules.combatLog
    if not cfg or not cfg.enabled then return end

    if combatPlayers[src] then
        local combatDuration = GetGameTimer() - combatPlayers[src]
        combatPlayers[src] = nil

        local name = GetPlayerName(src) or "Unknown"
        Log("WARN", ("[COMBAT_LOG] %s (ID:%d) disconnected during combat (in combat for %.1fs, reason: %s)"):format(name, src, combatDuration / 1000, reason))

        if AddThreatScore then
            AddThreatScore(src, "combatLog", 35)
        end

        local ids = {}
        for _, id in ipairs(GetPlayerIdentifiers(src) or {}) do
            ids[#ids + 1] = id
        end

        local kvpKey = "combatlog:" .. (ids[1] or tostring(src))
        local existing = GetResourceKvpString(kvpKey) or "0"
        local count = tonumber(existing) + 1
        SetResourceKvp(kvpKey, tostring(count))

        if count >= (cfg.maxLogs or 3) then
            BanPlayer(src, "combatLog", ("Combat logged %d times"):format(count))
        end

        local webhookData = {
            player = name,
            reason = ("Combat log #%d — disconnected while in combat (%.1fs)"):format(count, combatDuration / 1000),
            type = "WARN",
        }

        for adminPid, _ in pairs(ACS.connectedPlayers) do
            if IsPlayerAceAllowed(tostring(adminPid), Config.Whitelist.AcePerm) then
                TriggerClientEvent(EncodeEvent("AC:detectionNotify"), adminPid, webhookData)
            end
        end
    end
end)
