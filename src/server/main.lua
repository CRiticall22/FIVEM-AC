ACS = ACS or {}

ACS.active = false
ACS.connectedPlayers = {}
ACS.playerLicenses = {}
ACS.isolationBucket = math.random(1200, 1300)
ACS.eventHandlers = {}

local whitelistedPeds = {}
local blacklistedWeapons = {}
local blacklistedVehicles = {}
local pedWhitelistModels = {}
local objectWhitelistModels = { [2116969379] = true, [1336576410] = true, [148511758] = true }

SetRoutingBucketEntityLockdownMode(ACS.isolationBucket, "strict")

function ACS.addHandler(handler)
    ACS.eventHandlers[#ACS.eventHandlers + 1] = handler
end

function ACS.clearHandlers()
    for _, h in pairs(ACS.eventHandlers) do
        RemoveEventHandler(h)
    end
    ACS.eventHandlers = {}
end

function ACS.loadConfigTables()
    for _, model in ipairs(Config.Modules.antiVehicle.blacklist or {}) do
        blacklistedVehicles[joaat(model)] = true
    end
    for _, model in ipairs(Config.Modules.antiObject.whitelist or {}) do
        objectWhitelistModels[joaat(model)] = true
    end
    for _, model in ipairs(Config.Modules.antiPed.whitelist or {}) do
        pedWhitelistModels[joaat(model)] = true
        whitelistedPeds[joaat(model)] = true
    end
    for _, model in ipairs(Config.Modules.antiWeapon.blacklist or {}) do
        blacklistedWeapons[joaat(model)] = true
    end
end

function ACS.getClientConfig()
    return {
        modules = Config.Modules,
        blacklistedWeapons = blacklistedWeapons,
        whitelistedPeds = whitelistedPeds,
    }
end

function ACS.getBlacklistedVehicles() return blacklistedVehicles end
function ACS.getPedWhitelistModels() return pedWhitelistModels end
function ACS.getObjectWhitelistModels() return objectWhitelistModels end
function ACS.getWhitelistedPeds() return whitelistedPeds end
function ACS.getBlacklistedWeapons() return blacklistedWeapons end

RegisterNetEvent(EncodeEvent("AC:punishFromClient"))
RegisterNetEvent(EncodeEvent("AC:checkJumping"))
RegisterNetEvent(EncodeEvent("AC:requestInit"))
RegisterNetEvent(EncodeEvent("AC:pong"))
RegisterNetEvent(EncodeEvent("AC:error"))
RegisterNetEvent(EncodeEvent("AC:peerInit"))
RegisterNetEvent(EncodeEvent("AC:screenshotDone"))
RegisterNetEvent(EncodeEvent("AC:getNuiData"))
RegisterNetEvent(EncodeEvent("AC:nuiEvent"))
RegisterNetEvent(EncodeEvent("AC:heartbeat"))
RegisterNetEvent(EncodeEvent("AC:heartbeatChallenge"))
RegisterNetEvent(EncodeEvent("AC:getPlayers"))
RegisterNetEvent(EncodeEvent("AC:getBans"))
RegisterNetEvent(EncodeEvent("AC:unbanFromNui"))
RegisterNetEvent(EncodeEvent("AC:kickFromNui"))
RegisterNetEvent(EncodeEvent("AC:banFromNui"))

AddEventHandler(EncodeEvent("AC:error"), function(msg, mod)
    if msg then
        Log("ERROR", ("[Client] [%s] %s"):format(mod or "?", msg))
    end
end)

AddEventHandler(EncodeEvent("AC:requestInit"), function()
    local src = source
    local perms = {
        AdminMenu   = not (not HasAdminPermission(src)),
        Whitelisted = IsPlayerWhitelisted(src),
    }
    TriggerClientEvent(EncodeEvent("AC:setPermissions"), src, perms, Config.Debug)
    TriggerClientEvent(EncodeEvent("AC:setConfig"), src, ACS.getClientConfig())
    TriggerClientEvent(EncodeEvent("AC:setActive"), src, ACS.active)
    ACS.connectedPlayers[src] = true
end)

local playerPeers = {}

AddEventHandler(EncodeEvent("AC:peerInit"), function(peerId)
    local src = source
    playerPeers[src] = peerId
end)

AddEventHandler(EncodeEvent("AC:screenshotDone"), function(id, url)
    Log("DEBUG", "Screenshot " .. tostring(id) .. " done: " .. tostring(url))
end)

AddEventHandler(EncodeEvent("AC:getNuiData"), function()
    local src = source
    local count = 0
    for _ in pairs(ACS.connectedPlayers) do count = count + 1 end
    local bans = GetAllBans()
    TriggerClientEvent(EncodeEvent("AC:setNuiData"), src, {
        routingBucket = GetPlayerRoutingBucket(src),
        players       = count,
        totalBans     = #bans,
    })
end)

RegisterNetEvent(EncodeEvent("AC:getPlayers"))
AddEventHandler(EncodeEvent("AC:getPlayers"), function()
    local src = source
    if not HasAdminPermission(src) then return end
    local list = {}
    for pid, _ in pairs(ACS.connectedPlayers) do
        local name = GetPlayerName(pid)
        if name then
            list[#list + 1] = { id = pid, name = name }
        end
    end
    TriggerClientEvent(EncodeEvent("AC:playerList"), src, list)
end)

RegisterNetEvent(EncodeEvent("AC:getBans"))
AddEventHandler(EncodeEvent("AC:getBans"), function()
    local src = source
    if not HasAdminPermission(src) then return end
    local bans = GetAllBans()
    TriggerClientEvent(EncodeEvent("AC:banList"), src, bans)
end)

RegisterNetEvent(EncodeEvent("AC:unbanFromNui"))
AddEventHandler(EncodeEvent("AC:unbanFromNui"), function(banId)
    local src = source
    if not HasAdminPermission(src) then return end
    RemoveBan(banId)
    Log("INFO", ("Unbanned %s via admin panel by %s"):format(banId, GetPlayerName(src)))
    local bans = GetAllBans()
    TriggerClientEvent(EncodeEvent("AC:banList"), src, bans)
end)

RegisterNetEvent(EncodeEvent("AC:kickFromNui"))
AddEventHandler(EncodeEvent("AC:kickFromNui"), function(targetId)
    local src = source
    if not HasAdminPermission(src) then return end
    KickPlayer(targetId, "Admin kick", "Kicked via panel by " .. (GetPlayerName(src) or "?"))
end)

RegisterNetEvent(EncodeEvent("AC:banFromNui"))
AddEventHandler(EncodeEvent("AC:banFromNui"), function(targetId)
    local src = source
    if not HasAdminPermission(src) then return end
    BanPlayer(targetId, "Admin ban", "Banned via panel by " .. (GetPlayerName(src) or "?"))
end)

RegisterNetEvent("Anticheat:openMenu", function()
    local src = source
    if HasAdminPermission(src) then
        TriggerClientEvent("Anticheat:setMenuOpen", src, true)
    end
end)

AddEventHandler(EncodeEvent("AC:nuiEvent"), function(data)
    local src = source
    if not HasAdminPermission(src) then return end

    if data.type == "deleteVehicles" then
        for _, v in pairs(GetAllVehicles()) do DeleteEntity(v) end
    elseif data.type == "deletePeds" then
        for _, p in pairs(GetAllPeds()) do DeleteEntity(p) end
    elseif data.type == "deleteObjects" then
        for _, o in pairs(GetAllObjects()) do DeleteEntity(o) end
    elseif data.type == "setRoutingBucket" then
        SetPlayerRoutingBucket(src, data.value)
    end
end)

local originalNetworkedSounds = GetConvar("sv_enableNetworkedSounds", "false")
local originalRequestControl  = GetConvar("sv_filterRequestControl", "4")
local originalPhoneExplosions = GetConvar("sv_enableNetworkedPhoneExplosions", "false")

function ACS.activate()
    if ACS.active then return end
    ACS.active = true
    Log("INFO", "Anticheat activated")
    ACS.loadConfigTables()
    ACS.clearHandlers()

    TriggerClientEvent(EncodeEvent("AC:setActive"), -1, true)

    if Config.Modules.antiNetworkedSounds.enabled then
        SetConvar("sv_enableNetworkedSounds", "false")
    end
    if Config.Modules.antiEntityTakeover.enabled then
        SetConvar("sv_filterRequestControl", "4")
    end
    if Config.Modules.antiPhoneExplosions.enabled then
        SetConvar("sv_enableNetworkedPhoneExplosions", "false")
    end
end

function ACS.deactivate()
    if not ACS.active then return end
    ACS.active = false
    Log("INFO", "Anticheat deactivated")

    SetConvar("sv_enableNetworkedSounds", originalNetworkedSounds)
    SetConvar("sv_filterRequestControl", originalRequestControl)
    SetConvar("sv_enableNetworkedPhoneExplosions", originalPhoneExplosions)

    TriggerClientEvent(EncodeEvent("AC:setActive"), -1, false)
    ACS.clearHandlers()
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        ACS.deactivate()
    end
end)

Citizen.CreateThread(function()
    Log("INFO", ("v%s starting..."):format(Config.Branding.Version))
    Wait(2000)
    ACS.activate()
end)
