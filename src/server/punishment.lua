local KVP_PREFIX = "eac_ban_"
local punishCache = {}

function GetPlayerIdentifiers(src)
    local raw = GetPlayerIdentifiers(src)
    local ids = {}
    for i = 1, #raw do
        local parts = {}
        for part in string.gmatch(raw[i], "([^:]+)") do
            parts[#parts + 1] = part
        end
        if parts[1] and parts[2] then
            ids[parts[1]] = parts[2]
        end
    end
    ids.hwids = {}
    for i = 0, GetNumPlayerTokens(src) do
        ids.hwids[#ids.hwids + 1] = GetPlayerToken(src, i)
    end
    ids.ip = GetPlayerEndpoint(src)
    return ids
end

function GetPlayerInfo(src)
    local name = GetPlayerName(src)
    if not name then return nil end
    return { source = src, name = name, identifiers = GetPlayerIdentifiers(src) }
end

function SaveBan(banData)
    SetResourceKvp(KVP_PREFIX .. banData.id, json.encode(banData))
    local index = GetResourceKvpString("eac_ban_index") or "[]"
    local list = json.decode(index)
    list[#list + 1] = banData.id
    SetResourceKvp("eac_ban_index", json.encode(list))
end

function GetAllBans()
    local index = GetResourceKvpString("eac_ban_index")
    if not index then return {} end
    local list = json.decode(index)
    local bans = {}
    for _, id in ipairs(list) do
        local raw = GetResourceKvpString(KVP_PREFIX .. id)
        if raw then
            bans[#bans + 1] = json.decode(raw)
        end
    end
    return bans
end

function RemoveBan(banId)
    DeleteResourceKvp(KVP_PREFIX .. banId)
    local index = GetResourceKvpString("eac_ban_index") or "[]"
    local list = json.decode(index)
    local newList = {}
    for _, id in ipairs(list) do
        if id ~= banId then
            newList[#newList + 1] = id
        end
    end
    SetResourceKvp("eac_ban_index", json.encode(newList))
end

function IsIdentifierBanned(identifiers)
    local bans = GetAllBans()
    for _, ban in ipairs(bans) do
        if ban.identifiers then
            if identifiers.license and ban.identifiers.license == identifiers.license then
                return ban
            end
            if identifiers.steam and ban.identifiers.steam == identifiers.steam then
                return ban
            end
            if identifiers.discord and ban.identifiers.discord == identifiers.discord then
                return ban
            end
            if identifiers.xbl and ban.identifiers.xbl == identifiers.xbl then
                return ban
            end
            if identifiers.ip and ban.identifiers.ip == identifiers.ip then
                return ban
            end
            if identifiers.hwids and ban.identifiers.hwids then
                for _, hwid in ipairs(identifiers.hwids) do
                    for _, bannedHwid in ipairs(ban.identifiers.hwids) do
                        if hwid == bannedHwid and hwid ~= "" then
                            return ban
                        end
                    end
                end
            end
        end
    end
    return nil
end

function SendWebhook(url, payload)
    if not url or url == "" then return end
    PerformHttpRequest(url, function(code)
        if code < 200 or code > 299 then
            Log("WARN", "Webhook failed with status " .. tostring(code))
        end
    end, "POST", json.encode(payload), { ["Content-Type"] = "application/json" })
end

function SendDetectionWebhook(playerInfo, action, reason, details, color, screenshotData)
    local url
    if action == "Banned" then
        url = Config.Discord.BanWebhook
    elseif action == "Kicked" then
        url = Config.Discord.KickWebhook
    elseif action == "Warned" then
        url = Config.Discord.WarnWebhook
    else
        url = Config.Discord.DetectionWebhook
    end

    if not url or url == "" then return end

    local ipText = Config.Logs.ShowIPs and (playerInfo.identifiers.ip or "N/A") or "Hidden"
    local discord = playerInfo.identifiers.discord
        and ("<@" .. playerInfo.identifiers.discord .. ">")
        or "N/A"

    local image = nil
    if screenshotData then
        image = { url = "attachment://screenshot.png" }
    end

    SendWebhook(url, {
        username = Config.Discord.BotName,
        avatar_url = Config.Discord.BotAvatar ~= "" and Config.Discord.BotAvatar or nil,
        embeds = {{
            title = action,
            description = ("**%s**\n%s"):format(reason, details or ""),
            color = color or Config.Discord.Color.Info,
            image = image,
            fields = {
                { name = "Player",  value = playerInfo.name,                         inline = true },
                { name = "ID",      value = tostring(playerInfo.source),             inline = true },
                { name = "IP",      value = ipText,                                  inline = true },
                { name = "Discord", value = discord,                                 inline = true },
                { name = "License", value = playerInfo.identifiers.license or "N/A", inline = true },
                { name = "Steam",   value = playerInfo.identifiers.steam or "N/A",   inline = true },
            },
            footer = { text = Config.Branding.Name .. " v" .. Config.Branding.Version },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }},
    })
end

function TakeScreenshot(src, callback)
    if not Config.Screenshot.Enabled then
        callback(nil)
        return
    end
    if GetResourceState("screenshot-basic") ~= "started" then
        callback(nil)
        return
    end
    exports["screenshot-basic"]:requestClientScreenshot(src, {
        encoding = Config.Screenshot.Encoding or "webp",
        quality  = Config.Screenshot.Quality or 0.92,
    }, function(err, data)
        if err then
            callback(nil)
        else
            callback(data)
        end
    end)
end

function BanPlayer(src, reason, details)
    if IsPlayerWhitelisted(src) then return end

    local info = GetPlayerInfo(src)
    if not info then return end

    local banId = GenerateBanId()
    local banData = {
        id          = banId,
        name        = info.name,
        reason      = reason,
        details     = details,
        identifiers = info.identifiers,
        timestamp   = os.time(),
        date        = os.date("%Y-%m-%d %H:%M:%S"),
    }
    SaveBan(banData)

    if Config.Logs.Console then
        Log("WARN", ("BANNED %s (ID %s) — %s — BanID: %s"):format(info.name, src, reason, banId))
    end

    TakeScreenshot(src, function(screenshotData)
        local det = details or ""
        if screenshotData then
            det = det .. "\n[Screenshot captured]"
        end
        SendDetectionWebhook(info, "Banned", reason, det, Config.Discord.Color.Ban, screenshotData)
    end)

    DropPlayer(src, Config.Messages.Ban:format(banId, reason))
end

function KickPlayer(src, reason, details)
    if IsPlayerWhitelisted(src) then return end

    local info = GetPlayerInfo(src)
    if not info then return end

    if Config.Logs.Console then
        Log("WARN", ("KICKED %s (ID %s) — %s"):format(info.name, src, reason))
    end
    SendDetectionWebhook(info, "Kicked", reason, details, Config.Discord.Color.Kick)

    DropPlayer(src, Config.Messages.Kick .. "\nReason: " .. reason)
end

function WarnPlayer(src, reason, details)
    if IsPlayerWhitelisted(src) then return end

    local info = GetPlayerInfo(src)
    if not info then return end

    if Config.Logs.Console then
        Log("INFO", ("WARNED %s (ID %s) — %s"):format(info.name, src, reason))
    end
    SendDetectionWebhook(info, "Warned", reason, details, Config.Discord.Color.Warn)
end

function PunishPlayer(src, module, details)
    if punishCache[src] == module then return end
    punishCache[src] = module

    local cfg = Config.Modules[module]
    if not cfg then return end

    Citizen.CreateThread(function()
        if cfg.punishment == PunishAction.BAN then
            BanPlayer(src, module, details)
        elseif cfg.punishment == PunishAction.KICK then
            KickPlayer(src, module, details)
        elseif cfg.punishment == PunishAction.WARN then
            WarnPlayer(src, module, details)
        end
    end)
end

AddEventHandler("playerDropped", function()
    punishCache[source] = nil
end)
