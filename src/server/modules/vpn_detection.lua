local function getPlayerIP(src)
    local ep = GetPlayerEndpoint(src)
    if not ep then return nil end
    return ep:match("([%d%.]+)")
end

local vpnCache = {}

local function checkIP(src, ip)
    if vpnCache[ip] ~= nil then
        return vpnCache[ip]
    end

    local url = ("http://ip-api.com/json/%s?fields=status,proxy,hosting,isp,org,as"):format(ip)
    PerformHttpRequest(url, function(code, body)
        if code ~= 200 or not body then
            vpnCache[ip] = false
            return
        end

        local data = json.decode(body)
        if not data or data.status ~= "success" then
            vpnCache[ip] = false
            return
        end

        local isVPN = data.proxy == true or data.hosting == true
        vpnCache[ip] = isVPN

        if isVPN then
            local cfg = Config.Modules.vpnDetection
            if not cfg or not cfg.enabled then return end

            local name = GetPlayerName(src) or "Unknown"
            Log("WARN", ("[VPN] %s (ID:%d) connected via VPN/Proxy — ISP: %s, Org: %s"):format(name, src, data.isp or "?", data.org or "?"))

            if cfg.action == "KICK" then
                DropPlayer(src, Config.Messages.Kick .. "\nVPN/Proxy connections are not allowed.")
            elseif cfg.action == "FLAG" then
                if AddThreatScore then AddThreatScore(src, "vpnDetected", 30) end
                for adminPid, _ in pairs(ACS.connectedPlayers) do
                    if IsPlayerAceAllowed(tostring(adminPid), Config.Whitelist.AcePerm) then
                        TriggerClientEvent(EncodeEvent("AC:detectionNotify"), adminPid, {
                            player = name,
                            reason = "VPN/Proxy detected — ISP: " .. (data.isp or "?"),
                            type = "WARN",
                        })
                    end
                end
            end
        end
    end, "GET")
end

AddEventHandler("playerConnecting", function(name, _, deferrals)
    local src = source
    local cfg = Config.Modules.vpnDetection
    if not cfg or not cfg.enabled then return end

    local ip = getPlayerIP(src)
    if ip then
        Citizen.CreateThread(function()
            Wait(2000)
            checkIP(src, ip)
        end)
    end
end)
