local connectTimes = {}
local spawnedPlayers = {}
local loadingStages = {}
local suspiciousConnections = {}
local challengeResponses = {}
local DUMP_THRESHOLD_MS = 12000
local MAX_SUSPICIOUS = 3
local CHALLENGE_TIMEOUT = 30000

AddEventHandler("playerConnecting", function(name, _, deferrals)
    local src = source
    connectTimes[src] = GetGameTimer()
    loadingStages[src] = { connecting = true }
end)

RegisterNetEvent(EncodeEvent("AC:loadStage"), function(stage)
    local src = source
    if not loadingStages[src] then loadingStages[src] = {} end
    loadingStages[src][stage] = GetGameTimer()
end)

RegisterNetEvent(EncodeEvent("AC:playerSpawned"), function()
    local src = source
    spawnedPlayers[src] = true
    if loadingStages[src] then
        loadingStages[src].spawned = GetGameTimer()
    end
end)

RegisterNetEvent(EncodeEvent("AC:dumpChallenge"), function(response)
    local src = source
    if not challengeResponses[src] then return end

    local expected = challengeResponses[src].expected
    if response == expected then
        challengeResponses[src].passed = true
    else
        local name = GetPlayerName(src) or "Unknown"
        Log("WARN", ("[ANTI_DUMP] %s (ID:%d) failed dump challenge (expected=%s, got=%s)"):format(name, src, tostring(expected), tostring(response)))
        if AddThreatScore then AddThreatScore(src, "dumpChallenge", 40) end
    end
end)

local function sendChallenge(src)
    local challenge = math.random(100000, 999999)
    local expected = (challenge * 7 + 42) % 1000000

    challengeResponses[src] = {
        challenge = challenge,
        expected = expected,
        sent = GetGameTimer(),
        passed = false,
    }

    TriggerClientEvent(EncodeEvent("AC:dumpChallengeRequest"), src, challenge)

    Citizen.SetTimeout(CHALLENGE_TIMEOUT, function()
        if challengeResponses[src] and not challengeResponses[src].passed then
            local name = GetPlayerName(src) or "Unknown"
            if GetPlayerName(src) then
                Log("WARN", ("[ANTI_DUMP] %s (ID:%d) did not respond to dump challenge within %ds"):format(name, src, CHALLENGE_TIMEOUT / 1000))
                if AddThreatScore then AddThreatScore(src, "dumpNoResponse", 25) end
            end
        end
    end)
end

local function getPlayerIP(src)
    local ep = GetPlayerEndpoint(src)
    if not ep then return "unknown" end
    return ep:match("([%d%.]+)") or "unknown"
end

local function analyzeLoadingPattern(src)
    local stages = loadingStages[src]
    if not stages then return false, "no stages" end

    local connectTime = connectTimes[src]
    if not connectTime then return false, "no connect time" end

    local stageCount = 0
    for _ in pairs(stages) do stageCount = stageCount + 1 end

    if stageCount <= 1 and not stages.spawned then
        return true, "only connecting stage reached"
    end

    if stages.scripts_loaded and stages.spawned then
        local loadTime = stages.scripts_loaded - connectTime
        if loadTime < 2000 then
            return true, ("scripts loaded in %dms (too fast)"):format(loadTime)
        end
    end

    return false
end

AddEventHandler("playerDropped", function(reason)
    local src = source
    local cfg = Config.Modules.antiDump
    if not cfg or not cfg.enabled then
        connectTimes[src] = nil
        spawnedPlayers[src] = nil
        loadingStages[src] = nil
        challengeResponses[src] = nil
        return
    end

    local connectTime = connectTimes[src]
    local didSpawn = spawnedPlayers[src]
    local ip = getPlayerIP(src)

    connectTimes[src] = nil
    spawnedPlayers[src] = nil
    challengeResponses[src] = nil

    if not connectTime then
        loadingStages[src] = nil
        return
    end

    local sessionDuration = GetGameTimer() - connectTime

    local isDumpSuspect = false
    local suspectReason = ""

    if sessionDuration < DUMP_THRESHOLD_MS and not didSpawn then
        isDumpSuspect = true
        suspectReason = ("disconnected in %.1fs without spawning"):format(sessionDuration / 1000)
    end

    local loadingSuspect, loadReason = analyzeLoadingPattern(src)
    if loadingSuspect and sessionDuration < 30000 then
        isDumpSuspect = true
        suspectReason = suspectReason ~= "" and (suspectReason .. " + " .. loadReason) or loadReason
    end

    loadingStages[src] = nil

    if isDumpSuspect then
        local name = GetPlayerName(src) or "Unknown"
        local identifiers = {}
        for _, id in ipairs(GetPlayerIdentifiers(src) or {}) do
            identifiers[#identifiers + 1] = id
        end
        local idKey = identifiers[1] or ip

        suspiciousConnections[idKey] = (suspiciousConnections[idKey] or 0) + 1
        local attempts = suspiciousConnections[idKey]

        Log("WARN", ("[ANTI_DUMP] %s (IP:%s) — %s (attempt #%d)"):format(name, ip, suspectReason, attempts))

        for adminPid, _ in pairs(ACS.connectedPlayers) do
            if IsPlayerAceAllowed(tostring(adminPid), Config.Branding.AcePerm) then
                TriggerClientEvent(EncodeEvent("AC:detectionNotify"), adminPid, {
                    player = name,
                    reason = ("Possible dump: %s (attempt #%d, IP: %s)"):format(suspectReason, attempts, ip),
                    type = "WARN",
                })
            end
        end

        if SendEnhancedWebhook then
            SendEnhancedWebhook("WARN", name, src, "antiDump", suspectReason, {
                Attempts = tostring(attempts),
                IP = ip,
                Duration = ("%.1fs"):format(sessionDuration / 1000),
            })
        end

        if attempts >= MAX_SUSPICIOUS then
            for _, id in ipairs(identifiers) do
                if string.find(id, "license:") then
                    local banRecord = {
                        name = name,
                        identifiers = identifiers,
                        reason = ("[2F4R] Server dumping — %d rapid connections without gameplay"):format(attempts),
                        banId = GenerateBanId(),
                        date = os.date("%Y-%m-%d %H:%M"),
                    }
                    SetResourceKvp("ban:" .. banRecord.banId, json.encode(banRecord))
                    Log("WARN", ("[ANTI_DUMP] Auto-banned %s for %d dump-like connections"):format(name, attempts))
                    break
                end
            end
            suspiciousConnections[idKey] = 0
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(15000)
        if not ACS or not ACS.active then goto skip end

        for src, _ in pairs(ACS.connectedPlayers) do
            if not challengeResponses[src] and connectTimes[src] then
                local elapsed = GetGameTimer() - connectTimes[src]
                if elapsed > 10000 and elapsed < 60000 and not spawnedPlayers[src] then
                    sendChallenge(src)
                end
            end
        end

        ::skip::
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(600000)
        local cutoff = GetGameTimer() - 3600000
        for key, count in pairs(suspiciousConnections) do
            if count <= 0 then
                suspiciousConnections[key] = nil
            end
        end
    end
end)
