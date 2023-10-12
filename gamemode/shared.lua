GNIL = GNIL or {

    -- So unbelievably sweaty, but we're going to be following the semver
    -- standardisation. (https://semver.org/). This will be for automation
    -- purposes primarily. 
    _VERSION = "1.0.0-alpha",

    -- These are the credits of core developers among the project. The steamIDs
    -- provided below may used in authentication/access validation for developer
    -- only tools etc, so please ensure your SteamID64 provided is correct.
    _CREDITS = {

        -- Copy my structure, and paste your own stuff over it.
        -- IF YOU DON'T KNOW YOUR TITLE, ASK MORG OR RAPTOR, DONT MAKE ONE UP.
        -- ADD SEQUENTIALLY, YOUR PR WILL BE REJECTED IF YOU TRY ALTER ORDER. 
        {
            ["name"] = "morgverd",
            ["id64"] = "76561198301284223",
            ["title"] = "Project Manager"
        },
        {
            ["name"] = "professor",
            ["id64"] = "76561198866260204",
            ["title"] = "UI/UX Lead"
        },
        {
            ["name"] = "virtualraptor",
            ["id64"] = "76561198022787311",
            ["title"] = "Project Manager"
        },
        {
            ["name"] = "sparib",
            ["id64"] = "76561198306789611",
            ["title"] = "Web Lead + Backend Developer"
        },
        {
            ["name"] = "blazzy",
            ["id64"] = "76561198881071680",
            ["title"] = "Map Lead + Backend Developer"
        }
    }
}

-- The gamemode environment controls certain behaviours such as lua refresh
-- handling etc. The value can be a string preset name, or a table of env settings.
-- If using table, each env setting must be full caps as key. The 'preset' can be
-- used to inherit an environment preset, with the additional settings being overrides.
GNIL._ENVIRONMENT = "core-dev"

--------------------------------------------------------------------------------------------

-- Store a global version of the folder name for luadev.
if not GNIL.GamemodeFolderName then
    GNIL.GamemodeFolderName = GM.FolderName
    GNIL.GamemodeBasePath = GM.FolderName .. "/gamemode"
end

-- Core gamemode information.
GM.Version = GNIL._VERSION
GM.Name = "DarkRP"
GM.Author = "GotNil Development Team & FPtje Falco et al."

-- A safe logging alias.
GNIL._safeLog = function(msg, level)
    if GNIL.log then GNIL.log(msg, level) else print("GNIL - " .. msg) end
end

-- Load the environment handler first. This allows the gamemode to be halted
-- if there is an invalid environment provided (instead of failing later).
-- Loaded on all loads including refreshes to validate/change environment.
if SERVER and not GNIL._LOADED then AddCSLuaFile("core/sh_env.lua") end
if not include("core/sh_env.lua") then
    ErrorNoHalt("GNIL - Invalid gamemode environment, failed to start.\n")
    return
end

-- Handle LUA refreshes ourselves depending on the environment settings.
-- If the environment is unset, or lua refreshes are allowed do not block.
-- Only if: First load or environment is unset or LUA_REFRESH env setting is on.
if GNIL._LOADED then
    if (GNIL.ENV == nil or not GNIL.ENV.LUA_REFRESH) then
        hook.Run("GNIL.LuaRefreshBlocked")
        GNIL._safeLog("Lua refresh blocked due to environment settings.", "warning")
        return
    end
    GNIL._safeLog("Lua refreshing gamemode!", "warning")
end

-- Load a couple base utilities that are so important that they require
-- being loaded before all other core utilities/modules etc. This is
-- essentially for core tools that the utils themselves rely on.
-- Only if: First load or REFRESH_CORE env setting is on.
if not GNIL._LOADED or GNIL.ENV.REFRESH_CORE then
    local requiredSharedUtilities = {
        "sh_utils.lua",
        "sh_logging.lua",
        "sh_validation.lua",
        "sh_loader.lua",
        "sh_config.lua"
    }
    for _, f in ipairs(requiredSharedUtilities) do
        local path = "core/" .. f
        if SERVER then AddCSLuaFile(path) end
        include(path)
    end

    -- Include all other files within the core directory. We also exclude
    -- the requiredSharedUtilities from being re-loaded as they are included
    -- seperately above.
    GNIL.Utils.IncludeDirectory(GNIL.Utils.ResolveGamemodePath("core"), requiredSharedUtilities)
end

-- Once all basic utilities have set up etc, we should load all modules.
-- Only if: First load or REFRESH_ALL_MODULES env setting is on.
if not GNIL._LOADED or GNIL.ENV.REFRESH_ALL_MODULES then
    GNIL.Modules.LoadAll(GNIL._LOADED == true) -- If we're already loaded reload the modules.
end

-- Handle additional behaviour for lua refreshes.
if GNIL._LOADED then

    -- If we haven't reloaded all modules, attempt to load specific ones instead.
    if not GNIL.ENV.REFRESH_ALL_MODULES and GNIL.ENV.REFRESH_MODULES then
        for _, v in ipairs(GNIL.ENV.REFRESH_MODULES) do
            GNIL.Modules.Load(v, nil, true)
        end
    end
    hook.Run("GNIL.LuaRefresh")
end

-- Finished loading gamemode.
GNIL.log("Gamemode finished loading!", "debug")
GNIL._LOADED = true