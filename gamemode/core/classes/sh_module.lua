-- Handle the loading and management of modules.

local Module = GNIL.Thirdparty.middleclass("Module")
function Module:Initialize(name)
    self._module_name = name

    self.name = name
    self.description = "No Description Defined"
    self.author = "No Author Defined"

    self.dependencies = nil
    self.hooks = {}
    self.autoload_directories = {}
end

-- Add a relative directory path to be autoloaded when the rest of
-- the module is loaded by the utility. Delayed directory include.
function Module:AddAutoloadDirectory(directory)
    if not table.HasValue(self.autoload_directories, directory) then
        table.insert(self.autoload_directories, directory)
    end
end

-- Simply call the modules utility with the current module name
-- as the ID argument. This could've just been functional but we're
-- sticking to OOP layout here.
function Module:IsLoaded() return GNIL.Modules.IsLoaded(self._module_name) end
function Module:Load() return GNIL.Modules.Load(self._module_name) end
function Module:Unload() return GNIL.Modules.Unload(self._module_name) end

-- Require doesn't actually load anything, instead it keeps track of
-- what should be loaded and the Modules loader takes care of actually
-- resolving the dependencies.
function Module:Require(requirement)
    if not GNIL.Modules.Exists(requirement) then self:log("Required module '" .. requirement .. "' is Missing/Invalid.", "error") end
    if self.dependencies == nil then self.dependencies = {} end
    if not table.HasValue(self.dependencies, requirement) then
        table.insert(self.dependencies, requirement)
    end
end

-- Allow for multiple dependencies to be given at once.
function Module:Requires(requirements)
    assert(not table.IsSequential(requirements), "Requirements should be given as a sequential array of module names.")
    for _, v in ipairs(requirements) do
        if not self:Require(v) then return false end
    end
    return true
end

-- TODO: VirtualRaptor --
-- Not my work because cba --
function Module:AddHook(...) return GNIL.Hooks.Add(self._module_name, ...) end
function Module:RemoveHook(...) return GNIL.Hooks.RemoveHook(self._module_name, ...) end
function Module:GetHooks(...) return GNIL.Hooks.GetHooks(self._module_name, ...) end
-------------------------

-- Logging passthrough with module name as prefix.
function Module:log(log, logtype) GNIL.log(log, logtype, self._module_name) end

-- Class hook functions
function Module:OnUnload() end
function Module:OnLoad() end 

return Module