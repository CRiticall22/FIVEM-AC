RegisterNetEvent(EncodeEvent("AC:dumpChallengeRequest"), function(challenge)
    local result = (challenge * 7 + 42) % 1000000
    Wait(math.random(200, 800))
    TriggerServerEvent(EncodeEvent("AC:dumpChallenge"), result)
end)

Citizen.CreateThread(function()
    TriggerServerEvent(EncodeEvent("AC:loadStage"), "scripts_loaded")

    while not AC.config do
        Wait(500)
    end
    TriggerServerEvent(EncodeEvent("AC:loadStage"), "config_received")

    while not AC.spawned do
        Wait(500)
    end
    TriggerServerEvent(EncodeEvent("AC:loadStage"), "fully_loaded")
end)
