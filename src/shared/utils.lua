local resourceName = GetCurrentResourceName()
local eventCache = {}

function EncodeEvent(eventName)
    if eventCache[eventName] then
        return eventCache[eventName]
    end

    local combined = eventName .. resourceName
    local seed = 0
    for i = 1, #combined do
        local b = string.byte(combined, i)
        seed = seed + b * i + b
    end

    math.randomseed(seed)
    local encoded = ''
    for _ = 1, 64 do
        encoded = encoded .. string.char(math.random(97, 122))
    end

    eventCache[eventName] = encoded
    return encoded
end

function Log(level, ...)
    if not Config.Debug and level == "DEBUG" then return end
    local prefix = ({
        DEBUG = "^2[DEBUG]^0",
        INFO  = "^4[INFO]^0",
        WARN  = "^3[WARN]^0",
        ERROR = "^1[ERROR]^0",
    })[level] or "^0[LOG]^0"
    print(("[%s] %s"):format(Config.Branding.Name, prefix), ...)
end

function GenerateBanId()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for _ = 1, 8 do
        local idx = math.random(1, #chars)
        id = id .. chars:sub(idx, idx)
    end
    return "AC-" .. id
end
