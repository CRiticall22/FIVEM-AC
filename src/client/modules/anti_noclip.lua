local teleportPositions = {}
local lastCoords
local lastNoClipTime = -math.huge
local noClipDetections = 0
local lastUnderMapCheck = -9999999
local invisDetections = 0
local lastSavedPos
local lastSavedVel

EAC.runPeriodically(300, function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    if not lastSavedPos then lastSavedPos = coords end
    local gFound, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, 99999.0, false)

    if EAC.isModuleEnabled(DetectionType.UNDER_MAP) then
        if groundZ < 1000 then
            local vel = GetEntityVelocity(ped)
            local h   = GetEntityHeightAboveGround(ped)
            if h < 1000 and coords.z < groundZ and h == coords.z and vel.z < 0 then
                if invisDetections < 5 then
                    SetEntityCoords(ped, coords.x, coords.y, groundZ)
                    lastUnderMapCheck = GetGameTimer()
                end
                invisDetections = invisDetections + 1
            else
                invisDetections = 0
                lastSavedVel = coords
            end
        end
    end

    if EAC.isModuleEnabled(DetectionType.NOCLIP) then
        local pedH = GetEntityHeightAboveGround(ped)
        local ignore = false
        if lastCoords then
            if #(lastCoords - coords) > 150.0 then
                noClipDetections = 0
                lastNoClipTime = GetGameTimer()
            end
        end
        if GetGameTimer() - lastNoClipTime < 6000 then ignore = true end

        if not ignore and EAC.lastPosition and coords ~= EAC.lastPosition
           and pedH > 3.0 and IsPedOnFoot(ped) and not IsPedJumpingOutOfVehicle(ped)
           and not IsPedClimbing(ped) and not IsPedRagdoll(ped)
           and not IsPedSwimming(ped) and GetGameTimer() - lastUnderMapCheck > 5000 then
            local pState = GetPedParachuteState()
            if not IsPedJumping(ped) and not IsPedOnVehicle(ped)
               and pState ~= 2 and pState ~= 1 then
                if #teleportPositions >= 5 then table.remove(teleportPositions, 5) end
                table.insert(teleportPositions, 1, coords)
                if #teleportPositions >= 5 then
                    local lastH, asc, totalD, prevP, sameH = -9999.9, 0, 0, nil, 0
                    for i = #teleportPositions, 1, -1 do
                        local p = teleportPositions[i]
                        if prevP then totalD = totalD + #(p - prevP) end
                        prevP = p
                        if p.z > lastH + 0.05 then lastH = p.z; asc = asc + 1 end
                        if p.z == lastH then sameH = sameH + 1 end
                        lastH = p.z
                        if (asc >= 3 and totalD > 4.0 and pedH > 2.0)
                           or (sameH >= 3 and pedH >= 10.0 and coords.z > 0.0) then
                            noClipDetections = noClipDetections + 1
                            teleportPositions = {}
                            if groundZ < 1000 then SetEntityCoords(ped, coords.x, coords.y, groundZ) end
                            if noClipDetections >= 2 then
                                noClipDetections = 0
                                EAC.punish(DetectionType.NOCLIP, "Noclip detected")
                            end
                            break
                        end
                    end
                end
            end
        else
            teleportPositions = {}
        end
        lastCoords = coords
    end

    lastSavedPos = coords
end, "AntiNoclip")
