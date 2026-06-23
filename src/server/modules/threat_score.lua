local playerScores = {}
local DECAY_RATE = 0.5
local DECAY_INTERVAL = 60000

local scoreWeights = {
    [DetectionType.AIMBOT]       = 40,
    [DetectionType.WALL_HACK]    = 35,
    [DetectionType.GODMODE]      = 30,
    [DetectionType.NOCLIP]       = 35,
    [DetectionType.TELEPORT]     = 30,
    [DetectionType.SPEED_CHANGER]= 25,
    [DetectionType.INJECTOR]     = 50,
    [DetectionType.MENU]         = 45,
    [DetectionType.WEAPON]       = 20,
    [DetectionType.INVISIBLE]    = 25,
    [DetectionType.SPECTATE]     = 30,
    [DetectionType.SUPER_JUMP]   = 20,
    [DetectionType.CRASHER]      = 50,
    [DetectionType.AMMO]         = 20,
    [DetectionType.HEALTH]       = 25,
    [DetectionType.ARMOR]        = 20,
}

function GetThreatScore(src)
    return playerScores[src] or 0
end

function AddThreatScore(src, module, amount)
    if not playerScores[src] then playerScores[src] = 0 end

    local weight = amount or scoreWeights[module] or 10
    playerScores[src] = math.min(100, playerScores[src] + weight)

    local score = playerScores[src]
    local level = score >= 80 and "CRITICAL" or score >= 50 and "HIGH" or score >= 25 and "MEDIUM" or "LOW"

    Log("DEBUG", ("Threat score for %s: %d (%s) [+%d from %s]"):format(
        GetPlayerName(src) or src, score, level, weight, module))

    if score >= 80 and not Config.Modules.shadowMode then
        PunishPlayer(src, module, "Threat score critical: " .. score)
    end
end

Citizen.CreateThread(function()
    while true do
        Wait(DECAY_INTERVAL)
        for pid, score in pairs(playerScores) do
            if score > 0 then
                playerScores[pid] = math.max(0, score - DECAY_RATE)
            end
        end
    end
end)

AddEventHandler("playerDropped", function()
    playerScores[source] = nil
end)
