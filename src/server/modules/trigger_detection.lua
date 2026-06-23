local playerEventLog = {}
local playerEventRate = {}
local RATE_WINDOW = 5000
local MAX_UNIQUE_EVENTS = 25
local MAX_EVENT_RATE = 60

local TRAP_EVENTS = {
    "esx:getSharedObject",
    "esx:getPlayerData",
    "esx_society:getEmployees",
    "esx_billing:sendBill",
    "esx_policejob:handcuff",
    "qb-core:server:GetObject",
    "qb-phone:server:GetContacts",
    "qb-inventory:server:SetInventoryData",
    "vrp:getUser",
    "bank:withdraw",
    "garage:spawnVehicle",
    "shops:buyItem",
    "admin:giveWeapon",
    "admin:giveMoney",
    "admin:setJob",
    "job:startWork",
    "farming:harvest",
    "crafting:craft",
}

for _, evName in ipairs(TRAP_EVENTS) do
    RegisterNetEvent(evName, function()
        local src = source
        if not ACS or not ACS.active then return end

        local cfg = Config.Modules.triggerDetection
        if not cfg or not cfg.enabled then return end

        local name = GetPlayerName(src) or "Unknown"

        if IsPlayerAceAllowed(tostring(src), Config.Branding.AcePerm) then return end

        Log("WARN", ("[TRIGGER_FINDER] %s (ID:%d) triggered trap event: %s"):format(name, src, evName))

        if AddThreatScore then AddThreatScore(src, "triggerFinder", 50) end

        PunishPlayer(src, "triggerDetection", ("Trigger finder detected: called trap event '%s'"):format(evName))
    end)
end

local realEventCounts = {}
local eventTimestamps = {}

AddEventHandler("__cfx_internal:serverPrint", function() end)

local _origTrigger = RegisterNetEvent
local trackedEvents = {}

Citizen.CreateThread(function()
    while true do
        Wait(RATE_WINDOW)
        if not ACS or not ACS.active then goto skip end

        local cfg = Config.Modules.triggerDetection
        if not cfg or not cfg.enabled then goto skip end

        for src, events in pairs(playerEventRate) do
            local name = GetPlayerName(src)
            if not name then
                playerEventRate[src] = nil
                goto nextPlayer
            end

            if IsPlayerAceAllowed(tostring(src), Config.Branding.AcePerm) then goto nextPlayer end

            local totalRate = 0
            local uniqueCount = 0
            for evName, count in pairs(events) do
                totalRate = totalRate + count
                uniqueCount = uniqueCount + 1
            end

            if totalRate > MAX_EVENT_RATE then
                Log("WARN", ("[TRIGGER_SCAN] %s (ID:%d) fired %d events in %ds window (%d unique)"):format(name, src, totalRate, RATE_WINDOW / 1000, uniqueCount))

                if AddThreatScore then AddThreatScore(src, "eventFlood", 30) end

                if totalRate > MAX_EVENT_RATE * 3 then
                    PunishPlayer(src, "triggerDetection", ("Event flood: %d events in %ds"):format(totalRate, RATE_WINDOW / 1000))
                end
            end

            if uniqueCount > MAX_UNIQUE_EVENTS then
                Log("WARN", ("[TRIGGER_SCAN] %s (ID:%d) triggered %d unique events (scanning?)"):format(name, src, uniqueCount))
                if AddThreatScore then AddThreatScore(src, "triggerScan", 40) end
            end

            ::nextPlayer::
        end

        playerEventRate = {}
        ::skip::
    end
end)

local function trackEvent(src, eventName)
    if not playerEventRate[src] then playerEventRate[src] = {} end
    playerEventRate[src][eventName] = (playerEventRate[src][eventName] or 0) + 1
end

AddEventHandler("onServerResourceStart", function(res)
    if res ~= GetCurrentResourceName() then return end

    AddEventHandler("__cfx_internal:serverGameEvent", function(name, data)
        local src = source
        if src and src > 0 then
            trackEvent(src, name or "unknown_game_event")
        end
    end)
end)

AddEventHandler("playerDropped", function()
    local src = source
    playerEventRate[src] = nil
    playerEventLog[src] = nil
end)
