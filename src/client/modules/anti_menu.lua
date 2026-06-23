AC.registerModule("anti_menu", {
    activate = function()
        AC.waitForConfig()
        if not AC.isModuleEnabled(DetectionType.MENU) then return end

        local trapEvents = {
            "antilynx8:crashuser", "shilling=yet5", "antilynxr4:crashuser",
            "shilling=yet7", "antilynxr4:crashuser1", "HCheat:TempDisableDetection",
        }
        for _, ev in ipairs(trapEvents) do
            RegisterNetEvent(ev)
            AC.addHandler(AddEventHandler(ev, function()
                AC.waitForConfig()
                if AC.isModuleEnabled(DetectionType.MENU) then
                    AC.punish(DetectionType.MENU, "Menu detected via trap event: " .. ev)
                end
            end))
        end

        if AC.isModuleEnabled(DetectionType.CRASHER) then
            local sbh = AddStateBagChangeHandler(nil, nil, function(_, _, value)
                AC.waitForConfig()
                if AC.isModuleEnabled(DetectionType.CRASHER) then
                    if type(value) == "string" and #value > 131072 then
                        AC.punish(DetectionType.CRASHER, "Server crash attempt via state bag")
                        AC.quitGame()
                        while true do end
                    end
                end
            end)
            AC.addHandler(function()
                RemoveStateBagChangeHandler(sbh)
            end)
        end
    end,
})

AC.runPeriodically(10000, function()
    if not AC.isModuleEnabled(DetectionType.MENU) then return end

    for _, tex in ipairs(Config.MenuTextures) do
        if tex.x and tex.y then
            local res = GetTextureResolution(tex.txd, tex.txt)
            if res.x == tex.x and res.y == tex.y then
                AC.punish(DetectionType.MENU, "Menu texture: " .. tex.name)
            end
        else
            if GetTextureResolution(tex.txd, tex.txt).x ~= 4.0 then
                AC.punish(DetectionType.MENU, "Menu texture: " .. tex.name)
            end
        end
    end

    for _, dict in ipairs(Config.BlacklistedTextureDicts) do
        if HasStreamedTextureDictLoaded(dict) then
            AC.punish(DetectionType.MENU, "Menu texture dict: " .. dict)
        end
    end
end, "AntiMenu")
