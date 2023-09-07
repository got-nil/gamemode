
DeriveGamemode("darkrp")
DEFINE_BASECLASS("gamemode_darkrp")

GM.DarkRP = BaseClass

-- Include the shared file and send it to client,
-- this is the core gamemode entrypoint/setup.
AddCSLuaFile("shared.lua")
include("shared.lua")
