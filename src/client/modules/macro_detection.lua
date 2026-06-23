local INPUT_CONTROLS = {
    { id = 24,  name = "attack" },
    { id = 25,  name = "aim" },
    { id = 47,  name = "detonate" },
    { id = 73,  name = "veh_accelerate" },
    { id = 21,  name = "sprint" },
    { id = 22,  name = "jump" },
    { id = 38,  name = "pickup" },
}

local inputTimestamps = {}
local SAMPLE_COUNT = 20
local VARIANCE_THRESHOLD = 15
local CHECK_INTERVAL = 5000

local function initInputTracking()
    for _, ctrl in ipairs(INPUT_CONTROLS) do
        inputTimestamps[ctrl.id] = {}
    end
end

AC.registerModule("macroDetection", {
    activate = function()
        initInputTracking()

        AC.runPeriodically(0, function()
            local now = GetGameTimer()
            for _, ctrl in ipairs(INPUT_CONTROLS) do
                if IsDisabledControlJustPressed(0, ctrl.id) or IsControlJustPressed(0, ctrl.id) then
                    local ts = inputTimestamps[ctrl.id]
                    ts[#ts + 1] = now

                    if #ts > SAMPLE_COUNT then
                        table.remove(ts, 1)
                    end
                end
            end
        end, "MacroInputCapture")

        AC.runPeriodically(CHECK_INTERVAL, function()
            for _, ctrl in ipairs(INPUT_CONTROLS) do
                local ts = inputTimestamps[ctrl.id]
                if #ts >= SAMPLE_COUNT then
                    local intervals = {}
                    for i = 2, #ts do
                        intervals[#intervals + 1] = ts[i] - ts[i - 1]
                    end

                    local sum = 0
                    for _, v in ipairs(intervals) do sum = sum + v end
                    local mean = sum / #intervals

                    if mean > 5000 then goto nextCtrl end

                    local varSum = 0
                    for _, v in ipairs(intervals) do
                        varSum = varSum + (v - mean) ^ 2
                    end
                    local stddev = math.sqrt(varSum / #intervals)

                    if stddev < VARIANCE_THRESHOLD and mean < 2000 then
                        AC.punish(DetectionType.INJECTOR, ("Macro detected on '%s': %d inputs at %.0fms intervals (stddev: %.1fms)"):format(
                            ctrl.name, #ts, mean, stddev))
                        inputTimestamps[ctrl.id] = {}
                        return
                    end
                end
                ::nextCtrl::
            end
        end, "MacroAnalysis")
    end,
    deactivate = function()
        inputTimestamps = {}
    end,
})
