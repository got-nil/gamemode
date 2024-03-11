--[[

    GET /players
        Get basic info about all online players. This
        also returns the current and max player count.

    GET /players/{target:steamid64}
        Get additional info about a player. This accepts a
        steamid64 instead of a player, allowing it to act as
        an online check (as it returns 'is_online' state).

    POST /players/{target:ply}/kick | [?reason: string]
        Kick an online player from the server with an optional
        reason provided in body.

--]]

-- All players basic info
GNIL.API.Routes.Get("/players", function(request)

    local players = {}
    for i, v in ipairs(player.GetAll()) do
        players[i] = {
            userid = v:UserID(),
            steamid64 = v:SteamID64(),
            usergroup = v:GetUserGroup(),
            name = v:Name()
        }
    end

    return GNIL.API.Responses.JSON({
        success = true,
        data = {
            players = players,
            count = {
                current = #players,
                max = game.MaxPlayers()
            }
        }
    })
end)

-- Player info (is_online etc). basically as
-- much info about the player as is possible.
GNIL.API.Routes.Get("/players/{target:steamid64}", function(request, args)

    -- Get the player from steamid. If the target isn't online, there
    -- isn't any data we can actually return. (See darkrp routes for offline data).
    local ply, data = player.GetBySteamID64(args.target), nil
    if ply then
        data = {
            userid = ply:UserID(),
            owner = ply:OwnerSteamID64(),
            name = ply:Name(),
            admin = ply:IsAdmin() or ply:IsSuperAdmin(),
            developer = ply:IsDeveloper(),
            usergroup = ply:GetUserGroup(),
            pos = ply:GetPos()
        }
    end
    return GNIL.API.Responses.JSON({
        success = true,
        is_online = ply != false,
        data = data
    })
end)

-- Kick player from server. Requires player to be online.
GNIL.API.Routes.Post("/players/{target:ply}/kick", function(request, args)

    -- Get reason string from body, only if its a string.
    local reason = request.body:Get("reason")
    if reason != nil and not isstring(reason) then
        reason = nil
    end

    -- Kick the player with reason and return success response.
    args.target:Kick(
        reason
    )
    return GNIL.API.Responses.JSON({
        success = true
    })
end)
