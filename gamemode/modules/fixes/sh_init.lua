local MODULE = MODULE

MODULE.name = "Fixes"
MODULE.author = "morgverd"
MODULE.description = "A set of fixes and optimisations for the server and clients."

GNIL.Fixes = GNIL.Fixes or {
    ["_optimizers"] = {}
}

-- When the module has finished loading all the base files
-- we should start loading the optimizer files.
MODULE.OnLoadFinished = function()

    if not GNIL.Fixes.Config["Modules"]["Optimizers"] then
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
        if optimizer and not (isstring(optimizer.name) and isfunction(optimizer.enable) and isfunction(optimizer.disable)) then
            MODULE:log("Failed to load optimizer '" .. v .. "' as return value wasn't an optimizer.", "warning")
            continue
        end

        -- Cache output optimizer.
        GNIL.Fixes["_optimizers"][optimizer.name] = optimizer
        MODULE:log("Successfully loaded optimizer '" .. optimizer.name .. "' (" .. v .. ").", "debug")
    end
end

if SERVER then
    for _, v in ipairs({"sv_enums.lua", "sv_config.lua"}) do
        MODULE:Include(v)
    end
end