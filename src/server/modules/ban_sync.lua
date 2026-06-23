local resourceName = GetCurrentResourceName()

RegisterCommand("ac_export_bans", function(src)
    if src ~= 0 and not IsPlayerAceAllowed(tostring(src), Config.Whitelist.AcePerm) then return end

    local bans = {}
    local handle = StartFindKvp("ban:")
    local key = FindKvp(handle)

    while key do
        local data = GetResourceKvpString(key)
        if data then
            local decoded = json.decode(data)
            if decoded then
                bans[#bans + 1] = decoded
            end
        end
        key = FindKvp(handle)
    end
    EndFindKvp(handle)

    local exportData = {
        version = 1,
        server = Config.Branding.Name,
        exported = os.time(),
        count = #bans,
        bans = bans,
    }

    local encoded = json.encode(exportData)
    SaveResourceFile(resourceName, "bans_export.json", encoded, -1)

    local msg = ("Exported %d bans to bans_export.json"):format(#bans)
    if src == 0 then print(msg) else
        TriggerClientEvent("chat:addMessage", src, { args = { "2F4R", msg }, color = { 100, 255, 100 } })
    end
    Log("INFO", "[BAN_SYNC] " .. msg)
end, false)

RegisterCommand("ac_import_bans", function(src)
    if src ~= 0 and not IsPlayerAceAllowed(tostring(src), Config.Whitelist.AcePerm) then return end

    local content = LoadResourceFile(resourceName, "bans_import.json")
    if not content then
        local msg = "No bans_import.json found. Place the file in the resource folder."
        if src == 0 then print(msg) else
            TriggerClientEvent("chat:addMessage", src, { args = { "2F4R", msg }, color = { 255, 100, 100 } })
        end
        return
    end

    local data = json.decode(content)
    if not data or not data.bans then
        local msg = "Invalid bans_import.json format."
        if src == 0 then print(msg) else
            TriggerClientEvent("chat:addMessage", src, { args = { "2F4R", msg }, color = { 255, 100, 100 } })
        end
        return
    end

    local imported = 0
    local skipped = 0

    for _, ban in ipairs(data.bans) do
        if ban.identifiers and ban.reason then
            local banId = ban.banId or GenerateBanId()
            local existing = GetResourceKvpString("ban:" .. banId)

            if existing then
                skipped = skipped + 1
            else
                local record = {
                    name = ban.name or "Imported",
                    identifiers = ban.identifiers,
                    reason = "[SYNC] " .. (ban.reason or "Imported ban"),
                    banId = banId,
                    date = ban.date or os.date("%Y-%m-%d %H:%M"),
                    source = ban.server or "external",
                }
                SetResourceKvp("ban:" .. banId, json.encode(record))
                imported = imported + 1
            end
        end
    end

    local msg = ("Imported %d bans, skipped %d duplicates (from: %s)"):format(imported, skipped, data.server or "unknown")
    if src == 0 then print(msg) else
        TriggerClientEvent("chat:addMessage", src, { args = { "2F4R", msg }, color = { 100, 255, 100 } })
    end
    Log("INFO", "[BAN_SYNC] " .. msg)
end, false)
