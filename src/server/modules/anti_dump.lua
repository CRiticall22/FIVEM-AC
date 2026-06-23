local connectTimes = {}
local spawnedPlayers = {}
local suspiciousConnections = {}
local DUMP_THRESHOLD_MS = 12000
local MAX_SUSPICIOUS = 3

AddEventHandler("playerConnecting", function(name, _, deferrals)
    local src = source
    connectTimes[src] = GetGameTimer()
end)

RegisterNetEvent(EncodeEvent("AC:playerSpawned"), function()
    local src = source
    spawnedPlayers[src] = true
end)

AddEventHandler("playerDropped", function(reason)
    local src = source
    local cfg = Config.Modules.antiDump
    if not cfg or not cfg.enabled then
        connectTimes[src] = nil
        spawnedPlayers[src] = nil
        return
    end

    local connectTime = connectTimes[src]
    local didSpawn = spawnedPlayers[src]

    connectTimes[src] = nil
    spawnedPlayers[src] = nil

    if not connectTime then return end

    local sessionDuration = GetGameTimer() - connectTime

    if sessionDuration < DUMP_THRESHOLD_MS and not didSpawn then
        local name = GetPlayerName(src) or "Unknown"
        local identifiers = {}
        for _, id in ipairs(GetPlayerIdentifiers(src) or {}) do
            identifiers[#identifiers + 1] = id
        end
        local idKey = identifiers[1] or tostring(src)

        suspiciousConnections[idKey] = (suspiciousConnections[idKey] or 0) + 1

        Log("WARN", ("[ANTI_DUMP] %s connected for %.1fs without spawning (attempt #%d) — possible server dumper"):format(
            name, sessionDuration / 1000, suspiciousConnections[idKey]))

        for adminPid, _ in pairs(ACS.connectedPlayers) do
            if IsPlayerAceAllowed(tostring(adminPid), Config.Branding.AcePerm) then
                TriggerClientEvent(EncodeEvent("AC:detectionNotify"), adminPid, {
                    player = name,
                    reason = ("Possible server dump: connected %.1fs, no spawn (attempt #%d)"):format(
                        sessionDuration / 1000, suspiciousConnections[idKey]),
                    type = "WARN",
                })
            end
        end

        if suspiciousConnections[idKey] >= MAX_SUSPICIOUS then
            for _, id in ipairs(identifiers) do
                local license = id:match("license:(.+)")
                if license then
                    local banRecord = {
                        name = name,
                        identifiers = identifiers,
                        reason = "[2F4R] Server dumping detected — " .. suspiciousConnections[idKey] .. " rapid connect/disconnect cycles without spawning",
                        banId = GenerateBanId(),
                        date = os.date("%Y-%m-%d %H:%M"),
                    }
                    SetResourceKvp("ban:" .. banRecord.banId, json.encode(banRecord))
                    Log("WARN", ("[ANTI_DUMP] Auto-banned %s for repeated dump-like connections"):format(name))
                    break
                end
            end
            suspiciousConnections[idKey] = 0
        end

        if SendEnhancedWebhook then
            SendEnhancedWebhook("WARN", name, src, "antiDump",
                ("Connected for %.1fs without spawning ped (attempt #%d)"):format(sessionDuration / 1000, suspiciousConnections[idKey] or 1))
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(300000)
        local now = GetGameTimer()
        for src, t in pairs(connectTimes) do
            if (now - t) > 600000 then
                connectTimes[src] = nil
            end
        end
    end
end)
