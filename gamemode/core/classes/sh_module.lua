-- Handle the loading and management of modules.

local Module = GNIL.Thirdparty.middleclass("Module")
function Module:Initialize(name)
    self.name = name
    self.dependencies = {}
end

-- Simply call the modules utility with the current module name
-- as the ID argument. This could've just been functional but we're
-- sticking to OOP layout here.
function Module:IsLoaded() return GNIL.Modules.IsLoaded(self.name) end
function Module:Load() return GNIL.Modules.Load(self.name) end
function Module:Unload() return GNIL.Modules.Unload(self.name) end

function Module:Require(requirement)
    if not table.HasValue(self.dependencies, requirement) then
        table.insert(self.dependencies, requirement)
    end

    local required_module = GNIL.Modules.Get(requirement)
    if required_module == nil then self:log("Required module '" .. requirement .. "' is Missing/Invalid.", "error") return end
    return required_module:Load()
end

function Module:Requires(requirements)
    for _, v in ipairs(requirements) do
        if not self:Require(v) then return false end
    end
    return true
end

// Logging passthrough with module name as prefix.
function Module:log(log, logtype) GNIL.log(log, logtype, self.name) end

-- Class hook functions
function Module:OnUnload() end
function Module:OnLoad() end 

return Module