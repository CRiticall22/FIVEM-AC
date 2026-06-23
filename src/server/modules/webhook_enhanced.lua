local COLORS = {
    BAN  = 16711680,
    KICK = 16744448,
    WARN = 3447003,
    INFO = 5793266,
}

local function getPlayerIdentifierString(src)
    local ids = GetPlayerIdentifiers(src) or {}
    local parts = {}
    for _, id in ipairs(ids) do
        if string.find(id, "steam:") or string.find(id, "license:") or string.find(id, "discord:") then
            parts[#parts + 1] = "`" .. id .. "`"
        end
    end
    return table.concat(parts, "\n") or "N/A"
end

function SendEnhancedWebhook(eventType, playerName, playerId, module, details, extra)
    local url = Config.Webhook.URL
    if not url or url == "" then return end

    local color = COLORS[eventType] or COLORS.INFO
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    local fields = {
        { name = "Player", value = playerName or "Unknown", inline = true },
        { name = "Server ID", value = tostring(playerId or 0), inline = true },
        { name = "Module", value = module or "Unknown", inline = true },
        { name = "Action", value = eventType or "INFO", inline = true },
        { name = "Details", value = details or "No details", inline = false },
    }

    if playerId and playerId > 0 then
        local idStr = getPlayerIdentifierString(playerId)
        if idStr ~= "" then
            fields[#fields + 1] = { name = "Identifiers", value = idStr, inline = false }
        end
    end

    if extra then
        for k, v in pairs(extra) do
            fields[#fields + 1] = { name = k, value = tostring(v), inline = true }
        end
    end

    local embed = {
        title = Config.Branding.Name .. " — " .. eventType,
        description = ("**%s** triggered by module `%s`"):format(eventType, module or "?"),
        color = color,
        fields = fields,
        timestamp = timestamp,
        footer = {
            text = Config.Branding.Name .. " v" .. Config.Branding.Version,
        },
    }

    local payload = {
        username = Config.Webhook.BotName or Config.Branding.Name,
        avatar_url = Config.Webhook.AvatarURL or "",
        embeds = { embed },
    }

    PerformHttpRequest(url, function(code)
        if code < 200 or code >= 300 then
            Log("ERROR", ("[WEBHOOK] Failed to send: HTTP %d"):format(code))
        end
    end, "POST", json.encode(payload), { ["Content-Type"] = "application/json" })
end

function SendWebhookWithSignature(eventType, playerName, playerId, module, details, extra)
    SendEnhancedWebhook(eventType, playerName, playerId, module, details, extra)
end
