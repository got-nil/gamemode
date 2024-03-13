-- Module extensions allow for other modules to directly inject
-- functionality into other modules by "Using" the extension.

---@class BaseExtension: EventsMixin
local BaseExtension = GNIL.Thirdparty.middleclass("BaseModuleExtension"):IncludeMixin(GNIL.ClassMixins.Events)

function BaseExtension:Initialize(moduleInstance)
    self.module = moduleInstance
end

---Called when the extension is loaded on a module.
---@param moduleInstance Module
function BaseExtension:OnLoad(moduleInstance) end

---Called when the extension is unloaded on a module.
---@param moduleInstance Module
function BaseExtension:OnUnload(moduleInstance) end

return BaseExtension