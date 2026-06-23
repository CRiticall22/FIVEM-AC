local playerJobEvents = {}
local LOOP_WINDOW = 60000
local MIN_REPEATS = 5
local INTERVAL_VARIANCE_THRESHOLD = 500

local JOB_PATTERNS = {
    "job", "work", "farm", "harvest", "mine", "fish", "hunt",
    "craft", "process", "sell", "deliver", "collect", "pickup",
    "duty", "clock", "task", "mission", "start", "complete",
}

local function isJobEvent(eventName)
    local lower = string.lower(eventName)
    for _, pattern in ipairs(JOB_PATTERNS) do
        if string.find(lower, pattern, 1, true) then
            return true
        end
    end
    return false
end

local function detectLoop(src, eventName)
    if not playerJobEvents[src] then playerJobEvents[src] = {} end
    if not playerJobEvents[src][eventName] then playerJobEvents[src][eventName] = {} end

    local timestamps = playerJobEvents[src][eventName]
    timestamps[#timestamps + 1] = GetGameTimer()

    local now = GetGameTimer()
    local recent = {}
    for _, t in ipairs(timestamps) do
        if now - t < LOOP_WINDOW then
            recent[#recent + 1] = t
        end
    end
    playerJobEvents[src][eventName] = recent

    if #recent < MIN_REPEATS then return end

    local intervals = {}
    for i = 2, #recent do
        intervals[#intervals + 1] = recent[i] - recent[i - 1]
    end

    if #intervals < 2 then return end

    local sum = 0
    for _, v in ipairs(intervals) do sum = sum + v end
    local mean = sum / #intervals

    local varianceSum = 0
    for _, v in ipairs(intervals) do
        varianceSum = varianceSum + (v - mean) ^ 2
    end
    local stddev = math.sqrt(varianceSum / #intervals)

    if stddev < INTERVAL_VARIANCE_THRESHOLD and mean < 15000 then
        local name = GetPlayerName(src) or "Unknown"
        Log("WARN", ("[JOB_LOOP] %s (ID:%d) repeating '%s' every %.0fms (stddev: %.0fms, %d times)"):format(
            name, src, eventName, mean, stddev, #recent))

        if AddThreatScore then AddThreatScore(src, "jobLoop", 35) end

        if #recent >= MIN_REPEATS * 2 then
            PunishPlayer(src, "jobLoopDetection", ("Automated job loop: '%s' repeated %d times at %.0fms intervals"):format(eventName, #recent, mean))
        end

        playerJobEvents[src][eventName] = {}
    end
end

AddEventHandler("__cfx_internal:serverGameEvent", function(name)
    local src = source
    if not src or src <= 0 then return end
    if not ACS or not ACS.active then return end

    local cfg = Config.Modules.jobLoopDetection
    if not cfg or not cfg.enabled then return end

    if IsPlayerAceAllowed(tostring(src), Config.Whitelist.AcePerm) then return end

    if isJobEvent(name or "") then
        detectLoop(src, name)
    end
end)

AddEventHandler("playerDropped", function()
    playerJobEvents[source] = nil
end)
