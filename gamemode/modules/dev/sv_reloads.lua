local MODULE, Config = MODULE, MODULE:Config()
if Config == nil then
    error("Could not get required dev module config!")
end

MODULE:AddHook("GNIL.Modules.Reload", "module_vfs_reload", function(name, moduleInstance)

    -- Check that client refreshing is enabled.
    if not Config:Get("client_refresh_modules", true) then
        MODULE:log("Client module refreshing is disabled!", "debug")
        return
    end

    -- Make sure the module supports autoloading.
    if not moduleInstance.autoload then
        moduleInstance:log("Cannot send VFS developer reload as module autoload is disabled.", "debug")
        return
    end

    -- Don't broadcast to an empty server.
    local players = player.GetAll()
    if #players == 0 then
        moduleInstance:log("No players connected, not attempting to broadcast module reload.", "debug")
        return
    end

    -- Check what reload_type is being used.
    local reload_type = string.lower(Config:Get("reload_type", "luarefresh"))
    if reload_type == "vfs" then

        -- Send VFS reload to all players.
        MODULE:log("Using VFS to refresh module '" .. moduleInstance:GetModuleName() .. "'! This should only be used in development.", "warning")
        GNIL.Dev.VFS.SendReload(moduleInstance, players)

    elseif reload_type == "luarefresh" then

        -- If luarefresh is enabled, we can just tell clients
        -- to reload the module without sending any files over.
        local targetModuleName = moduleInstance:GetModuleName()
        GNIL.Net.Create("dev_module_reload")
            :WriteString(targetModuleName)
            :OnReply(function(success, _, ply)

                -- If unsuccesful, log it.
                if not success then
                    MODULE:log("Failed to refresh module '" .. targetModuleName .. "' on " .. ply:ToString(), "warning")
                    return
                end
            end)
        :Broadcast()

    else
        MODULE:log("Unknown module reload type '" .. reload_type .. "'.", "warning")
    end
end)