-- Module extensions allow for other modules to directly inject
-- functionality into other modules by "Using" the extension.

local BaseExtension = GNIL.Thirdparty.middleclass("BaseModuleExtension"):IncludeMixin(GNIL.ClassMixins.Events)

function BaseExtension:Initialize(moduleInstance)
    self.module = moduleInstance
end

-- Module passthrough hooks.
function BaseExtension:OnLoad(moduleInstance) end
function BaseExtension:OnUnload(moduleInstance) end

return BaseExtension