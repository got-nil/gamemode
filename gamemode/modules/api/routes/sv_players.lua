
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

-- Get the reason string from the request body, ignoring non-strings.
local function getReason(request)
    local reason = request.body:Get("reason")
    if reason != nil and not isstring(reason) then
        reason = nil
    end
    return reason
end

-- Kick player from server. Requires player to be online.
GNIL.API.Routes.Post("/players/{target:ply}/kick", function(request, args)

    -- Kick the player with reason and return success response.
    args.target:Kick(
        getReason(request)
    )
    return GNIL.API.Responses.JSON({
        success = true
    })
end)
