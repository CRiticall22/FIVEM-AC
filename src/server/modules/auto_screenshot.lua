local screenshotQueue = {}
local SCREENSHOT_RESOURCE = "screenshot-basic"

function TakeEvidenceScreenshot(src, module, details)
    if GetResourceState(SCREENSHOT_RESOURCE) ~= "started" then
        Log("WARN", "[SCREENSHOT] screenshot-basic is not running, skipping evidence capture")
        return
    end

    local cfg = Config.Modules.autoScreenshot
    if not cfg or not cfg.enabled then return end

    local name = GetPlayerName(src) or "Unknown"

    exports[SCREENSHOT_RESOURCE]:requestClientScreenshot(src, {
        encoding = "png",
        quality = 0.85,
    }, function(err, data)
        if err then
            Log("ERROR", ("[SCREENSHOT] Failed to capture %s: %s"):format(name, tostring(err)))
            return
        end

        local banId = module .. "_" .. os.time()
        local evidence = {
            player = name,
            playerId = src,
            module = module,
            details = details,
            timestamp = os.time(),
            screenshot = data,
        }

        screenshotQueue[banId] = evidence
        Log("INFO", ("[SCREENSHOT] Evidence captured for %s — %s"):format(name, module))

        if cfg.webhookUrl and cfg.webhookUrl ~= "" then
            local embed = {
                title = "Evidence Screenshot",
                description = ("**Player:** %s\n**Module:** %s\n**Details:** %s"):format(name, module, details),
                color = 16711680,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                image = { url = "attachment://evidence.png" },
            }

            PerformHttpRequest(cfg.webhookUrl, function() end, "POST",
                json.encode({ embeds = { embed } }),
                { ["Content-Type"] = "application/json" })
        end
    end)
end

function GetScreenshotEvidence(banId)
    return screenshotQueue[banId]
end
