local resourceName = GetCurrentResourceName()
local fileHashes = {}
local CHECK_INTERVAL = 60000

local CRITICAL_FILES = {
    "fxmanifest.lua",
    "config.lua",
    "src/shared/utils.lua",
    "src/shared/enums.lua",
    "src/client/main.lua",
    "src/client/heartbeat.lua",
    "src/client/nui_bridge.lua",
    "src/server/main.lua",
    "src/server/punishment.lua",
    "src/server/heartbeat.lua",
    "src/server/permissions.lua",
}

local function simpleHash(str)
    if not str then return nil end
    local h = 5381
    for i = 1, #str do
        h = ((h * 33) + string.byte(str, i)) % 4294967296
    end
    return h
end

local function snapshotFiles()
    for _, file in ipairs(CRITICAL_FILES) do
        local content = LoadResourceFile(resourceName, file)
        if content then
            fileHashes[file] = simpleHash(content)
        end
    end
    Log("INFO", ("[TAMPER_WATCH] Hashed %d critical files"):format(#CRITICAL_FILES))
end

local function checkIntegrity()
    local cfg = Config.Modules.resourceTamper
    if not cfg or not cfg.enabled then return end

    for _, file in ipairs(CRITICAL_FILES) do
        local content = LoadResourceFile(resourceName, file)
        if not content then
            if fileHashes[file] then
                Log("ERROR", ("[TAMPER_WATCH] Critical file DELETED: %s"):format(file))
                alertAdmins("CRITICAL: File deleted — " .. file)
            end
        else
            local currentHash = simpleHash(content)
            if fileHashes[file] and currentHash ~= fileHashes[file] then
                Log("ERROR", ("[TAMPER_WATCH] File MODIFIED at runtime: %s (hash %d -> %d)"):format(file, fileHashes[file], currentHash))
                alertAdmins("CRITICAL: File tampered — " .. file)
                fileHashes[file] = currentHash
            end
        end
    end
end

local function alertAdmins(msg)
    for adminPid, _ in pairs(ACS.connectedPlayers) do
        if IsPlayerAceAllowed(tostring(adminPid), Config.Branding.AcePerm) then
            TriggerClientEvent(EncodeEvent("AC:detectionNotify"), adminPid, {
                player = "SYSTEM",
                reason = msg,
                type = "BAN",
            })
        end
    end
end

Citizen.CreateThread(function()
    Wait(5000)
    snapshotFiles()

    while true do
        Wait(CHECK_INTERVAL)
        if ACS and ACS.active then
            checkIntegrity()
        end
    end
end)
