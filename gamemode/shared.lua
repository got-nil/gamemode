GNIL = GNIL or {}
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