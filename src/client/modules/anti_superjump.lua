AC.runPeriodically(1000, function()
    if not AC.isModuleEnabled(DetectionType.SUPER_JUMP) then return end
    local ped = PlayerPedId()
    if IsPedJumping(ped) then
        TriggerServerEvent(EncodeEvent("AC:checkJumping"))
    end
    if IsPedDoingBeastJump(ped) then
        AC.punish(DetectionType.SUPER_JUMP, "Super jump")
    end
end, "AntiSuperJump")
