local MODULE = MODULE

MODULE.name = "API"
MODULE.description = "Provides a HTTP interface for external data access."
MODULE.author = "morgverd"
MODULE.config = true
MODULE.tests = true

-- Handle module fileloading manually to preserve load-order.
MODULE:SetAutoload(false)

GNIL.API = GNIL.API or {
    
    -- This is the global server instance that is used as
    -- a default target when adding routes via the static
    -- router methods. 
    _GLOBAL_SERVER = nil
}

MODULE.OnInit = function()

    -- Require the gwsockets module.
    local success, errorMessage = GNIL.Utils.RequireDLL("gwsockets", "GWSockets")
    if not success then
        MODULE:log("Failed to load gwsockets with error: " .. errorMessage, "error")
        return false
    end
end

-- Module load start before any other files are included.
MODULE.OnLoad = function()
    
    -- Load core utilities (the utils that the utils require).
    local baseUtilities, ignoredUtilities = {"config", "url", "thirdparty", "classes"}, {}
    for i, v in ipairs(baseUtilities) do
        local path = "utils/sv_" .. v .. ".lua"
        MODULE:Include(path)
        table.insert(ignoredUtilities, path)
    end

    -- Load any remaining core utilities.
    MODULE:IncludeDirectory("utils", ignoredUtilities)
    MODULE:Include("sv_extension.lua")
end

-- When the module files have been fully loaded.
MODULE.OnLoadFinished = function()

    -- Create global server reference and connect.
    GNIL.API._GLOBAL_SERVER = GNIL.API._GLOBAL_SERVER or GNIL.API.Server:New("main", {
        ["ip_whitelist"] = GNIL.API.Config.ip_whitelist
    })
    GNIL.API._GLOBAL_SERVER:Connect(function(state)
        MODULE:log(
            (state && "Successfully connected" || "Failed to connect") .. " to upstream websocket.",
            (state && "debug" || "error")
        )
    end)

    -- Finally, include the routes!
    MODULE:IncludeDirectory("routes")
end