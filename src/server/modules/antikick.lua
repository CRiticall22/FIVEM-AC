local kickAttempts = {}

AddEventHandler("playerEnteredScope", function() end)

RegisterNetEvent("clientCommand", function(cmd)
    local src = source
    if not ACS or not ACS.active then return end

    local cfg = Config.Modules.antiKick
    if not cfg or not cfg.enabled then return end

    local lower = string.lower(cmd or "")
    local patterns = { "kick", "clientkick", "dropplayer", "forceplayerdrop" }

    for _, pattern in ipairs(patterns) do
        if string.find(lower, pattern, 1, true) then
            if not IsPlayerAceAllowed(tostring(src), Config.Branding.AcePerm) then
                local name = GetPlayerName(src) or "Unknown"
                kickAttempts[src] = (kickAttempts[src] or 0) + 1

                Log("WARN", ("[ANTIKICK] %s (ID:%d) attempted unauthorized kick command: %s"):format(name, src, cmd))

                if AddThreatScore then AddThreatScore(src, "kickAttempt", 40) end

                if kickAttempts[src] >= 2 then
                    PunishPlayer(src, "antiKick", "Unauthorized kick attempts: " .. cmd)
                    kickAttempts[src] = 0
                end

                CancelEvent()
                return
            end
        end
    end
end)

RegisterNetEvent("__cfx_internal:commandFallback", function(cmd)
    local src = source
    if not ACS or not ACS.active then return end

    local cfg = Config.Modules.antiKick
    if not cfg or not cfg.enabled then return end

    local lower = string.lower(cmd or "")
    if string.find(lower, "kick", 1, true) or string.find(lower, "drop", 1, true) then
        if not IsPlayerAceAllowed(tostring(src), Config.Branding.AcePerm) then
            CancelEvent()
            if AddThreatScore then AddThreatScore(src, "kickAttempt", 30) end
        end
    end
end)

AddEventHandler("playerDropped", function()
    kickAttempts[source] = nil
end)
