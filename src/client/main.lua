AC = AC or {}

AC.active = false
AC.config = nil
AC.playerId = PlayerId()
AC.perms = {}
AC.debugMode = false
AC.spawned = false
AC.initialized = false
AC.lastPosition = nil

AC.whitelistedWeapons = { [joaat("WEAPON_STUNGUN")] = true }
AC.whitelistedPeds = {}
AC.blacklistedWeapons = {}

local modules = {}
local eventHandlers = {}
local stateBagHandler

function AC.addHandler(h)
    eventHandlers[#eventHandlers + 1] = h
end

local function clearHandlers()
    for _, h in pairs(eventHandlers) do RemoveEventHandler(h) end
    eventHandlers = {}
end

function AC.waitForConfig()
    while not AC.config do Wait(100) end
end

function AC.runSafely(fn, name)
    Citizen.CreateThread(function()
        local ok, err = pcall(fn)
        if not ok and err then
            TriggerServerEvent(EncodeEvent("AC:error"), err, name)
        end
    end)
end

function AC.runPeriodically(interval, fn, name)
    AC.runSafely(function()
        AC.waitForConfig()
        while true do
            if AC.active and not AC.perms.Whitelisted then
                fn()
            end
            Wait(interval)
        end
    end, name)
end

function AC.punish(module, reason)
    if AC.perms.Whitelisted then return end
    TriggerServerEvent(EncodeEvent("AC:punishFromClient"), module, reason)
    AC.waitForConfig()
    local mod = AC.config.modules[module]
    if mod and (mod.punishment == PunishAction.BAN or mod.punishment == PunishAction.KICK) then
        AC.deleteOwnedEntities()
    end
end

function AC.getModuleConfig(name)
    return AC.config and AC.config.modules and AC.config.modules[name]
end

function AC.isModuleEnabled(name)
    local cfg = AC.getModuleConfig(name)
    return cfg and cfg.enabled
end

function AC.deleteOwnedEntities()
    local myId = GetPlayerServerId(AC.playerId)
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

function AC.quitGame() ForceSocialClubUpdate() end

function AC.dirFromRot(rot)
    local r = { x = math.rad(rot.x), y = math.rad(rot.y), z = math.rad(rot.z) }
    return {
        x = -math.sin(r.z) * math.abs(math.cos(r.x)),
        y =  math.cos(r.z) * math.abs(math.cos(r.x)),
        z =  math.sin(r.x),
    }
end

function AC.raycastMat(dist)
    local rot = GetGameplayCamRot()
    local pos = GetGameplayCamCoord()
    local dir = AC.dirFromRot(rot)
    local dst = vector3(pos.x + dir.x * dist, pos.y + dir.y * dist, pos.z + dir.z * dist)
    local _, hit, endC, _, matHash, ent =
        GetShapeTestResultIncludingMaterial(
            StartShapeTestRay(pos.x, pos.y, pos.z, dst.x, dst.y, dst.z, -1, -1, 1))
    local d = endC and #(pos - endC) or nil
    return hit, endC, ent, matHash, d
end

function AC.raycastSimple(dist)
    local rot = GetGameplayCamRot()
    local pos = GetGameplayCamCoord()
    local dir = AC.dirFromRot(rot)
    local dst = vector3(pos.x + dir.x * dist, pos.y + dir.y * dist, pos.z + dir.z * dist)
    local _, hit, endC, _, ent =
        GetShapeTestResult(
            StartShapeTestRay(pos.x, pos.y, pos.z, dst.x, dst.y, dst.z, -1, -1, 1))
    local d = endC and #(pos - endC) or nil
    return hit, endC, ent, d
end

function AC.registerModule(name, callbacks)
    modules[name] = callbacks
end

local function activateModules()
    for name, mod in pairs(modules) do
        if mod.activate then
            AC.runSafely(function() mod.activate() end, "Mod:" .. name)
        end
    end
end

local function deactivateModules()
    for name, mod in pairs(modules) do
        if mod.deactivate then
            AC.runSafely(function() mod.deactivate() end, "Mod:" .. name)
        end
    end
end

RegisterNetEvent(EncodeEvent("AC:setActive"), function(active)
    AC.active = active
    if active then
        clearHandlers()
        AC.waitForConfig()
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
    for _, m in ipairs(cfg.whitelistedPeds or {}) do AC.whitelistedPeds[m] = true end
    for h, _ in pairs(cfg.blacklistedWeapons or {}) do AC.blacklistedWeapons[h] = true end
    AC.config = cfg
end)

RegisterNetEvent(EncodeEvent("AC:setPermissions"), function(perms, isDebug)
    AC.perms = perms
    AC.debugMode = isDebug
end)

RegisterNetEvent(EncodeEvent("AC:ping"), function()
    TriggerServerEvent(EncodeEvent("AC:pong"))
end)

AC.runSafely(function()
    while not NetworkIsPlayerActive(AC.playerId) do Wait(100) end
    AC.initialized = true
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
    AC.lastPosition = GetEntityCoords(PlayerPedId())
    AC.spawned = true
end, "SpawnChecker")
