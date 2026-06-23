local reports = {}
local reportCooldowns = {}
local COOLDOWN = 60000

RegisterCommand("report", function(src, args)
    if src == 0 then return end
    if not ACS or not ACS.active then return end

    local cfg = Config.Modules.reportSystem
    if not cfg or not cfg.enabled then return end

    local now = GetGameTimer()
    if reportCooldowns[src] and (now - reportCooldowns[src]) < COOLDOWN then
        TriggerClientEvent("chat:addMessage", src, {
            args = { "2F4R", "Please wait before submitting another report." },
            color = { 255, 100, 100 },
        })
        return
    end

    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent("chat:addMessage", src, {
            args = { "2F4R", "Usage: /report [player id] [reason]" },
            color = { 255, 200, 100 },
        })
        return
    end

    local reason = table.concat(args, " ", 2)
    if reason == "" then reason = "No reason provided" end

    local reporterName = GetPlayerName(src) or "Unknown"
    local targetName = GetPlayerName(targetId) or "Unknown"

    local report = {
        id = #reports + 1,
        reporter = { id = src, name = reporterName },
        target = { id = targetId, name = targetName },
        reason = reason,
        time = os.time(),
        status = "pending",
    }

    reports[#reports + 1] = report
    reportCooldowns[src] = now

    TriggerClientEvent("chat:addMessage", src, {
        args = { "2F4R", ("Report #%d submitted against %s. An admin will review it."):format(report.id, targetName) },
        color = { 100, 255, 100 },
    })

    Log("INFO", ("[REPORT] #%d: %s reported %s — %s"):format(report.id, reporterName, targetName, reason))

    for adminPid, _ in pairs(ACS.connectedPlayers) do
        if IsPlayerAceAllowed(tostring(adminPid), Config.Branding.AcePerm) then
            TriggerClientEvent("chat:addMessage", adminPid, {
                args = { "2F4R REPORT", ("#%d: %s → %s: %s"):format(report.id, reporterName, targetName, reason) },
                color = { 255, 165, 0 },
            })
            TriggerClientEvent(EncodeEvent("AC:detectionNotify"), adminPid, {
                player = reporterName .. " → " .. targetName,
                reason = "Report: " .. reason,
                type = "WARN",
            })
        end
    end
end, false)

RegisterCommand("ac_reports", function(src)
    if src ~= 0 and not IsPlayerAceAllowed(tostring(src), Config.Branding.AcePerm) then return end

    local pending = {}
    for _, r in ipairs(reports) do
        if r.status == "pending" then
            pending[#pending + 1] = r
        end
    end

    if #pending == 0 then
        local msg = "No pending reports."
        if src == 0 then print(msg) else
            TriggerClientEvent("chat:addMessage", src, { args = { "2F4R", msg }, color = { 100, 200, 255 } })
        end
        return
    end

    for _, r in ipairs(pending) do
        local line = ("#%d | %s reported %s | %s"):format(r.id, r.reporter.name, r.target.name, r.reason)
        if src == 0 then print(line) else
            TriggerClientEvent("chat:addMessage", src, { args = { "REPORT", line }, color = { 255, 165, 0 } })
        end
    end
end, false)

RegisterCommand("ac_resolve", function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(tostring(src), Config.Branding.AcePerm) then return end

    local reportId = tonumber(args[1])
    if not reportId then
        local msg = "Usage: /ac_resolve [report id]"
        if src == 0 then print(msg) else
            TriggerClientEvent("chat:addMessage", src, { args = { "2F4R", msg }, color = { 255, 200, 100 } })
        end
        return
    end

    for _, r in ipairs(reports) do
        if r.id == reportId then
            r.status = "resolved"
            local msg = ("Report #%d resolved."):format(reportId)
            if src == 0 then print(msg) else
                TriggerClientEvent("chat:addMessage", src, { args = { "2F4R", msg }, color = { 100, 255, 100 } })
            end
            return
        end
    end
end, false)

function GetPendingReports()
    local pending = {}
    for _, r in ipairs(reports) do
        if r.status == "pending" then pending[#pending + 1] = r end
    end
    return pending
end
