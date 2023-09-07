-- Used to contain each gamemode config file.

local Config = GNIL.Thirdparty.middleclass("Config")
function Config:Initialize(name, struct)
    self.name = name
    self.struct = struct
    self.filepath = GNIL.Utils.ResolveGamemodePath("config/" .. name .. ".lua")
end

function Config:Setup()
    
    -- SERVER: If there is no check function the config
    -- file can be added normally as a lua file!
    if SERVER and not self.struct.check and self.struct.realm != "server" then
        AddCSLuaFile(self.filepath)
    end
    return self
end

-- Call a validation structure directly on the raw config.
function Config:Validate(structure)
    return GNIL.Validation.Structure(self.struct.config, structure)
end

-- Return the raw config data instead of using Get.
function Config:ToTable()
    return self.struct.config
end

function Config:Get(key, default)
    local out = self.struct.config[key]
    if out == nil then out = default end
    return out
end

function Config:Gets(struct)
    assert(not table.IsSequential(struct), "Provided config gets structure should be associative key = default")

    local out = {}
    for k, v in pairs(struct) do
        out[k] = self:Get(k, v) 
    end
    return out
end

function Config:ShouldSend(ply)
    if CLIENT or self.struct.realm == "server" then return false end
    return self.struct.check and self.struct.check(ply)
end

return Config