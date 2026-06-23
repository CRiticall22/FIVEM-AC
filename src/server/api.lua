exports("banPlayer", function(src, reason, details)
    BanPlayer(src, reason, details or "")
end)

exports("kickPlayer", function(src, reason, details)
    KickPlayer(src, reason, details or "")
end)

exports("warnPlayer", function(src, reason, details)
    WarnPlayer(src, reason, details or "")
end)

exports("unban", function(banId)
    RemoveBan(banId)
    Log("INFO", "Unbanned via API: " .. banId)
end)

exports("getBans", function()
    return GetAllBans()
end)

exports("isPlayerBanned", function(identifiers)
    return IsIdentifierBanned(identifiers)
end)

exports("isPlayerWhitelisted", function(src)
    return IsPlayerWhitelisted(src)
end)

exports("isActive", function()
    return EACS.active
end)

exports("activate", function()
    EACS.activate()
end)

exports("deactivate", function()
    EACS.deactivate()
end)

exports("getPlayerHeartbeat", function(src)
    return playerHeartbeats and playerHeartbeats[src] or nil
end)

exports("getConnectedPlayers", function()
    local list = {}
    for pid, _ in pairs(EACS.connectedPlayers) do
        list[#list + 1] = pid
    end
    return list
end)

exports("punishPlayer", function(src, module, details)
    PunishPlayer(src, module, details)
end)
