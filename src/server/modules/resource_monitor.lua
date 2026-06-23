local resourceName = GetCurrentResourceName()

AddEventHandler("onResourceStop", function(res)
    if res == resourceName then return end

    if not EACS.active then return end
    if not Config.Modules.antiResourceStop or not Config.Modules.antiResourceStop.enabled then return end

    local blacklisted = Config.Modules.antiResourceStop.blacklist or {}
    for _, bl in ipairs(blacklisted) do
        if res == bl then
            Log("WARN", ("Protected resource '%s' was stopped"):format(res))
            Citizen.CreateThread(function()
                Wait(500)
                if GetResourceState(res) == "stopped" then
                    StartResource(res)
                    Log("INFO", ("Auto-restarted protected resource '%s'"):format(res))
                end
            end)
            return
        end
    end
end)

Citizen.CreateThread(function()
    Wait(10000)
    while true do
        Wait(60000)
        if not EACS.active then goto continue end
        if not Config.Modules.antiResourceStop or not Config.Modules.antiResourceStop.enabled then goto continue end

        for _, res in ipairs(Config.Modules.antiResourceStop.blacklist or {}) do
            if GetResourceState(res) == "stopped" then
                Log("WARN", ("Protected resource '%s' found stopped, restarting"):format(res))
                StartResource(res)
            end
        end

        ::continue::
    end
end)
