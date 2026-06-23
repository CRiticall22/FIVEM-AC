local particleTracker = {}
local eventRateLimits = {}

AddEventHandler("ptFxEvent", function(src)
    if not EACS.active then return end
    if not Config.Modules.antiParticles.enabled then return end
    if not particleTracker[src] then
        particleTracker[src] = { count = 0, time = os.time() }
    end
    if os.time() - particleTracker[src].time >= 10 then
        particleTracker[src] = { count = 0, time = os.time() }
    end
    particleTracker[src].count = particleTracker[src].count + 1
    particleTracker[src].time  = os.time()
    if particleTracker[src].count >= Config.Modules.antiParticles.max then
        CancelEvent()
        PunishPlayer(src, DetectionType.PARTICLES, "Particle spam " .. particleTracker[src].count .. "x")
    end
end)

AddEventHandler("giveWeaponEvent", function(src)
    if not EACS.active then return end
    if Config.Modules.antiAddWeapon.enabled then
        CancelEvent()
        PunishPlayer(src, DetectionType.ADD_WEAPON, "Tried to add weapon to player")
    end
end)

AddEventHandler("RemoveWeaponEvent", function(src)
    if not EACS.active then return end
    if Config.Modules.antiRemoveWeapon.enabled then
        if tonumber(src) and GetPlayerName(src) then
            CancelEvent()
            PunishPlayer(src, DetectionType.REMOVE_WEAPON, "Tried to remove weapon from player")
        end
    end
end)

AddEventHandler("RemoveAllWeaponsEvent", function(src)
    if not EACS.active then return end
    if Config.Modules.antiRemoveWeapon.enabled then
        CancelEvent()
        PunishPlayer(src, DetectionType.REMOVE_WEAPON, "Tried to remove all weapons from player")
    end
end)

Citizen.CreateThread(function()
    if not Config.Modules.antiTrigger.enabled then return end
    for _, eventName in ipairs(Config.Modules.antiTrigger.blacklist or {}) do
        RegisterNetEvent(eventName)
        EACS.addHandler(AddEventHandler(eventName, function()
            CancelEvent()
            PunishPlayer(source, DetectionType.TRIGGER, "Blacklisted trigger: " .. eventName)
        end))
    end
end)

if GetResourceState("interact-sound") == "started" then
    AddEventHandler("InteractSound_SV:PlayWithinDistance", function(dist, file, vol)
        local src = source
        if not EACS.active then return end
        if not Config.Modules.antiPlaySound.enabled then return end
        local suspicious = {
            { 10000,  "handcuff" },
            { 1000,   "Cuff" },
            { 103232, "lock" },
            { 10,     "szajbusek" },
            { 5,      "alarm" },
            { 13232,  "pasysound" },
            { 5000,   "demo" },
        }
        for _, s in ipairs(suspicious) do
            if dist == s[1] and file == s[2] then
                CancelEvent()
                PunishPlayer(src, DetectionType.PLAY_SOUND, "Sound exploit: " .. file .. " @ " .. dist)
                return
            end
        end
    end)
end

AddEventHandler("playerDropped", function()
    local src = source
    particleTracker[src] = nil
    eventRateLimits[src] = nil
end)
