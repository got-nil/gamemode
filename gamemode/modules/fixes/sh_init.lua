local MODULE = MODULE

MODULE.name = "Fixes"
MODULE.author = "morgverd"
MODULE.description = "A set of fixes and optimisations for the server and clients."
MODULE.config = "fixes"

GNIL.Fixes = GNIL.Fixes or {
    ["_optimizers"] = {}
}


-- Ensure the enums are loaded before other files.
if SERVER then
    MODULE.OnLoad = function()
        MODULE:Include("sv_enums.lua")
    end
end

-- The config file is only required on the server, since its
-- not used by the client (since config isn't sent to client).
MODULE.IsConfigRequired = function()
    return SERVER
end

-- When the module has finished loading all the base files
-- we should start loading the optimizer files.
MODULE.OnLoadFinished = function()
    if SERVER and not MODULE:Config():Get("Modules", {Optimizers = false}).Optimizers then
        MODULE:log("Optimizers have been disabled.", "debug")
        return
    end

    MODULE:log("Finished loading module, starting to load optimizers.", "debug")
    local files, _ = MODULE:Find("optimizers/*.lua")
    for _, v in ipairs(files) do

        -- Load the optimizer irregardless of realm. If the realm is
        -- invalid simply do not process the return value. This ensures
        -- that the client optimizer files are sent to client.
        local optimizer = MODULE:Include("optimizers/" .. v)
        if not GNIL.Utils.IsFilenameForCurrentRealm(v) then
            continue
        end

        -- Validate optimizer return structure.
        if not (istable(optimizer) and isstring(optimizer.name) and isfunction(optimizer.enable) and isfunction(optimizer.disable)) then
            MODULE:log("Failed to load optimizer '" .. v .. "' as return value wasn't an optimizer.", "warning")
            continue
        end

        -- Cache output optimizer.
        GNIL.Fixes["_optimizers"][optimizer.name] = optimizer
        MODULE:log("Successfully loaded optimizer '" .. optimizer.name .. "' (" .. v .. ").", "debug")
    end
end
