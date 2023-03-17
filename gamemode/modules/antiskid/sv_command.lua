
local whitelist_set_callback = function(ply, args)
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

GNIL.Commands.Add("antiskid-whitelist-set", whitelist_set_callback, {GNIL_CMD_ARGUMENT_STRING}, GNIL_CMD_ACCESS_DEVELOPER, true)