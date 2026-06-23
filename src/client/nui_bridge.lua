local menuOpen = false
local menuReady = false
local espActive = false

RegisterNetEvent("Anticheat:setMenuOpen", function(open)
    SendNUIMessage({ menuOpen = open })
end)

RegisterCommand("eac", function()
    if not menuReady then return end
    if menuOpen then
        SendNUIMessage({ menuOpen = false })
    else
        TriggerServerEvent("Anticheat:openMenu")
    end
end)

RegisterNuiCallback("menuOpen", function(data, cb)
    cb({})
    menuOpen = data.menuOpen
    if menuOpen then
        TriggerServerEvent(EncodeEvent("AC:getNuiData"))
    end
    SetNuiFocus(menuOpen, menuOpen)
end)

RegisterNuiCallback("menuReady", function(_, cb)
    cb({})
    menuReady = true
end)

RegisterNuiCallback("nuiEvent", function(data, cb)
    cb({})
    if data.type == "ESP" then
        if data.value then startEsp() else stopEsp() end
    end
    TriggerServerEvent(EncodeEvent("AC:nuiEvent"), data)
end)

RegisterNuiCallback("getPlayers", function(_, cb)
    cb({})
    TriggerServerEvent(EncodeEvent("AC:getPlayers"))
end)

RegisterNuiCallback("getBans", function(_, cb)
    cb({})
    TriggerServerEvent(EncodeEvent("AC:getBans"))
end)

RegisterNuiCallback("unbanPlayer", function(data, cb)
    cb({})
    if data.banId then
        TriggerServerEvent(EncodeEvent("AC:unbanFromNui"), data.banId)
    end
end)

RegisterNuiCallback("kickPlayer", function(data, cb)
    cb({})
    if data.id then
        TriggerServerEvent(EncodeEvent("AC:kickFromNui"), data.id)
    end
end)

RegisterNuiCallback("banPlayer", function(data, cb)
    cb({})
    if data.id then
        TriggerServerEvent(EncodeEvent("AC:banFromNui"), data.id)
    end
end)

RegisterNetEvent(EncodeEvent("AC:playerList"), function(list)
    SendNUIMessage({ playerList = list })
end)

RegisterNetEvent(EncodeEvent("AC:banList"), function(list)
    SendNUIMessage({ banList = list })
end)

RegisterNetEvent(EncodeEvent("AC:detectionNotify"), function(det)
    SendNUIMessage({ detection = det })
end)

RegisterNuiCallback("ready", function(_, cb)
    cb({})
    AC.waitForConfig()
    if Config.OCR.Enabled then
        SendNUIMessage({
            onScreenDetection = true,
            onScreenKeywords = Config.OCR.Blacklist,
        })
    end
end)

RegisterNuiCallback("recognitionReady", function(_, cb)
    cb({})
    AC.waitForConfig()
    if Config.OCR.Enabled then
        SendNUIMessage({
            onScreenDetection = true,
            onScreenKeywords = Config.OCR.Blacklist,
        })
    end
end)

RegisterNuiCallback("keywordDetected", function(data, cb)
    cb({})
    AC.waitForConfig()
    if Config.OCR.Enabled then
        if not IsPauseMenuActive() then
            AC.punish(DetectionType.MENU, "OCR keyword: " .. (data.word or "?"))
        end
    end
end)

RegisterNuiCallback("peerInitialized", function(data, cb)
    cb({})
    if Config.LiveView.Enabled then
        TriggerServerEvent(EncodeEvent("AC:peerInit"), data.id)
    end
end)

RegisterNuiCallback("screenshotCreated", function(data, cb)
    cb({})
    if data.data and data.data.success then
        TriggerServerEvent(EncodeEvent("AC:screenshotDone"), data.id,
            data.data.data and data.data.data.id)
    end
end)

RegisterNuiCallback("playerOffline", function(_, cb) cb({}) end)

RegisterNuiCallback("NUIDevTools", function(_, cb)
    cb({})
    AC.waitForConfig()
    if AC.isModuleEnabled(DetectionType.DEV_TOOLS) then
        AC.punish(DetectionType.DEV_TOOLS, "Opened NUI DevTools")
    end
end)

local nuiBlockerDet = 0
local isPongReceived = false

RegisterNuiCallback("pong", function(_, cb)
    cb({})
    isPongReceived = true
end)

Citizen.CreateThread(function()
    Wait(30000)
    while true do
        if AC.active and AC.config
           and AC.isModuleEnabled(DetectionType.NUI_BLOCKER) then
            isPongReceived = false
            SendNUIMessage({ type = "ping" })
            Wait(5000)
            if isPongReceived then
                nuiBlockerDet = 0
            else
                nuiBlockerDet = nuiBlockerDet + 1
                if nuiBlockerDet >= 3 then
                    AC.punish(DetectionType.NUI_BLOCKER, "NUI blocker detected")
                end
            end
        end
        Wait(3000)
    end
end)

RegisterNetEvent(EncodeEvent("AC:setNuiData"), function(data)
    if menuReady then
        SendNUIMessage({ nuiData = data })
    end
end)

function RGBRainbow(freq)
    local t = GetGameTimer() / 1000
    local amp, ctr, phase = 127, 128, 2
    return {
        r = math.floor(math.sin(t * freq) * amp + ctr),
        g = math.floor(math.sin(t * freq + phase) * amp + ctr),
        b = math.floor(math.sin(t * freq + 2 * phase) * amp + ctr),
    }
end

function startEsp()
    if espActive then return end
    espActive = true
    Citizen.CreateThread(function()
        while espActive do
            local ped = PlayerPedId()
            local c = RGBRainbow(1.0)
            local pc = GetEntityCoords(ped)
            for _, e in ipairs(GetGamePool(EntityPool.PED)) do
                local ec = GetEntityCoords(e)
                DrawLine(pc.x, pc.y, pc.z, ec.x, ec.y, ec.z, c.r, c.g, c.b, 255)
            end
            Wait(0)
        end
    end)
end

function stopEsp()
    espActive = false
end
