RegisterCommand("eac_unban", function(src, args)
    if src ~= 0 and not HasAdminPermission(src) then return end
    local banId = args[1]
    if not banId then
        Log("WARN", "Usage: eac_unban <BanID>")
        return
    end
    RemoveBan(banId)
    Log("INFO", "Unbanned: " .. banId)
end, true)

RegisterCommand("eac_bans", function(src)
    if src ~= 0 and not HasAdminPermission(src) then return end
    local bans = GetAllBans()
    Log("INFO", ("%d active ban(s):"):format(#bans))
    for _, b in ipairs(bans) do
        print(("  [%s] %s — %s (%s)"):format(b.id, b.name, b.reason, b.date or "?"))
    end
end, true)

RegisterCommand("eac_activate", function(src)
    if src ~= 0 and not HasAdminPermission(src) then return end
    EACS.activate()
    Log("INFO", "Anticheat activated via command")
end, true)

RegisterCommand("eac_deactivate", function(src)
    if src ~= 0 and not HasAdminPermission(src) then return end
    EACS.deactivate()
    Log("INFO", "Anticheat deactivated via command")
end, true)

RegisterCommand("eac_status", function(src)
    if src ~= 0 and not HasAdminPermission(src) then return end
    local count = 0
    for _ in pairs(EACS.connectedPlayers) do count = count + 1 end
    Log("INFO", ("Status: %s | Players: %d | Version: %s"):format(
        EACS.active and "ACTIVE" or "INACTIVE", count, Config.Branding.Version))
end, true)

RegisterCommand("eac_ban", function(src, args)
    if src ~= 0 and not HasAdminPermission(src) then return end
    local targetId = tonumber(args[1])
    local reason = table.concat(args, " ", 2)
    if not targetId then
        Log("WARN", "Usage: eac_ban <playerId> <reason>")
        return
    end
    if reason == "" then reason = "Admin ban" end
    BanPlayer(targetId, reason, "Manual ban by " .. (src == 0 and "console" or GetPlayerName(src)))
    Log("INFO", ("Banned player %d: %s"):format(targetId, reason))
end, true)

RegisterCommand("eac_kick", function(src, args)
    if src ~= 0 and not HasAdminPermission(src) then return end
    local targetId = tonumber(args[1])
    local reason = table.concat(args, " ", 2)
    if not targetId then
        Log("WARN", "Usage: eac_kick <playerId> <reason>")
        return
    end
    if reason == "" then reason = "Admin kick" end
    KickPlayer(targetId, reason, "Manual kick by " .. (src == 0 and "console" or GetPlayerName(src)))
    Log("INFO", ("Kicked player %d: %s"):format(targetId, reason))
end, true)

RegisterCommand("eac_info", function(src, args)
    if src ~= 0 and not HasAdminPermission(src) then return end
    local targetId = tonumber(args[1])
    if not targetId then
        Log("WARN", "Usage: eac_info <playerId>")
        return
    end
    local info = GetPlayerInfo(targetId)
    if not info then
        Log("WARN", "Player not found: " .. targetId)
        return
    end
    print(("  Name: %s"):format(info.name))
    print(("  License: %s"):format(info.identifiers.license or "N/A"))
    print(("  Steam: %s"):format(info.identifiers.steam or "N/A"))
    print(("  Discord: %s"):format(info.identifiers.discord or "N/A"))
    print(("  IP: %s"):format(Config.Logs.ShowIPs and (info.identifiers.ip or "N/A") or "Hidden"))
    print(("  Whitelisted: %s"):format(IsPlayerWhitelisted(targetId) and "Yes" or "No"))
    print(("  Admin: %s"):format(HasAdminPermission(targetId) and "Yes" or "No"))
end, true)
