local honeypots = {}
local HONEYPOT_CHECK_INTERVAL = 5000
local HONEYPOT_RADIUS = 3.0

local honeypotLocations = {
    vector3(245.3, -987.2, 29.3),
    vector3(-1045.7, -2752.1, 21.3),
    vector3(1660.3, 4770.5, 42.0),
    vector3(-234.5, -766.3, 34.1),
    vector3(428.7, -979.4, 30.7),
    vector3(-1612.4, -1050.8, 13.0),
    vector3(2557.3, 382.1, 108.6),
    vector3(-1038.2, -2737.8, 20.2),
}

local function setupHoneypots()
    AC.waitForConfig()
    if not Config.Modules.antiHoneypot or not Config.Modules.antiHoneypot.enabled then return end

    for _, pos in ipairs(honeypotLocations) do
        honeypots[#honeypots + 1] = {
            pos = pos,
            triggered = false,
        }
    end
end

Citizen.CreateThread(function()
    Wait(15000)
    setupHoneypots()
end)

AC.runPeriodically(HONEYPOT_CHECK_INTERVAL, function()
    if not Config.Modules.antiHoneypot or not Config.Modules.antiHoneypot.enabled then return end
    if #honeypots == 0 then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, hp in ipairs(honeypots) do
        if not hp.triggered then
            local dist = #(coords - hp.pos)

            if dist < HONEYPOT_RADIUS then
                if not IsScreenFadedOut() and AC.spawned then
                    local _, groundZ = GetGroundZFor_3dCoord(hp.pos.x, hp.pos.y, hp.pos.z + 100.0, false)
                    local terrainDist = math.abs(coords.z - groundZ)

                    if terrainDist > 5.0 or not HasEntityClearLosToCoord(ped, hp.pos.x, hp.pos.y, hp.pos.z, 17) then
                        hp.triggered = true
                        AC.punish(DetectionType.MENU, "Honeypot triggered at hidden location (through wall/underground)")
                    end
                end
            end
        end
    end
end, "AntiHoneypot")
