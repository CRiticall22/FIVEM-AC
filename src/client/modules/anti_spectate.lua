EAC.runPeriodically(1000, function()
    if not EAC.isModuleEnabled(DetectionType.SPECTATE) then return end
    if NetworkIsInSpectatorMode() then
        EAC.punish(DetectionType.SPECTATE, "Spectating")
    end
end, "AntiSpectate")
