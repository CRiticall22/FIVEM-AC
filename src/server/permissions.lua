local ACE_ADMIN = "AdminMenu"
local ACE_BYPASS = Config.Whitelist.AcePerm
local txAdminWhitelist = {}

function HasAdminPermission(src)
    return IsPlayerAceAllowed(src, ACE_ADMIN)
end

function IsPlayerWhitelisted(src)
    if Config.Whitelist.WhitelistTxAdmin and txAdminWhitelist[src] then
        return true
    end
    if IsPlayerAceAllowed(src, ACE_BYPASS) then
        return true
    end
    return false
end

AddEventHandler("txAdmin:events:adminAuth", function(data)
    if GetInvokingResource() == "monitor" then
        if data.netid == -1 then
            txAdminWhitelist = {}
        else
            txAdminWhitelist[data.netid] = data.isAdmin or false
        end
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    txAdminWhitelist[src] = nil
end)

RegisterCommand("eac_whitelist", function(src, args)
    if src ~= 0 and not HasAdminPermission(src) then return end
    local targetId = tonumber(args[1])
    if not targetId then
        Log("WARN", "Usage: eac_whitelist <playerId>")
        return
    end
    ExecuteCommand(("add_ace identifier.license:%s %s allow"):format(
        GetPlayerIdentifierByType(targetId, "license") or "unknown", ACE_BYPASS))
    Log("INFO", "Whitelisted player " .. targetId)
end, true)

RegisterCommand("eac_unwhitelist", function(src, args)
    if src ~= 0 and not HasAdminPermission(src) then return end
    local targetId = tonumber(args[1])
    if not targetId then
        Log("WARN", "Usage: eac_unwhitelist <playerId>")
        return
    end
    ExecuteCommand(("remove_ace identifier.license:%s %s allow"):format(
        GetPlayerIdentifierByType(targetId, "license") or "unknown", ACE_BYPASS))
    Log("INFO", "Removed whitelist for player " .. targetId)
end, true)
