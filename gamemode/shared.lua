GNIL = GNIL or {}

-- The table order is randomised when shown to stop anyone from crying.
-- If your name isn't here, then you haven't made anything yet. If you
-- have made something, feel free to submit a PR on the gamemode to edit.
GNIL._CREDITS = {
    ["morgverd"] = "Backend developer",
    ["virtualraptor"] = "Backend developer and mapper",
    ["professor"] = "UI/UX Lead"
}

-- Replace these once we get a website URL.
GNIL.Website = "https://google.com"
GNIL.WebsiteForums = "https://google.com"
GNIL.WebsiteStore = "https://google.com"

-- Store a global version of the folder name for luadev.
if not GNIL.GamemodeFolderName then
    GNIL.GamemodeFolderName = GM.FolderName
    GNIL.GamemodeBasePath = GM.FolderName .. "/gamemode"
end

-- Core gamemode information.
GM.Version = "1.0.0"
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