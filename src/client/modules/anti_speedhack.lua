local speedDetections = 0
local staminaDetections = 0
local isOutOfStamina = false

EAC.runPeriodically(1000, function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)

    if not EAC.isModuleEnabled(DetectionType.SPEED_CHANGER) then return end

    if vehicle then
        if not (IsPedInAnyPlane(ped) or IsPedInAnyHeli(ped)) then
            local vel = GetEntityVelocity(vehicle)
            local maxSpd = GetVehicleEstimatedMaxSpeed(vehicle)
            if maxSpd then
                local spd = #vector2(vel.x, vel.y)
                if not IsEntityInAir(vehicle) and spd > maxSpd + 10.0 then
                    local norm = vector2(vel.x, vel.y) * maxSpd / spd
                    SetEntityVelocity(vehicle, norm.x, norm.y, vel.z)
                end
            end
        end
    else
        local vel = GetEntityVelocity(ped)
        local spd = #vector2(vel.x, vel.y)
        local maxSpd = 9.066428184509
        if IsPedRunning(ped) and not IsPedJumping(ped) and not IsPedRagdoll(ped)
           and not IsEntityInAir(ped) and not IsPedClimbing(ped) and spd > maxSpd then
            local norm = vector2(vel.x, vel.y) * maxSpd / spd
            SetEntityVelocity(ped, norm.x, norm.y, vel.z)
            speedDetections = speedDetections + 1
            if speedDetections >= 2 then
                speedDetections = 0
                EAC.punish(DetectionType.SPEED_CHANGER, "Walk speed: " .. spd)
            end
        else
            speedDetections = 0
        end
    end

    if EAC.isModuleEnabled(DetectionType.STAMINA) then
        local pedH = GetEntityHeightAboveGround(ped)
        if GetEntitySpeed(ped) > 7 and not vehicle
           and not IsPedFalling(ped) and not IsPedInParachuteFreeFall(ped)
           and not IsPedJumpingOutOfVehicle(ped) and not IsPedRagdoll(ped)
           and not IsEntityInAir(ped) and not IsPedDeadOrDying(ped) and pedH <= 1.0 then
            local vel = GetEntityVelocity(ped)
            local spd = #vector2(vel.x, vel.y)
            local norm = vector2(vel.x, vel.y) * 6 / spd
            SetEntityVelocity(ped, norm.x, norm.y, vel.z)
            local remain = GetPlayerSprintStaminaRemaining(EAC.playerId)
            if remain == 0.0 then
                if isOutOfStamina then
                    staminaDetections = staminaDetections + 1
                    if staminaDetections > 2 then
                        staminaDetections = 0
                        EAC.punish(DetectionType.STAMINA, "Stamina hacks")
                    end
                end
                isOutOfStamina = true
            else
                isOutOfStamina = false
            end
        end
    end
end, "AntiSpeed")
