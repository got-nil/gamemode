local MODULE = MODULE

-- The PlayerNetLoad is a serverside hook that is called similar
-- to PlayerInitialSpawn (in that its only called once per player connection)
-- however unlike PlayerInitialSpawn it indicates that the client
-- is able to send and receive net data.

GNIL.Net["_pnl"] = GNIL.Net["_pnl"] or {}

-- Used by the server send to queue messages for players that have not
-- fully loaded in (although the table is global anyway, this is just pretty).
function GNIL.Net.HasPlayerNetLoaded(ply_or_steamid)
    local sid = isstring(ply_or_steamid) and ply_or_steamid or ply_or_steamid:SteamID()
    return GNIL.Net["_pnl"][sid] == true
end

local function _playerNetLoaded(ply)
    local sid = ply:SteamID()
    if sid != "BOT" and GNIL.Net["_pnl"][sid] == true then return end
    MODULE:log("Player '" .. ply:Nick() .. "' has netloaded.", "debug")

    -- If the player has not yet netloaded, then we should run the hook
    -- with the player as the only argument. (Then store the steamid).
    GNIL.Net["_pnl"][sid] = true -- Set before hook otherwise messages sent in hook would be queued.

    -- Before actually calling the hook, we directly call the sync function
    -- to allow netmessages to work within the PlayerNetLoad hook (has to be first).
    GNIL.Net._SyncNetworkIDs(ply)
    hook.Run("PlayerNetLoad", ply)
end

-- Use the dirty setupmove check to make sure that the client cant just block the
-- ready message and remain in a state of never recieving net messages.
MODULE:AddHook("PlayerInitialSpawn", "playerNetLoadedInit", function(ply)
    local setup_move_id = "pnl_" .. ply:SteamID64()
    MODULE:AddHook("SetupMove", setup_move_id, function(pl, _, cmd)
        if ply == pl and not cmd:IsForced() then
            _playerNetLoaded(pl)
            MODULE:RemoveHook("SetupMove", setup_move_id)
        end
    end)
end)

-- When a player disconnects, we should ensure that their steamid is removed
-- from the PlayerNetLoad table (so when they rejoin they can re-send the ready event)
MODULE:AddHook("PlayerDisconnected", "playerNetLoadedGc", function(ply)
    GNIL.Net["_pnl"][ply:SteamID()] = nil

    -- Remove the waiting setup move hook if there is one.
    MODULE:RemoveHook("SetupMove", "pnl_" .. ply:SteamID64())
end)
