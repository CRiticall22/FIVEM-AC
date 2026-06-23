EAC.runPeriodically(1000, function()
    if not EAC.isModuleEnabled(DetectionType.SUPER_JUMP) then return end
    local ped = PlayerPedId()
    if IsPedJumping(ped) then
        TriggerServerEvent(EncodeEvent("AC:checkJumping"))
    end
    if IsPedDoingBeastJump(ped) then
        EAC.punish(DetectionType.SUPER_JUMP, "Super jump")
    end
end, "AntiSuperJump")
