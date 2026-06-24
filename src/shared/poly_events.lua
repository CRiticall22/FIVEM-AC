PolyEvent = {}

PolyEvent.ROUTER_BASE = "AC:polyRouter"
PolyEvent.INIT_EVENT = "AC:polyInit"
PolyEvent.SYNC_EVENT = "AC:polySync"

function PolyEvent.hash(str)
    local h = 5381
    for i = 1, #str do
        h = ((h * 33) + string.byte(str, i)) % 4294967291
    end
    return h
end

function PolyEvent.computeSuffix(key, epoch)
    local combined = key .. "::" .. tostring(epoch) .. "::rotate"
    local seed = PolyEvent.hash(combined)
    local chars = ""
    for _ = 1, 8 do
        seed = (seed * 1103515245 + 12345) % 2147483648
        chars = chars .. string.char(97 + (seed % 26))
    end
    return chars
end

function PolyEvent.computeToken(key, epoch, challenge)
    local raw = key .. "|" .. tostring(epoch) .. "|" .. tostring(challenge or 0) .. "|poly_tkn"
    return PolyEvent.hash(raw)
end

function PolyEvent.getRouterName(epoch)
    local baseName = EncodeEvent(PolyEvent.ROUTER_BASE)
    local suffix = PolyEvent.computeSuffix(baseName, epoch)
    return baseName:sub(1, 56) .. suffix
end

function PolyEvent.generateKey()
    math.randomseed((os.time and os.time() or 0) + GetGameTimer())
    local pool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local key = ""
    for _ = 1, 32 do
        local idx = math.random(1, #pool)
        key = key .. pool:sub(idx, idx)
    end
    return key
end
