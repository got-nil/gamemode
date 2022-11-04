
-- The PlayerNetLoad is a serverside hook that is called similar
-- to PlayerInitialSpawn (in that its only called once per player connection)
-- however unlike PlayerInitialSpawn it indicates that the client
-- is able to send and receive net data. 

if CLIENT then

	-- As the client, simply send the ready message once initpostentity.
	hook.Add("InitPostEntity", "gnil_net_pnl_ready", function()
		net.Start("gnilr")
		net.SendToServer()
	end)

end
if SERVER then

	GNIL.Net["_pnl"] = GNIL.Net["_pnl"] or {}

	-- Used by the server send to queue messages for players that have not
	-- fully loaded in (although the table is global anyway, this is just pretty).
	function GNIL.Net.HasPlayerNetLoaded(ply_or_steamid)
		local sid = isstring(ply_or_steamid) and ply_or_steamid or ply_or_steamid:SteamID()
		return GNIL.Net["_pnl"][sid] == true
	end

	net.Receive("gnilr", function(_, ply)
		local sid = ply:SteamID()
		if sid != "BOT" and GNIL.Net["_pnl"][sid] == true then return end

		-- If the player has not yet netloaded, then we should run the hook
		-- with the player as the only argument. (Then store the steamid).
		hook.Run("PlayerNetLoad", ply)
		GNIL.Net["_pnl"][sid] = true
	end)

	-- When a player disconnects, we should ensure that their steamid is removed
	-- from the PlayerNetLoad table (so when they rejoin they can re-send the ready event)
	hook.Add("PlayerDisconnected", "gnil_net_pnl_disconnect", function(ply)
		GNIL.Net["_pnl"][ply:SteamID()] = nil
	end)

end
