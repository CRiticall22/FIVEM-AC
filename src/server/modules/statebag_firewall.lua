local PROTECTED_BAGS = {
    "health", "maxHealth", "armour", "maxArmour",
    "position", "cash", "bank", "money",
    "job", "job_grade", "group", "gang",
    "inventory", "weapons", "loadout",
    "isDead", "isAdmin", "isSuperAdmin",
}

local protectedSet = {}
for _, key in ipairs(PROTECTED_BAGS) do
    protectedSet[key] = true
end

local playerViolations = {}

AddStateBagChangeHandler("", "", function(bagName, key, value, _reserved, replicated)
    local cfg = Config.Modules.stateBagFirewall
    if not cfg or not cfg.enabled then return end
    if not ACS or not ACS.active then return end

    if not replicated then return end

    local src = nil
    local playerBag = bagName:match("^player:(%d+)")
    if playerBag then
        src = tonumber(playerBag)
    end

    if not src then return end

    local name = GetPlayerName(src)
    if not name then return end

    if IsPlayerAceAllowed(tostring(src), Config.Branding.AcePerm) then
        return
    end

    local isProtected = protectedSet[key]
    if not isProtected then
        for _, pattern in ipairs(PROTECTED_BAGS) do
            if string.find(key:lower(), pattern:lower(), 1, true) then
                isProtected = true
                break
            end
        end
    end

    if isProtected then
        playerViolations[src] = (playerViolations[src] or 0) + 1

        Log("WARN", ("[STATEBAG] %s (ID:%d) modified protected state bag '%s' key '%s'"):format(name, src, bagName, key))

        if AddThreatScore then AddThreatScore(src, "stateBagTamper", 25) end

        if playerViolations[src] >= 3 then
            PunishPlayer(src, "stateBagFirewall", ("Repeated state bag tampering: %s = %s"):format(key, tostring(value)))
            playerViolations[src] = 0
        end
    end
end)

AddEventHandler("playerDropped", function()
    playerViolations[source] = nil
end)
