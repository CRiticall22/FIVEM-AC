AC.runPeriodically(10000, function()
    if not AC.isModuleEnabled(DetectionType.INJECTOR) then return end
    if GetGlobalCharBuffer() == nil then
        AC.punish(DetectionType.INJECTOR, "Lua injector detected")
    end
end, "AntiInjectorLong")

AC.runPeriodically(2500, function()
    if not AC.isModuleEnabled(DetectionType.INJECTOR) then return end
    if GetNumResourceMetadata("_cfx_internal", "client_script") > 0 then
        AC.punish(DetectionType.INJECTOR, "Code injection detected")
    end
    for _, entity in pairs(GetGamePool(EntityPool.VEHICLE)) do
        local script = GetEntityScript(entity)
        if script == "scr_2" or script == "scr_3" then
            local owner = NetworkGetEntityOwner(entity)
            local ownerId = GetPlayerServerId(owner)
            local myId = GetPlayerServerId(AC.playerId)
            if owner == -1 or ownerId == myId then
                AC.punish(DetectionType.INJECTOR, "Injected vehicle spawn via " .. script)
            end
            SetEntityAsMissionEntity(entity, true, true)
            DeleteVehicle(entity)
        end
    end
end, "AntiInjector")

RegisterNetEvent(GetCurrentResourceName() .. ".verify")
AddEventHandler(GetCurrentResourceName() .. ".verify", function()
    AC.waitForConfig()
    if AC.isModuleEnabled(DetectionType.INJECTOR) then
        AC.punish(DetectionType.INJECTOR, "Injector verify event fired")
    end
end)

for _, ev in ipairs({
    "antilynx8:crashuser", "shilling=yet5", "antilynxr4:crashuser",
    "shilling=yet7", "antilynxr4:crashuser1", "HCheat:TempDisableDetection",
}) do
    RegisterNetEvent(ev)
end
