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
        }
    },

    -- Used for when we eventually have a production environment, allowing us to
    -- push code that will not run on production environment servers etc.
    -- Either 'dev' or 'prod' ('prod' only being for the server actively hosting players)
    _ENVIRONMENT = "dev"
}

-- Store a global version of the folder name for luadev.
if not GNIL.GamemodeFolderName then
    GNIL.GamemodeFolderName = GM.FolderName
    GNIL.GamemodeBasePath = GM.FolderName .. "/gamemode"
end

-- Core gamemode information.
GM.Version = GNIL._VERSION
GM.Name = "DarkRP"
GM.Author = "GotNil Development Team & FPtje Falco et al."

-- Load a couple base utilities that are so important that they require
-- being loaded before all other core utilities/modules etc. This is
-- essentially for core tools that the utils themselves rely on.
local requiredSharedUtilities = {
    "sh_utils.lua",
    "sh_logging.lua"
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

-- Once all basic utilities have set up etc, we should load all modules.
GNIL.Modules.LoadAll()