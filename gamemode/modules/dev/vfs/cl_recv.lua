local MODULE = MODULE
MODULE:GetExtension("net"):ReceiveChunked("dev_module_reload", function(data)
    local moduleName, filecount = data[1], tonumber(data[2])

    -- If the module isn't loaded or the filecount couldn't be read, return.
    if not GNIL.Modules.IsLoaded(moduleName) or filecount == nil then
        MODULE:log("Could not VFS reload module '" .. moduleName .. "' as it is not loaded.", "warning")
        return
    end

    -- Create the virtual file system and write each module file to it.
    local vfs, offset = GNIL.Dev.VFS.Class:New(), 2
    for i = 1, filecount, 2 do
        vfs:Write(
            data[offset + i],
            data[offset + i + 1]
        )
    end

    -- Try to reload the target module in a wrapped vfs?
    local success, out = vfs:Wrap(GNIL.Modules.Reload, moduleName)
    if success then
        MODULE:log("Successfully VFS reloaded module '" .. moduleName .. "'.", "success")
    else
        MODULE:log("Failed to reload VFS module '" .. moduleName .. "' with error:", "error")
        ErrorNoHaltWithStack(out)
    end
end)