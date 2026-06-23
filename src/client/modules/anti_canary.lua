local canaries = {}
local CANARY_CHECK = 2000
local canaryTriggered = false

local function makeCanary(name, value)
    rawset(_G, name, value)
    canaries[name] = value
end

Citizen.CreateThread(function()
    Wait(10000)
    AC.waitForConfig()
    if not Config.Modules.antiCanary or not Config.Modules.antiCanary.enabled then return end

    makeCanary("_money",      0)
    makeCanary("_godmode",    false)
    makeCanary("_admin",      false)
    makeCanary("_noclip",     false)
    makeCanary("_speed",      1.0)
    makeCanary("_teleport",   false)
    makeCanary("_invisible",  false)
    makeCanary("_weapons",    false)
    makeCanary("_esp",        false)
    makeCanary("_aimbot",     false)
    makeCanary("_executor",   false)
    makeCanary("_bypass",     false)
    makeCanary("_unban",      nil)
    makeCanary("_whitelist",  nil)
    makeCanary("GiveWeapon",  nil)
    makeCanary("SetGodmode",  nil)
    makeCanary("TriggerCheat",nil)
end)

AC.runPeriodically(CANARY_CHECK, function()
    if not Config.Modules.antiCanary or not Config.Modules.antiCanary.enabled then return end
    if canaryTriggered then return end

    for name, original in pairs(canaries) do
        local current = rawget(_G, name)
        if current ~= original then
            canaryTriggered = true
            rawset(_G, name, original)
            AC.punish(DetectionType.INJECTOR, "Canary variable tampered: " .. name)
            return
        end
    end
end, "AntiCanary")
