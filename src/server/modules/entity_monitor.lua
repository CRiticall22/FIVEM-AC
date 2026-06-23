local vehicleTracker = {}
local pedTracker     = {}
local objectTracker  = {}

AddEventHandler("entityCreating", function(entity)
    if not EACS.active then return end

    local entityType = GetEntityType(entity)
    local owner      = NetworkGetFirstEntityOwner(entity)
    local popType    = GetEntityPopulationType(entity)
    local model      = GetEntityModel(entity)

    if not entityType or not model then
        CancelEvent()
        return
    end

    if popType ~= 7 and popType ~= 0 then return end

    local blVehicles = EACS.getBlacklistedVehicles()
    local pedWL      = EACS.getPedWhitelistModels()
    local objWL      = EACS.getObjectWhitelistModels()

    if Config.Modules.antiPed.enabled and entityType == 1 then
        if not pedWL[model] then
            CancelEvent()
            PunishPlayer(owner, DetectionType.PED, "Spawned ped: " .. model)
            return
        end
        if not pedTracker[owner] then
            pedTracker[owner] = { time = os.time(), count = 0 }
        end
        if os.time() - pedTracker[owner].time >= 60 then
            pedTracker[owner] = { time = os.time(), count = 0 }
        end
        pedTracker[owner].count = pedTracker[owner].count + 1
        pedTracker[owner].time  = os.time()
        if pedTracker[owner].count >= Config.Modules.antiPed.max then
            CancelEvent()
            PunishPlayer(owner, DetectionType.PED, "Ped spam: " .. pedTracker[owner].count)
        end
    end

    if Config.Modules.antiVehicle.enabled and entityType == 2 then
        if blVehicles[model] then
            CancelEvent()
            PunishPlayer(owner, DetectionType.VEHICLE, "Spawned blacklisted vehicle: " .. model)
            return
        end
        if not vehicleTracker[owner] then
            vehicleTracker[owner] = { time = os.time(), count = 0 }
        end
        if os.time() - vehicleTracker[owner].time >= 30 then
            vehicleTracker[owner] = { time = os.time(), count = 0 }
        end
        vehicleTracker[owner].count = vehicleTracker[owner].count + 1
        vehicleTracker[owner].time  = os.time()
        if vehicleTracker[owner].count >= Config.Modules.antiVehicle.max then
            CancelEvent()
            PunishPlayer(owner, DetectionType.VEHICLE, "Vehicle spam: " .. vehicleTracker[owner].count)
        end
    end

    if Config.Modules.antiObject.enabled and entityType == 3 and popType == 7 then
        if not objWL[model] then
            CancelEvent()
            PunishPlayer(owner, DetectionType.OBJECT, "Spawned object: " .. model)
            return
        end
        if not objectTracker[owner] then
            objectTracker[owner] = { time = os.time(), count = 0 }
        end
        if os.time() - objectTracker[owner].time >= 30 then
            objectTracker[owner] = { time = os.time(), count = 0 }
        end
        objectTracker[owner].count = objectTracker[owner].count + 1
        objectTracker[owner].time  = os.time()
        if objectTracker[owner].count >= Config.Modules.antiObject.max then
            CancelEvent()
            PunishPlayer(owner, DetectionType.OBJECT, "Object spam: " .. objectTracker[owner].count)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(10000)
        if not EACS.active then goto continue end

        local pedWL = EACS.getPedWhitelistModels()
        local blVeh = EACS.getBlacklistedVehicles()

        if Config.Modules.antiPed.enabled then
            for _, ped in pairs(GetAllPeds()) do
                local pop = GetEntityPopulationType(ped)
                if pop == 0 or pop == 7 then
                    local model = GetEntityModel(ped)
                    if not pedWL[model] then
                        if DoesEntityExist(ped) then
                            local owner = NetworkGetFirstEntityOwner(ped)
                            DeleteEntity(ped)
                            PunishPlayer(owner, DetectionType.PED, "Spawned ped: " .. model)
                        end
                    end
                end
            end
        end
        Wait(0)

        if Config.Modules.antiVehicle.enabled then
            for _, veh in pairs(GetAllVehicles()) do
                local pop = GetEntityPopulationType(veh)
                if pop == 0 or pop == 7 then
                    local model = GetEntityModel(veh)
                    if blVeh[model] then
                        if DoesEntityExist(veh) then
                            local owner = NetworkGetFirstEntityOwner(veh)
                            DeleteEntity(veh)
                            PunishPlayer(owner, DetectionType.VEHICLE, "Spawned blacklisted vehicle: " .. model)
                        end
                    end
                end
            end
        end

        ::continue::
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    vehicleTracker[src]  = nil
    pedTracker[src]      = nil
    objectTracker[src]   = nil
end)
