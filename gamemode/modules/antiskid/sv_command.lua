
-- Set a specific AntiSkid check whitelist.
local whitelist_set_check_callback = function(ply, args)
    if #args == 0 then
        ply:log("Missing required argument <check> (SkidCheck check name)", "warning")
        return
    end

    local check = GNIL.AntiSkid["_checks"][args[1]]
    if not check then
        ply:log("Unknown antiskid SkidCheck name provided", "warning")
        return
    end
    
    if not check.whitelist then
        ply:log("Check '" .. check.name .. "' does not use a whitelist", "warning")
        return
    end

    ply:log("Starting SkidCheck '" .. check.name .. "' on " .. ply:ToString(), "info")
    check:Start(ply, function(success, out)
        if not success then
            ply:log("Failed to set check whitelist data with error: " .. out, "error")
            return
        end

        -- Store the gathered output in the check whitelist.
        check.whitelist:Write(out)
        ply:log("Successfully updated AntiSkid check '" .. check.name .. "' whitelist", "success")
    end)
end

-- Set all AntiSkid checks that use whitelists.
local whitelist_set_all_callback = function(ply)
    for _, v in pairs(GNIL.AntiSkid["_checks"]) do
        if not v.whitelist then return end
        
        ply:log("Starting whitelist SkidCheck '" .. v.name .. "'", "info")
        v:Start(ply, function(success, out)
            if not success then
                ply:log("Failed to set check whitelist data with error: " .. out, "error")
                return
            end

            v.whitelist:Write(out)
            ply:log("Successfully updated AntiSkid check '" .. check.name .. "' whitelist", "success")
        end)
    end
    ply:log("Finished setting all SkidCheck whitelists based on player " .. ply:ToString(), "success")
end

-- Register commands.
GNIL.Commands.Add("antiskid-whitelist-set-all", whitelist_set_all_callback, {GNIL_CMD_ARGUMENT_STRING}, GNIL_CMD_ACCESS_DEVELOPER, true)
GNIL.Commands.Add("antiskid-whitelist-set-check", whitelist_set_check_callback, {GNIL_CMD_ARGUMENT_STRING}, GNIL_CMD_ACCESS_DEVELOPER, true)