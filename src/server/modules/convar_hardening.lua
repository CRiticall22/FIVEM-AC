local PROTECTED_CONVARS = {
    { name = "sv_enableNetworkedSounds",         expected = "false", module = "antiNetworkedSounds" },
    { name = "sv_filterRequestControl",          expected = "4",     module = "antiEntityTakeover" },
    { name = "sv_enableNetworkedPhoneExplosions", expected = "false", module = "antiPhoneExplosions" },
}

Citizen.CreateThread(function()
    Wait(5000)
    while true do
        Wait(30000)
        if not EACS.active then goto continue end

        for _, cv in ipairs(PROTECTED_CONVARS) do
            local cfg = Config.Modules[cv.module]
            if cfg and cfg.enabled then
                local current = GetConvar(cv.name, "")
                if current ~= cv.expected then
                    Log("WARN", ("Convar %s was changed to '%s', resetting to '%s'"):format(
                        cv.name, current, cv.expected))
                    SetConvar(cv.name, cv.expected)
                end
            end
        end

        ::continue::
    end
end)
