EAC = EAC or {}

EAC.active = false
EAC.config = nil
EAC.playerId = PlayerId()
EAC.perms = {}
EAC.debugMode = false
EAC.spawned = false
EAC.initialized = false
EAC.lastPosition = nil

EAC.whitelistedWeapons = { [joaat("WEAPON_STUNGUN")] = true }
EAC.whitelistedPeds = {}
EAC.blacklistedWeapons = {}

local modules = {}
local eventHandlers = {}
local stateBagHandler

function EAC.addHandler(h)
    eventHandlers[#eventHandlers + 1] = h
end

local function clearHandlers()
    for _, h in pairs(eventHandlers) do RemoveEventHandler(h) end
    eventHandlers = {}
end

function EAC.waitForConfig()
    while not EAC.config do Wait(100) end
end

function EAC.runSafely(fn, name)
    Citizen.CreateThread(function()
        local ok, err = pcall(fn)
        if not ok and err then
            TriggerServerEvent(EncodeEvent("AC:error"), err, name)
        end
    end)
end

function EAC.runPeriodically(interval, fn, name)
    EAC.runSafely(function()
        EAC.waitForConfig()
        while true do
            if EAC.active and not EAC.perms.Whitelisted then
                fn()
            end
            Wait(interval)
        end
    end, name)
end

function EAC.punish(module, reason)
    if EAC.perms.Whitelisted then return end
    TriggerServerEvent(EncodeEvent("AC:punishFromClient"), module, reason)
    EAC.waitForConfig()
    local mod = EAC.config.modules[module]
    if mod and (mod.punishment == PunishAction.BAN or mod.punishment == PunishAction.KICK) then
        EAC.deleteOwnedEntities()
    end
end

function EAC.getModuleConfig(name)
    return EAC.config and EAC.config.modules and EAC.config.modules[name]
end

function EAC.isModuleEnabled(name)
    local cfg = EAC.getModuleConfig(name)
    return cfg and cfg.enabled
end

function EAC.deleteOwnedEntities()
    local myId = GetPlayerServerId(EAC.playerId)
    for _, e in pairs(GetGamePool(EntityPool.PED)) do
        if GetPlayerServerId(NetworkGetEntityOwner(e)) == myId then DeletePed(e) end
    end
    for _, e in pairs(GetGamePool(EntityPool.OBJECT)) do
        if GetPlayerServerId(NetworkGetEntityOwner(e)) == myId then DeleteObject(e) end
    end
    for _, e in pairs(GetGamePool(EntityPool.VEHICLE)) do
        if GetPlayerServerId(NetworkGetEntityOwner(e)) == myId then
            SetEntityAsMissionEntity(e, true, true)
            DeleteVehicle(e)
        end
    end
end

function EAC.quitGame() ForceSocialClubUpdate() end

function EAC.dirFromRot(rot)
    local r = { x = math.rad(rot.x), y = math.rad(rot.y), z = math.rad(rot.z) }
    return {
        x = -math.sin(r.z) * math.abs(math.cos(r.x)),
        y =  math.cos(r.z) * math.abs(math.cos(r.x)),
        z =  math.sin(r.x),
    }
end

function EAC.raycastMat(dist)
    local rot = GetGameplayCamRot()
    local pos = GetGameplayCamCoord()
    local dir = EAC.dirFromRot(rot)
    local dst = vector3(pos.x + dir.x * dist, pos.y + dir.y * dist, pos.z + dir.z * dist)
    local _, hit, endC, _, matHash, ent =
        GetShapeTestResultIncludingMaterial(
            StartShapeTestRay(pos.x, pos.y, pos.z, dst.x, dst.y, dst.z, -1, -1, 1))
    local d = endC and #(pos - endC) or nil
    return hit, endC, ent, matHash, d
end

function EAC.raycastSimple(dist)
    local rot = GetGameplayCamRot()
    local pos = GetGameplayCamCoord()
    local dir = EAC.dirFromRot(rot)
    local dst = vector3(pos.x + dir.x * dist, pos.y + dir.y * dist, pos.z + dir.z * dist)
    local _, hit, endC, _, ent =
        GetShapeTestResult(
            StartShapeTestRay(pos.x, pos.y, pos.z, dst.x, dst.y, dst.z, -1, -1, 1))
    local d = endC and #(pos - endC) or nil
    return hit, endC, ent, d
end

function EAC.registerModule(name, callbacks)
    modules[name] = callbacks
end

local function activateModules()
    for name, mod in pairs(modules) do
        if mod.activate then
            EAC.runSafely(function() mod.activate() end, "Mod:" .. name)
        end
    end
end

local function deactivateModules()
    for name, mod in pairs(modules) do
        if mod.deactivate then
            EAC.runSafely(function() mod.deactivate() end, "Mod:" .. name)
        end
    end
end

RegisterNetEvent(EncodeEvent("AC:setActive"), function(active)
    EAC.active = active
    if active then
        clearHandlers()
        EAC.waitForConfig()
        activateModules()
    else
        deactivateModules()
        clearHandlers()
    end
end)

Citizen.CreateThread(function()
    TriggerServerEvent(EncodeEvent("AC:requestInit"))
end)

RegisterNetEvent(EncodeEvent("AC:setConfig"), function(cfg)
    for _, m in ipairs(cfg.whitelistedPeds or {}) do EAC.whitelistedPeds[m] = true end
    for h, _ in pairs(cfg.blacklistedWeapons or {}) do EAC.blacklistedWeapons[h] = true end
    EAC.config = cfg
end)

RegisterNetEvent(EncodeEvent("AC:setPermissions"), function(perms, isDebug)
    EAC.perms = perms
    EAC.debugMode = isDebug
end)

RegisterNetEvent(EncodeEvent("AC:ping"), function()
    TriggerServerEvent(EncodeEvent("AC:pong"))
end)

EAC.runSafely(function()
    while not NetworkIsPlayerActive(EAC.playerId) do Wait(100) end
    EAC.initialized = true
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    while coords.x == 0.0 or coords.y == 0.0 do
        ped = PlayerPedId(); coords = GetEntityCoords(ped); Wait(0)
    end
    Wait(0)
    local cam = GetFinalRenderedCamCoord()
    while #(cam - coords) > 50.0 do
        cam = GetFinalRenderedCamCoord()
        ped = PlayerPedId(); coords = GetEntityCoords(ped); Wait(0)
    end
    EAC.lastPosition = GetEntityCoords(PlayerPedId())
    EAC.spawned = true
end, "SpawnChecker")
