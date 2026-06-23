local playerEventRate = {}
local playerEventLog = {}
local playerEventSequence = {}
local eventCooldowns = {}
local RATE_WINDOW = 5000
local MAX_UNIQUE_EVENTS = 20
local MAX_EVENT_RATE = 50

local TRAP_EVENTS = {
    "esx:getSharedObject", "esx:getPlayerData", "esx:setPlayerData",
    "esx_society:getEmployees", "esx_billing:sendBill", "esx_policejob:handcuff",
    "esx_ambulancejob:revive", "esx_drugs:pick", "esx_shops:buy",
    "esx_vehicleshop:buy", "esx_banking:withdraw", "esx_banking:deposit",
    "esx_identity:setIdentity", "esx_status:set",
    "qb-core:server:GetObject", "qb-core:server:SetMetaData",
    "qb-phone:server:GetContacts", "qb-phone:server:SendMail",
    "qb-inventory:server:SetInventoryData", "qb-inventory:server:SaveStashItems",
    "qb-clothing:server:SaveOutfit", "qb-houses:server:buyHouse",
    "qb-banking:server:withdraw", "qb-banking:server:deposit",
    "vrp:getUser", "vrp:getUserId", "vrp:setUData",
    "bank:withdraw", "bank:deposit", "bank:transfer",
    "garage:spawnVehicle", "garage:storeVehicle",
    "shops:buyItem", "shops:sellItem",
    "admin:giveWeapon", "admin:giveMoney", "admin:setJob",
    "admin:teleport", "admin:noclip", "admin:godmode",
    "admin:setGroup", "admin:setPermission",
    "job:startWork", "farming:harvest", "crafting:craft",
    "inventory:addItem", "inventory:removeItem",
    "weapon:giveWeapon", "weapon:removeWeapon",
    "money:giveCash", "money:giveDirty",
    "vehicle:spawnVehicle", "vehicle:modifyVehicle",
    "player:setHealth", "player:setArmor", "player:revive",
}

local trapSet = {}
for _, ev in ipairs(TRAP_EVENTS) do
    trapSet[ev] = true
    RegisterNetEvent(ev, function()
        local src = source
        if not ACS or not ACS.active then return end
        local cfg = Config.Modules.triggerDetection
        if not cfg or not cfg.enabled then return end
        if IsPlayerAceAllowed(tostring(src), Config.Whitelist.AcePerm) then return end

        local name = GetPlayerName(src) or "Unknown"
        Log("WARN", ("[TRIGGER_TRAP] %s (ID:%d) hit trap: %s"):format(name, src, ev))
        if AddThreatScore then AddThreatScore(src, "triggerTrap", 50) end
        PunishPlayer(src, "triggerDetection", ("Trap event triggered: '%s'"):format(ev))
    end)
end

local SENSITIVE_EVENTS = {
    ["give"]     = { cooldown = 5000, maxPerMinute = 5 },
    ["money"]    = { cooldown = 3000, maxPerMinute = 10 },
    ["weapon"]   = { cooldown = 3000, maxPerMinute = 5 },
    ["spawn"]    = { cooldown = 2000, maxPerMinute = 8 },
    ["teleport"] = { cooldown = 2000, maxPerMinute = 10 },
    ["item"]     = { cooldown = 1000, maxPerMinute = 30 },
    ["admin"]    = { cooldown = 5000, maxPerMinute = 3 },
    ["bank"]     = { cooldown = 3000, maxPerMinute = 5 },
    ["set"]      = { cooldown = 2000, maxPerMinute = 15 },
}

local function matchesSensitivePattern(eventName)
    local lower = string.lower(eventName)
    for pattern, rules in pairs(SENSITIVE_EVENTS) do
        if string.find(lower, pattern, 1, true) then
            return pattern, rules
        end
    end
    return nil
end

local playerSensitiveCounts = {}
local playerLastSensitive = {}

local function checkSensitiveEvent(src, eventName)
    local pattern, rules = matchesSensitivePattern(eventName)
    if not pattern then return false end

    local now = GetGameTimer()
    local key = src .. ":" .. pattern

    if playerLastSensitive[key] and (now - playerLastSensitive[key]) < rules.cooldown then
        if not playerSensitiveCounts[key] then playerSensitiveCounts[key] = { count = 0, start = now } end
        playerSensitiveCounts[key].count = playerSensitiveCounts[key].count + 1

        if playerSensitiveCounts[key].count > rules.maxPerMinute then
            return true, pattern, playerSensitiveCounts[key].count
        end
    end

    playerLastSensitive[key] = now

    if not playerSensitiveCounts[key] then
        playerSensitiveCounts[key] = { count = 1, start = now }
    elseif (now - playerSensitiveCounts[key].start) > 60000 then
        playerSensitiveCounts[key] = { count = 1, start = now }
    else
        playerSensitiveCounts[key].count = playerSensitiveCounts[key].count + 1
    end

    return false
end

local function trackEvent(src, eventName)
    if not playerEventRate[src] then playerEventRate[src] = {} end
    playerEventRate[src][eventName] = (playerEventRate[src][eventName] or 0) + 1

    if not playerEventSequence[src] then playerEventSequence[src] = {} end
    local seq = playerEventSequence[src]
    seq[#seq + 1] = { event = eventName, time = GetGameTimer() }
    if #seq > 100 then table.remove(seq, 1) end
end

local function analyzeSequence(src)
    local seq = playerEventSequence[src]
    if not seq or #seq < 10 then return end

    local seen = {}
    local burstStart = nil
    local burstCount = 0

    for i = 2, #seq do
        local dt = seq[i].time - seq[i - 1].time
        if dt < 50 then
            burstCount = burstCount + 1
            if not burstStart then burstStart = i - 1 end
        else
            if burstCount >= 8 then
                return true, burstCount, "rapid-fire burst"
            end
            burstCount = 0
            burstStart = nil
        end

        seen[seq[i].event] = true
    end

    if burstCount >= 8 then
        return true, burstCount, "rapid-fire burst"
    end

    local uniqueInWindow = 0
    local windowStart = seq[#seq].time - 3000
    local windowEvents = {}
    for _, entry in ipairs(seq) do
        if entry.time >= windowStart then
            if not windowEvents[entry.event] then
                uniqueInWindow = uniqueInWindow + 1
                windowEvents[entry.event] = true
            end
        end
    end

    if uniqueInWindow > 15 then
        return true, uniqueInWindow, "event scanning (many unique events in 3s)"
    end

    return false
end

Citizen.CreateThread(function()
    while true do
        Wait(RATE_WINDOW)
        if not ACS or not ACS.active then goto skip end
        local cfg = Config.Modules.triggerDetection
        if not cfg or not cfg.enabled then goto skip end

        for src, events in pairs(playerEventRate) do
            local name = GetPlayerName(src)
            if not name then playerEventRate[src] = nil; goto nextPlayer end
            if IsPlayerAceAllowed(tostring(src), Config.Whitelist.AcePerm) then goto nextPlayer end

            local totalRate = 0
            local uniqueCount = 0
            for _, count in pairs(events) do
                totalRate = totalRate + count
                uniqueCount = uniqueCount + 1
            end

            if totalRate > MAX_EVENT_RATE then
                if AddThreatScore then AddThreatScore(src, "eventFlood", 30) end
                if totalRate > MAX_EVENT_RATE * 3 then
                    PunishPlayer(src, "triggerDetection", ("Event flood: %d events in %ds"):format(totalRate, RATE_WINDOW / 1000))
                end
            end

            if uniqueCount > MAX_UNIQUE_EVENTS then
                if AddThreatScore then AddThreatScore(src, "triggerScan", 40) end
                if uniqueCount > MAX_UNIQUE_EVENTS * 2 then
                    PunishPlayer(src, "triggerDetection", ("Event scanning: %d unique events in %ds"):format(uniqueCount, RATE_WINDOW / 1000))
                end
            end

            local isSuspicious, detail, reason = analyzeSequence(src)
            if isSuspicious then
                Log("WARN", ("[TRIGGER_SEQ] %s (ID:%d) — %s (%s)"):format(name, src, reason, tostring(detail)))
                if AddThreatScore then AddThreatScore(src, "triggerSequence", 45) end
            end

            ::nextPlayer::
        end

        playerEventRate = {}
        ::skip::
    end
end)

RegisterNetEvent(EncodeEvent("AC:clientTriggerReport"), function(eventName, argCount)
    local src = source
    if not ACS or not ACS.active then return end
    local cfg = Config.Modules.triggerDetection
    if not cfg or not cfg.enabled then return end
    if IsPlayerAceAllowed(tostring(src), Config.Whitelist.AcePerm) then return end

    trackEvent(src, eventName)

    local exceeded, pattern, count = checkSensitiveEvent(src, eventName)
    if exceeded then
        local name = GetPlayerName(src) or "Unknown"
        Log("WARN", ("[SENSITIVE_EVENT] %s (ID:%d) exceeded '%s' rate limit: %d calls"):format(name, src, pattern, count))
        if AddThreatScore then AddThreatScore(src, "sensitiveAbuse", 35) end

        if count > 20 then
            PunishPlayer(src, "triggerDetection", ("Sensitive event abuse: '%s' pattern called %d times"):format(pattern, count))
        end
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    playerEventRate[src] = nil
    playerEventLog[src] = nil
    playerEventSequence[src] = nil
    playerSensitiveCounts = {}
    for k in pairs(playerLastSensitive) do
        if string.find(k, "^" .. tostring(src) .. ":") then
            playerLastSensitive[k] = nil
        end
    end
end)
