-- Used to contain each gamemode config file.

---@class Config: middleclass
local Config = GNIL.Thirdparty.middleclass("Config")
function Config:Initialize(name, struct, filepath)
    self.name = name
    self.struct = struct
    self.filepath = filepath or GNIL.Utils.ResolveGamemodePath("config/" .. name .. ".lua")
end

---Setup the config file (called on load).
---@return self
function Config:Setup()

    -- SERVER: If there is no check function the config
    -- file can be added normally as a lua file!
    if SERVER and not self.struct.check and self.struct.realm != "server" then
        AddCSLuaFile(self.filepath)
    end
    return self
end

---Validate the config file structure.
---@param structure table
---@return boolean Structure validity state.
---@return string|table Error message or structured output.
function Config:Validate(structure)
    return GNIL.Validation.Structure(self.struct.config, structure)
end

---Convert config to table.
---@return table
function Config:ToTable()
    return self.struct.config
end

---Get a value from config by key.
---@param key string
---@param default any
---@return any
function Config:Get(key, default)
    local out = self.struct.config[key]
    if out == nil then out = default end
    return out
end

---Set a value from config by key.
---@param key string
---@param value any
---@return self
function Config:Set(key, value)
    self.struct.config[key] = value
    return self
end

---Get multiple values by key names.
---@param struct table<string, any> KeyName, Default
---@return table
function Config:Gets(struct)
    assert(not table.IsSequential(struct), "Provided config gets structure should be associative key = default")

    local out = {}
    for k, v in pairs(struct) do
        out[k] = self:Get(k, v)
    end
    return out
end

---Should a config file be sent to target player?
---@param ply Player
---@return boolean
function Config:ShouldSend(ply)
    if CLIENT or self.struct.realm == "server" then return false end
    return self.struct.check and self.struct.check(ply)
end

return Config