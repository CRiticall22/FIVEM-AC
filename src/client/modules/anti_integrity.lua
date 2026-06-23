local integrityChecked = false

Citizen.CreateThread(function()
    Wait(20000)
    AC.waitForConfig()
    if not Config.Modules.antiIntegrity or not Config.Modules.antiIntegrity.enabled then return end
    if integrityChecked then return end
    integrityChecked = true

    local resName = GetCurrentResourceName()
    local checks = {
        { file = "src/client/main.lua",          key = "AC" },
        { file = "src/client/heartbeat.lua",     key = "heartbeatChallenge" },
        { file = "src/client/nui_bridge.lua",    key = "menuReady" },
        { file = "src/shared/utils.lua",         key = "EncodeEvent" },
    }

    for _, check in ipairs(checks) do
        local content = LoadResourceFile(resName, check.file)
        if not content then
            AC.punish(DetectionType.INJECTOR, "Missing anticheat file: " .. check.file)
            return
        end
        if not string.find(content, check.key, 1, true) then
            AC.punish(DetectionType.INJECTOR, "Modified anticheat file: " .. check.file)
            return
        end
    end

    local manifest = LoadResourceFile(resName, "fxmanifest.lua")
    if not manifest or not string.find(manifest, "2F4R", 1, true) then
        AC.punish(DetectionType.INJECTOR, "Modified fxmanifest.lua")
    end
end)

AC.runPeriodically(120000, function()
    if not Config.Modules.antiIntegrity or not Config.Modules.antiIntegrity.enabled then return end

    local resName = GetCurrentResourceName()
    local content = LoadResourceFile(resName, "config.lua")
    if not content or not string.find(content, "Config.Modules", 1, true) then
        AC.punish(DetectionType.INJECTOR, "Config file tampered or missing")
    end
end, "IntegrityLoop")
