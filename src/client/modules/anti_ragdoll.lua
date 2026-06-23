local ragdollDetections = 0

AC.runPeriodically(1000, function()
    local ped = PlayerPedId()

    if not AC.spawned then return end

    if GetPedConfigFlag(ped, 68, true) and not IsPedInAnyVehicle(ped)
       and not IsPedRagdoll(ped) and not IsEntityDead(ped) then
        ragdollDetections = ragdollDetections + 1
        if ragdollDetections >= 5 then
            ragdollDetections = 0
            AC.punish(DetectionType.GODMODE, "Anti-ragdoll detected")
        end
    else
        ragdollDetections = math.max(0, ragdollDetections - 1)
    end

    if IsPedUsingActionMode(ped) and not IsPedArmed(ped, 6) and not IsPedInAnyVehicle(ped) then
        SetPedUsingActionMode(ped, false, -1, 0)
    end
end, "AntiRagdoll")
