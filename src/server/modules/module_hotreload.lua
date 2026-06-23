RegisterNetEvent(EncodeEvent("AC:toggleModule"), function(data)
    local src = source
    if not IsPlayerAceAllowed(tostring(src), Config.Whitelist.AcePerm) then return end
    if not data or not data.module then return end

    local moduleName = data.module
    local enabled = data.enabled

    if Config.Modules[moduleName] then
        Config.Modules[moduleName].enabled = enabled
        local state = enabled and "ENABLED" or "DISABLED"
        Log("INFO", ("[HOT_RELOAD] %s %s module '%s'"):format(GetPlayerName(src) or "Admin", state, moduleName))

        for pid, _ in pairs(ACS.connectedPlayers) do
            TriggerClientEvent(EncodeEvent("AC:setConfig"), pid, ACS.getClientConfig())
        end

        TriggerClientEvent(EncodeEvent("AC:detectionNotify"), src, {
            player = "SYSTEM",
            reason = ("Module '%s' %s"):format(moduleName, state),
            type = "WARN",
        })
    end
end)

RegisterNetEvent(EncodeEvent("AC:getModuleStates"), function()
    local src = source
    if not IsPlayerAceAllowed(tostring(src), Config.Whitelist.AcePerm) then return end

    local states = {}
    for name, cfg in pairs(Config.Modules) do
        if type(cfg) == "table" then
            states[name] = cfg.enabled or false
        end
    end

    TriggerClientEvent(EncodeEvent("AC:moduleStates"), src, states)
end)
