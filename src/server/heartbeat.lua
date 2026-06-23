local playerHeartbeats = {}
local playerTimeouts = {}
local HEARTBEAT_TIMEOUT = 45000
local PING_INTERVAL = 30000
local MAX_MISSED = 3

local heartbeatTokens = {}

local function generateToken()
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local token = ""
    for _ = 1, 16 do
        local idx = math.random(1, #chars)
        token = token .. chars:sub(idx, idx)
    end
    return token
end

AddEventHandler(EncodeEvent("AC:heartbeat"), function(data)
    local src = source
    if not data then return end

    if heartbeatTokens[src] and data.token ~= heartbeatTokens[src] then
        PunishPlayer(src, DetectionType.INJECTOR, "Invalid heartbeat token")
        return
    end

    playerHeartbeats[src] = {
        time   = os.time(),
        coords = data.coords,
        health = data.health,
        armor  = data.armor,
        weapon = data.weapon,
    }

    playerTimeouts[src] = 0

    local newToken = generateToken()
    heartbeatTokens[src] = newToken
    TriggerClientEvent(EncodeEvent("AC:heartbeatChallenge"), src, newToken)
end)

local pingResponses = {}

AddEventHandler(EncodeEvent("AC:pong"), function()
    pingResponses[source] = true
end)

Citizen.CreateThread(function()
    while true do
        Wait(PING_INTERVAL)
        if not EACS.active then goto continue end

        pingResponses = {}
        TriggerClientEvent(EncodeEvent("AC:ping"), -1)
        Wait(10000)

        for pid, _ in pairs(EACS.connectedPlayers) do
            if not pingResponses[pid] then
                playerTimeouts[pid] = (playerTimeouts[pid] or 0) + 1
                if playerTimeouts[pid] >= MAX_MISSED then
                    DropPlayer(pid, "Connection timeout")
                    EACS.connectedPlayers[pid] = nil
                end
            else
                playerTimeouts[pid] = math.max((playerTimeouts[pid] or 0) - 1, 0)
            end
        end

        ::continue::
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(HEARTBEAT_TIMEOUT)
        if not EACS.active then goto continue end

        local now = os.time()
        for pid, _ in pairs(EACS.connectedPlayers) do
            local hb = playerHeartbeats[pid]
            if hb and (now - hb.time) > (HEARTBEAT_TIMEOUT / 1000) * 2 then
                Log("WARN", ("Player %s heartbeat stale (%ds ago)"):format(
                    GetPlayerName(pid) or pid, now - hb.time))
            end
        end

        ::continue::
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    playerHeartbeats[src] = nil
    playerTimeouts[src] = nil
    heartbeatTokens[src] = nil
    pingResponses[src] = nil
    EACS.connectedPlayers[src] = nil
end)
