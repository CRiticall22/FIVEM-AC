local AIM_SAMPLES = 120
local SNAP_THRESHOLD = 15.0
local ZERO_JITTER_THRESHOLD = 0.05
local PERFECT_TRACK_THRESHOLD = 0.8

local aimHistory = {}
local aimIdx = 0
local lastAimX, lastAimY = 0.0, 0.0
local suspiciousSnaps = 0
local zeroJitterFrames = 0
local totalFrames = 0

local cfg

AC.registerModule("mouseForensics", {
    activate = function()
        cfg = AC.getModuleConfig(DetectionType.AIMBOT)
        if not cfg then return end

        AC.runPeriodically(0, function()
            local ped = PlayerPedId()
            if not IsPedShooting(ped) and not IsPlayerFreeAiming(PlayerId()) then
                return
            end

            local aimX = GetDisabledControlNormal(0, 1)
            local aimY = GetDisabledControlNormal(0, 2)

            local dx = aimX - lastAimX
            local dy = aimY - lastAimY
            local delta = math.sqrt(dx * dx + dy * dy)

            totalFrames = totalFrames + 1

            if delta > SNAP_THRESHOLD then
                suspiciousSnaps = suspiciousSnaps + 1
            end

            if delta < ZERO_JITTER_THRESHOLD and delta > 0.001 then
                zeroJitterFrames = zeroJitterFrames + 1
            end

            aimIdx = (aimIdx % AIM_SAMPLES) + 1
            aimHistory[aimIdx] = { dx = dx, dy = dy, d = delta, t = GetGameTimer() }

            lastAimX, lastAimY = aimX, aimY
        end, "MouseForensics")

        AC.runPeriodically(10000, function()
            if totalFrames < 60 then return end

            local snapRate = suspiciousSnaps / totalFrames
            if snapRate > 0.25 then
                AC.punish(DetectionType.AIMBOT, ("Inhuman snap rate: %.1f%% (%d/%d frames)"):format(snapRate * 100, suspiciousSnaps, totalFrames))
                return
            end

            local jitterRate = zeroJitterFrames / totalFrames
            if jitterRate > PERFECT_TRACK_THRESHOLD then
                AC.punish(DetectionType.AIMBOT, ("Perfect tracking (zero jitter): %.1f%% of frames"):format(jitterRate * 100))
                return
            end

            suspiciousSnaps = 0
            zeroJitterFrames = 0
            totalFrames = 0
        end, "MouseForensicsAnalysis")
    end,
    deactivate = function()
        aimHistory = {}
        aimIdx = 0
        suspiciousSnaps = 0
        zeroJitterFrames = 0
        totalFrames = 0
    end,
})
