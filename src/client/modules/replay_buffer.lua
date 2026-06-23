local BUFFER_SECONDS = 30
local SAMPLE_RATE = 250
local MAX_SAMPLES = math.floor((BUFFER_SECONDS * 1000) / SAMPLE_RATE)

local buffer = {}
local head = 0

local function captureFrame()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    head = (head % MAX_SAMPLES) + 1

    local pos = GetEntityCoords(ped)
    local vel = GetEntityVelocity(ped)
    local health = GetEntityHealth(ped)
    local armor = GetPedArmour(ped)
    local weapon = GetSelectedPedWeapon(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    local vehSpeed = veh ~= 0 and GetEntitySpeed(veh) or 0.0

    local camRot = GetGameplayCamRot(2)

    buffer[head] = {
        t = GetGameTimer(),
        x = pos.x, y = pos.y, z = pos.z,
        vx = vel.x, vy = vel.y, vz = vel.z,
        hp = health, ar = armor,
        wpn = weapon,
        spd = vehSpeed,
        cx = camRot.x, cy = camRot.y, cz = camRot.z,
        inv = GetPlayerInvincible(PlayerId()),
    }
end

local function getReplayData()
    local ordered = {}
    local count = #buffer
    if count == 0 then return ordered end

    local start = (head % count) + 1
    for i = 0, count - 1 do
        local idx = ((start + i - 1) % count) + 1
        if buffer[idx] then
            ordered[#ordered + 1] = buffer[idx]
        end
    end
    return ordered
end

AC.registerModule("replayBuffer", {
    activate = function()
        AC.runPeriodically(SAMPLE_RATE, captureFrame, "ReplayBuffer")
    end,
    deactivate = function()
        buffer = {}
        head = 0
    end,
})

RegisterNetEvent(EncodeEvent("AC:requestReplay"), function()
    local data = getReplayData()
    TriggerServerEvent(EncodeEvent("AC:replayData"), data)
end)
