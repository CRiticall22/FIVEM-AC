local MAX_ACCEL = 45.0
local MAX_VEHICLE_SPEED = 90.0
local GRAVITY_CHECK_INTERVAL = 2000
local GRAVITY_MIN = -5.0

local lastVehSpeed = 0.0
local lastSpeedTime = 0
local violations = 0
local VIOLATION_THRESHOLD = 3

AC.registerModule("physicsValidator", {
    activate = function()
        AC.runPeriodically(200, function()
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh == 0 then
                lastVehSpeed = 0.0
                lastSpeedTime = 0
                return
            end

            local speed = GetEntitySpeed(veh) * 3.6
            local now = GetGameTimer()

            if lastSpeedTime > 0 then
                local dt = (now - lastSpeedTime) / 1000.0
                if dt > 0.05 then
                    local accel = (speed - lastVehSpeed) / dt

                    if accel > MAX_ACCEL and speed > 50 then
                        violations = violations + 1
                        if violations >= VIOLATION_THRESHOLD then
                            AC.punish(DetectionType.SPEEDHACK, ("Impossible acceleration: %.1f km/h/s (%.0f→%.0f km/h)"):format(accel, lastVehSpeed, speed))
                            violations = 0
                            return
                        end
                    else
                        violations = math.max(0, violations - 1)
                    end
                end
            end

            if speed > MAX_VEHICLE_SPEED * 3.6 then
                AC.punish(DetectionType.SPEEDHACK, ("Vehicle exceeds physics cap: %.0f km/h"):format(speed))
                return
            end

            lastVehSpeed = speed
            lastSpeedTime = now
        end, "PhysicsValidator")

        AC.runPeriodically(GRAVITY_CHECK_INTERVAL, function()
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh == 0 then return end

            if not IsEntityInAir(veh) then return end

            local vel = GetEntityVelocity(veh)
            if vel.z > 5.0 and GetEntityHeightAboveGround(veh) > 10.0 then
                local hasRocket = GetVehicleMod(veh, 50) ~= -1
                if not hasRocket then
                    AC.punish(DetectionType.NOCLIP, ("Anti-gravity vehicle: vZ=%.1f, height=%.1fm"):format(vel.z, GetEntityHeightAboveGround(veh)))
                end
            end
        end, "GravityCheck")
    end,
    deactivate = function()
        lastVehSpeed = 0.0
        lastSpeedTime = 0
        violations = 0
    end,
})
