GNIL.Modules = GNIL.Modules or {}
GNIL.Modules.Extensions = GNIL.Modules.Extensions or {
    ["_cached_extensions"] = {}
}

-- This function can be called externally (despite the private prefix).
-- It CAN be called multiple times on one extension for module reloads.
-- Essentially the public interface incase more init behaviour is added.
function GNIL.Modules.Extensions._Initialize(moduleInstance, extensionInstance)
    return GNIL.Modules.Extensions._AddSignals(moduleInstance, extensionInstance)
end

-- Add passthrough signals.
function GNIL.Modules.Extensions._AddSignals(moduleInstance, extensionInstance)
    for _, v in ipairs({"Load", "Unload", "Reinitialize"}) do
        moduleInstance:AddSignalListener(v, function(...)
            extensionInstance:EmitSignal(v, ...)
        end)
    end
    return extensionInstance
end

function GNIL.Modules.Extensions.Add(name, extensionClass)
    assert(extensionClass:IsSubclassOf(GNIL.Classes.Extension), "Extension class must inherit from BaseModuleExtension")
    GNIL.Modules.Extensions["_cached_extensions"][name] = extensionClass
end

-- Use MODULE:GetExtension instead. Do not call directly.
function GNIL.Modules.Extensions._Get(moduleInstance, name)
    local extensionClass = GNIL.Modules.Extensions["_cached_extensions"][name]
    if extensionClass == nil then return nil end

    local extensionInstance = extensionClass:New(moduleInstance)
    return GNIL.Modules.Extensions._AddSignals(moduleInstance, extensionInstance)
end

hook.Add("GNIL.Modules.InitAfterDependencies", "modules_extensions_init", function(_, moduleInstance)
    for k, _ in pairs(moduleInstance._delayed_extensions) do
        if moduleInstance._extensions[k] != nil then continue end

        -- Attempt to load the required missing extension.
        if not moduleInstance:LoadExtension(k) then
            moduleInstance:log("Failed to load required extension '" .. k .. "' for module, refusing load.", "warning")
            return false
        end
    end
end)