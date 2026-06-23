local REPORT_INTERVAL = 5000
local pendingReports = {}
local triggerCounts = {}
local lastReportTime = 0

local BLACKLISTED_PATTERNS = {
    "^_cfx_",
    "^__cfx_",
    "DeleteEntity",
    "DeleteResourceKvp",
    "ServerCallback",
}

local KNOWN_EXECUTOR_GLOBALS = {
    "ExecuteCommand_Bypass",
    "ExecuteCheat",
    "CheatMenu",
    "MenuBase",
    "LynxMenu",
    "SkidMenu",
    "Eulen",
    "RedEngine",
    "Dopamine",
    "Desudo",
    "Brutan",
    "HamMafia",
    "Cherax",
}

AC.registerModule("triggerMonitor", {
    activate = function()
        AC.runPeriodically(1000, function()
            for _, globalName in ipairs(KNOWN_EXECUTOR_GLOBALS) do
                local val = rawget(_G, globalName)
                if val ~= nil then
                    AC.punish(DetectionType.INJECTOR, "Known executor global detected: " .. globalName)
                    return
                end
            end
        end, "ExecutorGlobalScan")

        AC.runPeriodically(2000, function()
            local env = getfenv(0)
            if not env then return end

            local suspicious = 0
            for k, v in pairs(env) do
                if type(k) == "string" then
                    local lower = string.lower(k)
                    if string.find(lower, "cheat", 1, true) or
                       string.find(lower, "hack", 1, true) or
                       string.find(lower, "exploit", 1, true) or
                       string.find(lower, "inject", 1, true) or
                       string.find(lower, "executor", 1, true) or
                       string.find(lower, "bypass", 1, true) then
                        suspicious = suspicious + 1
                    end
                end
            end

            if suspicious >= 3 then
                AC.punish(DetectionType.INJECTOR, ("Found %d suspicious globals (cheat/hack/exploit keywords)"):format(suspicious))
            end
        end, "SuspiciousGlobalScan")

        AC.runPeriodically(3000, function()
            local debugInfo = debug and debug.getinfo
            if debugInfo then
                local info = debugInfo(1, "S")
                if info and info.source then
                    local src = info.source
                    if string.find(src, "@") then
                        local resource = src:match("@([^/]+)")
                        if resource and resource ~= GetCurrentResourceName() then
                            return
                        end
                    end
                end
            end
        end, "DebugInfoCheck")

        AC.runPeriodically(5000, function()
            local mt = getmetatable(_G)
            if mt and (mt.__newindex or mt.__index) then
                local customMt = true
                if rawget(mt, "__ac_safe") then customMt = false end
                if customMt then
                    AC.punish(DetectionType.INJECTOR, "Global metatable tampered — custom __newindex or __index detected")
                end
            end
        end, "MetatableGuard")
    end,
    deactivate = function()
        pendingReports = {}
        triggerCounts = {}
    end,
})
