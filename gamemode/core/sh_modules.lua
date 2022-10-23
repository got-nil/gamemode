GNIL.Modules = GNIL.Modules or {
    ["_loaded"] = {}
}

local cachedModules = {}

-- TODO
function GNIL.Modules.IsLoaded(name) return false end
function GNIL.Modules.Load(name) return false end
function GNIL.Modules.Unload(name) return false end

function GNIL.Modules.Exists(name)
    return file.IsDir(GNIL.GamemodeBasePath .. "/modules/" .. name, "LUA")
end

function GNIL.Modules.Get(name) // ?Module
    if cachedModules[name] then return cachedModules[name] end
    if not self.Exists(name) then return nil end

    -- Create/Cache the module 
    cachedModules[name] = GNIL.Classes.Module:New(name)
    return cachedModules[name]
end
