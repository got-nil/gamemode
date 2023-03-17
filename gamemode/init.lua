hook.Run("DarkRPStartedLoading")

DeriveGamemode("darkrp")
DEFINE_BASECLASS("gamemode_darkrp")

GM.DarkRP = BaseClass

-- Make sure theres always a gnil data directory
-- on the server. It will be created on the client
-- if and when required.
if not file.IsDir("gnil", "DATA") then
    file.CreateDir("gnil")
end

-- Include the shared file and send it to client,
-- this is the core gamemode entrypoint/setup.
AddCSLuaFile("shared.lua")
include("shared.lua")
