hook.Run("DarkRPStartedLoading")

DeriveGamemode("darkrp")
DEFINE_BASECLASS("gamemode_darkrp")

GM.DarkRP = BaseClass

-- Include the shared file and send it to client,
-- this is the core gamemode entrypoint/setup.
AddCSLuaFile("shared.lua")
include("shared.lua")

-- This will eventually be moved to the net lib.
hook.Add("PlayerInitialSpawn", "gnil_setup_load", function(ply)
	hook.Add("SetupMove", ply, function(self, pl, _, cmd)
		if self == pl and not cmd:IsForced() then
			hook.Run("PlayerNetLoad", self)
			hook.Remove("SetupMove", self)
		end
	end)
end)