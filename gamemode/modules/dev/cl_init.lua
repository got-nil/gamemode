local MODULE = MODULE

GNIL.Dev = GNIL.Dev or {
    VFS = {}
}

MODULE:RequireModule("net")
MODULE:RequireExtension("net")

MODULE.OnLoad = function()

    MODULE:GetExtension("net"):Receive("dev_module_reload", function(_, _, reply)
        local moduleName = net.ReadString()
        if not GNIL.Modules.IsLoaded(moduleName) then
            return reply:WriteBool(false)
        end
        return reply:WriteBool(
            GNIL.Modules.Reload(moduleName)
        )
    end)
    MODULE:IncludeDirectory("vfs")
end