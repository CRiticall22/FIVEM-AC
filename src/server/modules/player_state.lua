AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    if not EACS.active then return end
    local src = source
    deferrals.defer()
    Wait(0)

    local ids = GetPlayerIdentifiers(src)
    if not ids.license then
        deferrals.done("Your license could not be verified. Please restart your game.")
        return
    end

    if EACS.playerLicenses[ids.license] then
        deferrals.done("Your identifiers are already in use on this server.")
        return
    end

    deferrals.update("Checking ban list...")
    Wait(0)

    local ban = IsIdentifierBanned(ids)
    if ban then
        deferrals.done(("\n[%s]\nYou are banned.\nBan ID: %s\nReason: %s\nDate: %s")
            :format(Config.Branding.Name, ban.id, ban.reason or "N/A", ban.date or "N/A"))
        return
    end

    if Config.Modules.antiBlacklistName.enabled then
        local lower = string.lower(name)
        for _, word in ipairs(Config.Modules.antiBlacklistName.blacklist or {}) do
            if string.find(lower, string.lower(word)) then
                deferrals.done(("\n[%s]\nYour name contains a prohibited word: %s")
                    :format(Config.Branding.Name, word))
                return
            end
        end
    end

    if Config.Logs.Console then
        Log("INFO", name .. " connecting...")
    end

    Wait(0)
    deferrals.done()
end)

AddEventHandler("playerJoining", function()
    local src = source
    local ids = GetPlayerIdentifiers(src)

    if not ids or not ids.license then
        DropPlayer(src, "Could not verify identifiers")
        return
    end

    if EACS.playerLicenses[ids.license] then
        Wait(0)
        DropPlayer(src, "Identifier already in use")
        return
    end

    EACS.playerLicenses[ids.license] = true
end)

AddEventHandler("playerDropped", function()
    local src = source
    EACS.connectedPlayers[src] = nil

    local ids = GetPlayerIdentifiers(src)
    if ids and ids.license then
        EACS.playerLicenses[ids.license] = nil
    end

    if Config.Logs.Console then
        local name = GetPlayerName(src) or "?"
        Log("INFO", name .. " disconnected")
    end
end)

AddEventHandler("chatMessage", function(src, _, msg)
    if not EACS.active then return end
    if not Config.Modules.antiBlacklistWords.enabled then return end
    local lower = string.lower(msg)
    for _, word in ipairs(Config.Modules.antiBlacklistWords.blacklist or {}) do
        if string.find(lower, string.lower(word)) then
            CancelEvent()
            PunishPlayer(src, DetectionType.BLACKLIST_WORDS, "Said: " .. word)
            return
        end
    end
end)
