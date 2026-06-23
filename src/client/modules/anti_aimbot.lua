local aimHistory = {}
local aimbotDetections = 0
local softAimOn = false

AddEventHandler("entityDamaged", function(entity, attacker, wHash)
    if not EAC.active or not EAC.config then return end
    if not EAC.isModuleEnabled(DetectionType.WALL_HACK) then return end
    local ped = PlayerPedId()
    if entity and attacker and entity ~= attacker and attacker == ped then
        if IsPedShooting(attacker) and IsEntityAPed(entity) then
            local noLOS  = not HasEntityClearLosToEntity(attacker, entity)
            local noLOS2 = not HasEntityClearLosToEntity(attacker, entity, 17)
            if noLOS then CancelEvent() end
            if noLOS and noLOS2 then
                CancelEvent()
                EAC.punish(DetectionType.WALL_HACK, "No line of sight to target")
            end
            local hit, _, _, matHash = EAC.raycastMat(1000.0)
            if hit and not matHash then
                CancelEvent()
                EAC.punish(DetectionType.WALL_HACK, "Shot through wall")
            end
        end
    end
end)

EAC.runPeriodically(300, function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    if not EAC.isModuleEnabled(DetectionType.AIMBOT) then return end

    local hasTarget, targetEnt = GetEntityPlayerIsFreeAimingAt(EAC.playerId)
    if hasTarget and targetEnt and targetEnt ~= ped then
        if (GetEntitySpeed(targetEnt) >= 1.5 or GetEntitySpeed(ped) >= 1.5)
           and IsPedArmed(ped, 6) and IsPlayerFreeAiming(EAC.playerId) then
            local hit, endC, _, _, dist = EAC.raycastSimple(1000.0)
            if hit then
                local tCoords = GetEntityCoords(targetEnt)
                local d2t = #(coords - tCoords)
                if d2t > 5.0 then
                    local tRot = GetEntityRotation(targetEnt, 2)
                    local yaw  = math.rad(tRot.z)
                    local rel  = endC - tCoords
                    local tf   = vector3(
                        rel.x * math.cos(yaw) + rel.y * math.sin(yaw),
                        rel.x * math.sin(yaw) - rel.y * math.cos(yaw),
                        rel.z)
                    if #aimHistory >= 20 then table.remove(aimHistory, 20) end
                    table.insert(aimHistory, 1, { pos = tf, dist = dist })
                    local hits = 0
                    local prev
                    for _, a in ipairs(aimHistory) do
                        if prev then
                            local diff = #(vector3(prev.pos.x/10, prev.pos.y/10, prev.pos.z)
                                        - vector3(a.pos.x/10, a.pos.y/10, a.pos.z))
                            if diff <= math.min(math.min(a.dist - 10, 2) * 0.0015, 0.05) then
                                hits = hits + 1
                            end
                            if hits >= 3 then
                                aimbotDetections = aimbotDetections + 1
                                if aimbotDetections > 3 then
                                    EAC.punish(DetectionType.AIMBOT, "Locked on to entity while aiming")
                                    aimbotDetections = 0
                                end
                                hits = 0
                            end
                        end
                        prev = a
                    end
                end
            end
        end
    end

    if GetScriptTaskStatus(ped, 3641635208) == 1
       or GetScriptTaskStatus(ped, 167901368) == 1
       or GetScriptTaskStatus(ped, 167901369) == 1 then
        EAC.punish(DetectionType.AIMBOT, "Aimbot task detected")
    end
end, "AntiAimbot")

EAC.runPeriodically(0, function()
    if not EAC.isModuleEnabled(DetectionType.SOFT_AIM) then return end
    local ped = PlayerPedId()
    if IsPedArmed(ped, 1) then
        softAimOn = true
        SetPlayerLockonRangeOverride(EAC.playerId, -1.0)
    elseif softAimOn then
        softAimOn = false
        SetPlayerLockonRangeOverride(EAC.playerId, 0.0)
        Wait(100)
    end
end, "AntiSoftAim")
