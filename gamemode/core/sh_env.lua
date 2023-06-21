
-- Default environment settings.
local env_options = {

    -- General.
    ["DEV"] = false,            -- Catch all development flag, used for non-specific cases.
    ["LOADER_RESET"] = false,   -- Should gamemode loaders be reset on lua refresh.
    ["MODULES_RESET"] = false,  -- Should all modules be reset on lua refresh (reloading all).

    -- Luadev access.
    ["LUADEV_ALLOWED"] = true,  -- Can luadev be used by developers?
    ["LUADEV_SNITCH"] = false,  -- Should we snitch on developers using luadev (for production).

    -- Lua refresh handling.
    ["LUA_REFRESH"] = false,         -- Can the gamemode be lua refreshed?
    ["REFRESH_CORE"] = false,        -- Should the core utilities be refreshed?
    ["REFRESH_ALL_MODULES"] = false, -- Should all modules be refreshed (if LUA_REFRESH is true)?
    ["REFRESH_MODULES"] = {}         -- Certain modules that should be refreshed (if LUA_REFRESH is true, and REFRESH_ALL_MODULES is false)
}

-- Preset environments.
local env_presets = {
    ["dev"] = {
        ["DEV"] = true,
        ["LOADER_RESET"] = true,
        ["MODULES_RESET"] = true,
        ["LUADEV_ALLOWED"] = true,
        ["LUADEV_SNITCH"] = false,
        ["LUA_REFRESH"] = true,
        ["REFRESH_ALL_MODULES"] = true
    },
    ["prod"] = {
        ["LUADEV_SNITCH"] = true
    }
}

-- Apply the preset ontop of the default env_options set.
local function getPreset(name)
    if not env_presets[name] then return nil end
    local out = env_options
    for k, v in pairs(env_presets[name]) do
        out[k] = v
    end
    return out
end

-- Validate the environment input.
local env = GNIL._ENVIRONMENT
if not ((isstring(env)) or (istable(env) and not table.IsSequential(env))) then
    print("Invalid provided environment, must be either preset name or env table.")
    return false
end

local out = {}
if isstring(env) then

    -- Validate the preset provided.
    local preset = getPreset(env)
    if not preset then
        print("Invalid provided preset name '" .. env .. "'")
        return false
    end
    
    -- Load the preset name provided.
    out = preset
else
    
    -- Table provided, could contain a preset however could also contain overrides.
    -- If there is a 'preset' string key, use that as a base.
    if isstring(env.preset) then
        
        -- Validate the preset provided.
        local preset = getPreset(env.preset)
        if not preset then
            print("Invalid provided preset name '" .. env.preset .. "'")
            return false
        end        
        out = preset
    end

    -- Apply additional settings ontop of preset base (if there is one).
    for k, v in pairs(env) do        
        if not env_options[k] then continue end
        out[k] = v
    end
end

-- If we get here, the environment is valid!
GNIL.ENV = out
return true