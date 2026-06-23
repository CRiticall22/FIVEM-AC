local tazerCounts = {}
local clearTaskCounts = {}

AddEventHandler("weaponDamageEvent", function(src, data)
    if not ACS.active then return end

    if Config.Modules.antiMenu.enabled then
        if data.silenced and data.weaponDamage == 0 and
           (data.weaponType == 2725352035 or data.weaponType == 3452007600) then
            PunishPlayer(src, DetectionType.MENU, "Menu script weapon signature detected")
        end
    end

    if Config.Modules.antiTaze.enabled and data.weaponType == 911657153 then
        if not tazerCounts[src] then
            tazerCounts[src] = { count = 0, time = os.time() }
        end
        if os.time() - tazerCounts[src].time >= 5 then
            tazerCounts[src] = { count = 0, time = os.time() }
        end
        tazerCounts[src].count = tazerCounts[src].count + 1
        tazerCounts[src].time  = os.time()
        if tazerCounts[src].count >= Config.Modules.antiTaze.max then
            CancelEvent()
            PunishPlayer(src, DetectionType.TAZE, "Tazer spam " .. tazerCounts[src].count .. "x")
        end
    end
end)

AddEventHandler("clearPedTasksEvent", function(src)
    if not ACS.active then return end
    if not Config.Modules.antiPedTasks.enabled then return end
    if not clearTaskCounts[src] then
        clearTaskCounts[src] = { count = 0, time = os.time() }
    end
    if os.time() - clearTaskCounts[src].time >= 10 then
        clearTaskCounts[src] = { count = 0, time = os.time() }
    end
    clearTaskCounts[src].count = clearTaskCounts[src].count + 1
    clearTaskCounts[src].time  = os.time()
    if clearTaskCounts[src].count >= Config.Modules.antiPedTasks.max then
        CancelEvent()
        PunishPlayer(src, DetectionType.PED_TASKS, "Clear ped tasks spam")
    end
end)

AddEventHandler(EncodeEvent("AC:checkJumping"), function()
    local src = source
    if not ACS.active then return end
    if IsPlayerUsingSuperJump(src) then
        PunishPlayer(src, DetectionType.SUPER_JUMP, "Server confirmed super jump")
    end
end)

AddEventHandler(EncodeEvent("AC:punishFromClient"), function(reason, details)
    if not ACS.active then return end
    PunishPlayer(source, reason, details)
end)

AddEventHandler("playerDropped", function()
    local src = source
    tazerCounts[src] = nil
    clearTaskCounts[src] = nil
end)
