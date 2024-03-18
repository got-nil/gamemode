local MODULE = MODULE

GNIL.Dev = GNIL.Dev or {
    VFS = {}
}

MODULE:RequireModule("net")
MODULE:RequireExtension("Net")

MODULE.OnLoad = function()

    MODULE:GetExtension("Net"):Receive("dev_module_reload", function(_, _, reply)
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