AC.runPeriodically(1000, function()
    if not AC.isModuleEnabled(DetectionType.SPECTATE) then return end
    if NetworkIsInSpectatorMode() then
        AC.punish(DetectionType.SPECTATE, "Spectating")
    end
end, "AntiSpectate")
