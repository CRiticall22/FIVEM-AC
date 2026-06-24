local polyKey = nil
local polyEpoch = 0
local polyInterval = 45000
local polyActive = false
local lastServerSync = 0
local HEARTBEAT_INTERVAL = 10000

local CHALLENGE_OPS = {
    function(c) return (c * 13 + 37) % 1000000 end,
    function(c) return (c * 7 + 91) % 1000000 end,
    function(c) return (c * 19 + 53) % 1000000 end,
    function(c) return (c * 11 + 67) % 1000000 end,
}

local function sendPolyEvent(action, extra)
    if not polyActive or not polyKey then return end

    local routerName = PolyEvent.getRouterName(polyEpoch)
    local data = {
        action = action,
        token = PolyEvent.computeToken(polyKey, polyEpoch, extra and extra.challenge or 0),
        epoch = polyEpoch,
    }

    if extra then
        for k, v in pairs(extra) do
            data[k] = v
        end
    end

    TriggerServerEvent(routerName, data)
end

RegisterNetEvent(EncodeEvent(PolyEvent.INIT_EVENT))
AddEventHandler(EncodeEvent(PolyEvent.INIT_EVENT), function(data)
    if not data or not data.key then return end

    polyKey = data.key
    polyEpoch = data.epoch or 0
    polyInterval = data.interval or 45000
    polyActive = true
    lastServerSync = GetGameTimer()
end)

RegisterNetEvent(EncodeEvent(PolyEvent.SYNC_EVENT))
AddEventHandler(EncodeEvent(PolyEvent.SYNC_EVENT), function(data)
    if not data or not polyActive then return end

    if data.type == "epoch" then
        polyEpoch = data.epoch
        lastServerSync = GetGameTimer()
    elseif data.type == "challenge" then
        if data.challenge and data.op and CHALLENGE_OPS[data.op] then
            local answer = CHALLENGE_OPS[data.op](data.challenge)
            Wait(math.random(100, 500))
            sendPolyEvent("challenge_response", {
                answer = answer,
                challenge = data.challenge,
            })
        end
    end
end)

AC.registerModule("polyEvents", {
    activate = function()
        AC.runPeriodically(HEARTBEAT_INTERVAL, function()
            if polyActive then
                sendPolyEvent("heartbeat")
            end
        end, "PolyHeartbeat")

        AC.runPeriodically(5000, function()
            if not polyActive then return end
            local now = GetGameTimer()
            if lastServerSync > 0 and (now - lastServerSync) > polyInterval * 2 then
                polyEpoch = polyEpoch + 1
                lastServerSync = now
            end
        end, "PolyEpochFallback")
    end,
    deactivate = function()
        polyActive = false
        polyKey = nil
        polyEpoch = 0
        lastServerSync = 0
    end,
})
