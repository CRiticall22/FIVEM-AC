local MIN_STEAM_AGE_DAYS = 30
local MIN_DISCORD_AGE_DAYS = 14

local function getIdentifier(src, prefix)
    for _, id in ipairs(GetPlayerIdentifiers(src) or {}) do
        if string.find(id, prefix .. ":") then
            return id
        end
    end
    return nil
end

local function getSteamHex(src)
    return getIdentifier(src, "steam")
end

local function getDiscordId(src)
    local id = getIdentifier(src, "discord")
    if id then return id:gsub("discord:", "") end
    return nil
end

local function discordIdToTimestamp(id)
    local num = tonumber(id)
    if not num then return nil end
    local epoch = math.floor(num / 4194304) + 1420070400000
    return epoch
end

AddEventHandler("playerConnecting", function(name, _, deferrals)
    local src = source
    local cfg = Config.Modules.accountAge
    if not cfg or not cfg.enabled then return end
    if not ACS or not ACS.active then return end

    Citizen.CreateThread(function()
        Wait(3000)

        if not GetPlayerName(src) then return end

        local discordId = getDiscordId(src)
        if discordId then
            local ts = discordIdToTimestamp(discordId)
            if ts then
                local ageDays = math.floor((os.time() * 1000 - ts) / 86400000)
                local minAge = cfg.minDiscordDays or MIN_DISCORD_AGE_DAYS

                if ageDays < minAge then
                    Log("WARN", ("[ACCOUNT_AGE] %s (ID:%d) Discord account is %d days old (min: %d)"):format(name, src, ageDays, minAge))

                    if AddThreatScore then AddThreatScore(src, "newAccount", 20) end

                    for adminPid, _ in pairs(ACS.connectedPlayers) do
                        if IsPlayerAceAllowed(tostring(adminPid), Config.Branding.AcePerm) then
                            TriggerClientEvent(EncodeEvent("AC:detectionNotify"), adminPid, {
                                player = name,
                                reason = ("New Discord account: %d days old"):format(ageDays),
                                type = "WARN",
                            })
                        end
                    end
                end
            end
        end

        local steam = getSteamHex(src)
        if not steam then
            if cfg.requireSteam then
                Log("WARN", ("[ACCOUNT_AGE] %s (ID:%d) has no Steam identifier"):format(name, src))
                if AddThreatScore then AddThreatScore(src, "noSteam", 15) end
            end
        end
    end)
end)
