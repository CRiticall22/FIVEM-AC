local polyPlayers = {}
local currentEpoch = 0
local registeredRouters = {}
local ROTATION_INTERVAL = 45000
local VALIDATION_INTERVAL = 15000
local TOKEN_FAIL_THRESHOLD = 3
local RESPONSE_TIMEOUT = 10000

local CHALLENGE_OPS = {
    function(c) return (c * 13 + 37) % 1000000 end,
    function(c) return (c * 7 + 91) % 1000000 end,
    function(c) return (c * 19 + 53) % 1000000 end,
    function(c) return (c * 11 + 67) % 1000000 end,
}

local function isPolyEnabled()
    local cfg = Config.Modules.polyEvents
    return cfg and cfg.enabled and ACS and ACS.active
end

local function registerRouterEpoch(epoch)
    if registeredRouters[epoch] then return end

    local routerName = PolyEvent.getRouterName(epoch)
    RegisterNetEvent(routerName)
    local handler = AddEventHandler(routerName, function(data)
        local src = source
        if not isPolyEnabled() then return end

        local player = polyPlayers[src]
        if not player then return end

        if type(data) ~= "table" then
            if AddThreatScore then AddThreatScore(src, "polyMalformed", 30) end
            return
        end

        local expectedToken = PolyEvent.computeToken(player.key, data.epoch or 0, data.challenge or 0)
        if data.token ~= expectedToken then
            local graceValid = false
            for offset = -1, 1 do
                if offset ~= 0 then
                    local alt = PolyEvent.computeToken(player.key, (data.epoch or 0) + offset, data.challenge or 0)
                    if data.token == alt then
                        graceValid = true
                        break
                    end
                end
            end

            if not graceValid then
                player.tokenFails = (player.tokenFails or 0) + 1
                Log("WARN", ("[POLY] %s (ID:%d) invalid token (fail #%d)"):format(
                    GetPlayerName(src) or "?", src, player.tokenFails))

                if player.tokenFails >= TOKEN_FAIL_THRESHOLD then
                    if AddThreatScore then AddThreatScore(src, "polyTokenFail", 50) end
                    PunishPlayer(src, "polyEvents", "Repeated poly-token failures: event integrity compromised")
                end
                return
            end
        end

        player.tokenFails = 0
        player.lastValidResponse = GetGameTimer()

        if data.action == "heartbeat" then
            player.polyHeartbeats = (player.polyHeartbeats or 0) + 1
        elseif data.action == "challenge_response" then
            if player.pendingChallenge and data.answer == player.pendingChallenge.expected then
                player.pendingChallenge = nil
                player.challengesPassed = (player.challengesPassed or 0) + 1
            else
                player.tokenFails = (player.tokenFails or 0) + 1
                Log("WARN", ("[POLY] %s (ID:%d) failed challenge"):format(
                    GetPlayerName(src) or "?", src))
            end
        end
    end)

    registeredRouters[epoch] = { handler = handler, name = routerName }
end

local function unregisterRouterEpoch(epoch)
    if registeredRouters[epoch] then
        RemoveEventHandler(registeredRouters[epoch].handler)
        registeredRouters[epoch] = nil
    end
end

local function sendChallenge(src)
    local player = polyPlayers[src]
    if not player or not player.key then return end

    local challenge = math.random(100000, 999999)
    local op = math.random(1, #CHALLENGE_OPS)
    local expected = CHALLENGE_OPS[op](challenge)

    player.pendingChallenge = {
        challenge = challenge,
        op = op,
        expected = expected,
        sent = GetGameTimer(),
    }

    TriggerClientEvent(EncodeEvent(PolyEvent.SYNC_EVENT), src, {
        type = "challenge",
        challenge = challenge,
        op = op,
        epoch = currentEpoch,
    })

    Citizen.SetTimeout(RESPONSE_TIMEOUT, function()
        local p = polyPlayers[src]
        if p and p.pendingChallenge and p.pendingChallenge.challenge == challenge then
            if GetPlayerName(src) then
                Log("WARN", ("[POLY] %s (ID:%d) did not respond to poly challenge"):format(
                    GetPlayerName(src) or "?", src))
                if AddThreatScore then AddThreatScore(src, "polyChallengeTimeout", 20) end
            end
            p.pendingChallenge = nil
        end
    end)
end

local function initPlayer(src)
    if not isPolyEnabled() then return end

    local key = PolyEvent.generateKey()
    polyPlayers[src] = {
        key = key,
        epoch = currentEpoch,
        tokenFails = 0,
        polyHeartbeats = 0,
        challengesPassed = 0,
        lastValidResponse = GetGameTimer(),
        initTime = GetGameTimer(),
    }

    TriggerClientEvent(EncodeEvent(PolyEvent.INIT_EVENT), src, {
        key = key,
        epoch = currentEpoch,
        interval = ROTATION_INTERVAL,
    })

    Log("DEBUG", ("[POLY] Initialized for %s (ID:%d), epoch=%d"):format(
        GetPlayerName(src) or "?", src, currentEpoch))
end

Citizen.CreateThread(function()
    while true do
        Wait(ROTATION_INTERVAL)
        if not isPolyEnabled() then goto skip end

        currentEpoch = currentEpoch + 1
        registerRouterEpoch(currentEpoch)

        if currentEpoch > 2 then
            unregisterRouterEpoch(currentEpoch - 2)
        end

        local syncName = EncodeEvent(PolyEvent.SYNC_EVENT)
        for src, player in pairs(polyPlayers) do
            if GetPlayerName(src) then
                player.epoch = currentEpoch
                TriggerClientEvent(syncName, src, {
                    type = "epoch",
                    epoch = currentEpoch,
                })
            else
                polyPlayers[src] = nil
            end
        end

        Log("DEBUG", ("[POLY] Epoch rotated to %d, %d players tracked"):format(
            currentEpoch, (function()
                local n = 0; for _ in pairs(polyPlayers) do n = n + 1 end; return n
            end)()))

        ::skip::
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(VALIDATION_INTERVAL)
        if not isPolyEnabled() then goto skip end

        local now = GetGameTimer()
        for src, player in pairs(polyPlayers) do
            if not GetPlayerName(src) then
                polyPlayers[src] = nil
                goto nextPlayer
            end

            if IsPlayerWhitelisted and IsPlayerWhitelisted(src) then
                goto nextPlayer
            end

            local age = now - player.initTime
            local silence = now - (player.lastValidResponse or player.initTime)

            if age > 60000 and player.polyHeartbeats == 0 then
                Log("WARN", ("[POLY] %s (ID:%d) no poly heartbeat after 60s"):format(
                    GetPlayerName(src) or "?", src))
                if AddThreatScore then AddThreatScore(src, "polyNoHeartbeat", 25) end
            end

            if silence > 90000 and age > 90000 then
                Log("WARN", ("[POLY] %s (ID:%d) no valid poly response in 90s"):format(
                    GetPlayerName(src) or "?", src))
                if AddThreatScore then AddThreatScore(src, "polyUnresponsive", 15) end
            end

            if not player.pendingChallenge and age > 30000 then
                if math.random(1, 3) == 1 then
                    sendChallenge(src)
                end
            end

            ::nextPlayer::
        end

        ::skip::
    end
end)

AddEventHandler(EncodeEvent("AC:requestInit"), function()
    local src = source
    Citizen.SetTimeout(3000, function()
        if GetPlayerName(src) then
            initPlayer(src)
        end
    end)
end)

Citizen.CreateThread(function()
    Wait(1000)
    registerRouterEpoch(currentEpoch)
end)

AddEventHandler("playerDropped", function()
    polyPlayers[source] = nil
end)
