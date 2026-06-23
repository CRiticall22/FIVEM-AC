local shadowLog = {}
local MAX_LOG = 500

function IsShadowMode()
    return Config.Modules.shadowMode and Config.Modules.shadowMode.enabled
end

function LogShadowDetection(src, module, details)
    local name = GetPlayerName(src) or "?"
    local entry = {
        player  = name,
        id      = src,
        module  = module,
        details = details,
        time    = os.date("%H:%M:%S"),
        date    = os.date("%Y-%m-%d"),
        score   = GetThreatScore(src),
    }
    shadowLog[#shadowLog + 1] = entry
    if #shadowLog > MAX_LOG then table.remove(shadowLog, 1) end

    Log("DEBUG", ("[SHADOW] %s (ID %d) — %s — %s"):format(name, src, module, details or ""))
end

function GetShadowLog()
    return shadowLog
end

function ClearShadowLog()
    shadowLog = {}
end

RegisterCommand("ac_shadow_log", function(src)
    if src ~= 0 and not HasAdminPermission(src) then return end
    Log("INFO", ("%d shadow detections logged:"):format(#shadowLog))
    for _, e in ipairs(shadowLog) do
        print(("  [%s] %s (ID %d) — %s — Score: %d"):format(
            e.time, e.player, e.id, e.module, e.score))
    end
end, true)

RegisterCommand("ac_shadow_clear", function(src)
    if src ~= 0 and not HasAdminPermission(src) then return end
    ClearShadowLog()
    Log("INFO", "Shadow log cleared")
end, true)

RegisterCommand("ac_shadow_ban_all", function(src)
    if src ~= 0 and not HasAdminPermission(src) then return end
    local banned = {}
    for _, e in ipairs(shadowLog) do
        if e.score >= 50 and not banned[e.id] then
            banned[e.id] = true
            local name = GetPlayerName(e.id)
            if name then
                BanPlayer(e.id, "Shadow mode review", "Accumulated " .. e.score .. " threat score")
            end
        end
    end
    local count = 0
    for _ in pairs(banned) do count = count + 1 end
    Log("INFO", ("Shadow ban: banned %d players with score >= 50"):format(count))
    ClearShadowLog()
end, true)
