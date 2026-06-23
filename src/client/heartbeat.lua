local HEARTBEAT_INTERVAL = 15000
local lastHeartbeat = 0
local heartbeatToken = nil

RegisterNetEvent(EncodeEvent("AC:heartbeatChallenge"), function(token)
    heartbeatToken = token
end)

Citizen.CreateThread(function()
    while true do
        Wait(HEARTBEAT_INTERVAL)
        if EAC.active and EAC.spawned then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local health = GetEntityHealth(ped)
            local vehicle = GetVehiclePedIsUsing(ped)

            TriggerServerEvent(EncodeEvent("AC:heartbeat"), {
                token   = heartbeatToken,
                coords  = { x = coords.x, y = coords.y, z = coords.z },
                health  = health,
                armor   = GetPedArmour(ped),
                vehicle = vehicle ~= 0 and vehicle or nil,
                weapon  = GetSelectedPedWeapon(ped),
                time    = GetGameTimer(),
            })
            lastHeartbeat = GetGameTimer()
        end
    end
end)
