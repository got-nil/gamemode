local MODULE = MODULE

MODULE.name = "API"
MODULE.description = "Provides a HTTP interface for external data access."
MODULE.author = "morgverd"

-- Handle module fileloading manually to preserve load-order.
MODULE:SetAutoload(false)

-- Ensure the required 'gwsockets' module is present and loaded.
if SERVER then
    local failure = false
    if not GNIL.Utils.IsInstalled("gwsockets") then
        MODULE:log("Missing required bin module 'gwsockets'.", "error")
        failure = true
    end
    if not pcall(require, "gwsockets") or GWSockets == nil then
        MODULE:log("Could not load required bin module 'gwsockets'.", "error")
        failure = true
    end

    -- If the sockets module was not loaded, disable the module
    -- as the websocket connection is required (handled by upstream)
    if failure then
        MODULE:SetDisabled(true)
        MODULE:log("Disabled due to failures with gwsockets.", "error")
        return
    end
end

GNIL.API = GNIL.API or {
    
    -- This is the global server instance that is used as
    -- a default target when adding routes via the static
    -- router methods. 
    _GLOBAL_SERVER = nil
}

-- Load core utilities (the utils that the utils require).
local baseUtilities, ignoredUtilities = {"config", "url", "thirdparty", "classes"}, {}
for i, v in ipairs(baseUtilities) do
    local path = "utils/sv_" .. v .. ".lua"
    MODULE:Include(path)
    table.insert(ignoredUtilities, path)
end

-- Load any remaining core utilities.
MODULE:IncludeDirectory("utils", ignoredUtilities)

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