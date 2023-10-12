
-- Default environment settings.
local env_options = {

    -- General.
    ["DEV"] = false,            -- Catch all development flag, used for non-specific cases.
    ["LOADER_RESET"] = false,   -- Should gamemode loaders be reset on lua refresh.
    ["MODULES_RESET"] = false,  -- Should all modules be reset on lua refresh (reloading all).
    ["DARKRP_REFRESH"] = false, -- Should DarkRP be lua refreshed?

    -- Luadev access.
    ["LUADEV_ALLOWED"] = true,  -- Can luadev be used by developers? (default to true since the addon has to be installed).
    ["LUADEV_SNITCH"] = false,  -- Should we snitch on developers using luadev (for production teehee).

    -- Lua refresh handling.
    ["LUA_REFRESH"] = false,         -- Can the gamemode be lua refreshed?
    ["REFRESH_CORE"] = false,        -- Should the core utilities be refreshed?
    ["REFRESH_ALL_MODULES"] = false, -- Should all modules be refreshed (if LUA_REFRESH is true)?
    ["REFRESH_MODULES"] = {}         -- Certain modules that should be refreshed (if LUA_REFRESH is true, and REFRESH_ALL_MODULES is false).
}
local env_enums = {}
for _, v in ipairs(table.GetKeys(env_options)) do
    env_enums[v] = true
end

-- Preset environments.
local env_presets = {
    ["dev"] = {
        ["DEV"] = true,
        ["LOADER_RESET"] = true,
        ["MODULES_RESET"] = true,
        ["LUA_REFRESH"] = true,
        ["REFRESH_ALL_MODULES"] = true
    },
    ["prod"] = {
        ["LUADEV_SNITCH"] = true
    },

    -- Development preset for working on the gamemode core.
    ["core-dev"] = {
        ["DEV"] = true,
        ["LUA_REFRESH"] = true,
        ["REFRESH_CORE"] = true,
        ["LOADER_RESET"] = true
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
if not (isstring(env) or istable(env)) then
    GNIL._safeLog("Invalid provided environment, must be either preset name or env table.", "error")
    return false
end

local out = {}
if isstring(env) then

    -- Validate the preset provided.
    local preset = getPreset(env)
    if not preset then
        GNIL._safeLog("Invalid provided preset name '" .. env .. "'", "error")
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
            GNIL._safeLog("Invalid provided preset name '" .. env.preset .. "'", "error")
            return false
        end        
        out = preset
    end

    -- Applies additional settings ontop of preset base (if there is one).
    for k, v in pairs(env) do        
        if not env_enums[k] then continue end
        out[k] = v
    end
end


-- Used to prevent DarkRP gamemode from lua refreshing.
-- Edit: At the top of both files, add the hook line.
-- Files: darkrp/gamemode/<init.lua, cl_init.lua>
-- Code:
--   if hook.Run("DarkRPInit") == false then return end
hook.Add("DarkRPInit", "gnil_luarefresh", function()

    -- If we've already loaded (luarefresh) + darkrp is already loaded + the
    -- DARKRP_REFRESH env setting is off then the darkrp reload should be stopped. 
    if GNIL._LOADED and not GNIL.ENV.DARKRP_REFRESH then
        return false
    end
end)

-- If we get here, than the environment is valid!
GNIL.ENV = out
return true