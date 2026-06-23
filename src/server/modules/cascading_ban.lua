function CascadingBanCheck(bannedIdentifiers)
    if not Config.Modules.cascadingBan or not Config.Modules.cascadingBan.enabled then return end

    for pid, _ in pairs(ACS.connectedPlayers) do
        local ids = GetPlayerIdentifiers(pid)
        if ids then
            local shared = {}

            if bannedIdentifiers.license and ids.license == bannedIdentifiers.license then
                shared[#shared + 1] = "license"
            end
            if bannedIdentifiers.steam and ids.steam == bannedIdentifiers.steam then
                shared[#shared + 1] = "steam"
            end
            if bannedIdentifiers.discord and ids.discord == bannedIdentifiers.discord then
                shared[#shared + 1] = "discord"
            end
            if bannedIdentifiers.ip and ids.ip == bannedIdentifiers.ip then
                shared[#shared + 1] = "ip"
            end
            if bannedIdentifiers.hwids and ids.hwids then
                for _, hw1 in ipairs(bannedIdentifiers.hwids) do
                    for _, hw2 in ipairs(ids.hwids) do
                        if hw1 == hw2 and hw1 ~= "" then
                            shared[#shared + 1] = "hwid"
                            break
                        end
                    end
                    if #shared > 0 and shared[#shared] == "hwid" then break end
                end
            end

            if #shared > 0 then
                local name = GetPlayerName(pid) or "?"
                Log("WARN", ("[CASCADE] %s (ID %d) shares identifiers with banned player: %s"):format(
                    name, pid, table.concat(shared, ", ")))

                if Config.Modules.cascadingBan.autoBan then
                    BanPlayer(pid, "Cascading ban",
                        "Shares identifiers with banned player: " .. table.concat(shared, ", "))
                else
                    for adminPid, _ in pairs(ACS.connectedPlayers) do
                        if IsPlayerAceAllowed(adminPid, "AdminMenu") then
                            TriggerClientEvent(EncodeEvent("AC:detectionNotify"), adminPid, {
                                player = name,
                                id     = pid,
                                module = "cascadingBan",
                                reason = "Shares " .. table.concat(shared, "/") .. " with banned player",
                                type   = "WARN",
                            })
                        end
                    end
                end
            end
        end
    end
end
