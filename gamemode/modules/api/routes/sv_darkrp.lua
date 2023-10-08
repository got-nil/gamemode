
--[[

    GET /darkrp/{target:steamid64}
        Get a players rpname and current money/wallet. This
        works on both online/offline players.

    PATCH /darkrp/{target:steamid64}/money | [reason: string]
        Update a players money with the body 'amount' key.
        This can be positive or negative. (Player can be online/offline)

--]]

-- TODO: Make this middleware.
local function requireDarkRP()

    -- Make sure DarkRP is loaded (it isn't in test environments).
    if not DarkRP then
        return GNIL.API.Responses.JSON({
            success = false,
            error_message = "Missing required DarkRP base gamemode."
        }, 503)
    end
end

-- Return a response promise wrapper to handle offline player data
-- requests. Automatically returning a successful not-found response
-- if there is no data for the provided target.
local function DarkRPOfflineDataResponder(target, callback)
    return function(respond)
        DarkRP.offlinePlayerData(
            util.SteamIDFrom64(target),
            function(data)

                -- If there were no results returned in the query then
                -- the player must not exist (or its an invalid steamid).
                if data == nil or #data == 0 then
                    return respond(
                        GNIL.API.Responses.JSON({
                            success = true,
                            found = false
                        })
                    )
                end

                respond(
                    callback(data)
                )
            end
        )
    end
end

GNIL.API.Routes.Get("/darkrp/{target:steamid64}", function(request, args)

    -- Since there isn't middleware yet :(
    local response = requireDarkRP()
    if response then return response end

    local ply = player.GetBySteamID64(args.target)
    if ply then

        -- If the player is currently online we can return the
        -- values from cache which is faster than waiting for the
        -- database query results.
        return GNIL.API.Responses.JSON({
            success = true,
            found = true,
            data = {
                rpname = ply:getDarkRPVar("rpname"),
                money = tonumber(ply:getDarkRPVar("money"))
            }
        })
    end

    return DarkRPOfflineDataResponder(args.target, function(data)
        return GNIL.API.Responses.JSON({
            success = true,
            found = true,
            data = {
                rpname = data[1]["rpname"],
                money = tonumber(data[1]["wallet"])
            }
        })
    end)
end)

GNIL.API.Routes.Patch("/darkrp/{target:steamid64}/money", function(request, args)

    -- Since there isn't middleware yet :(
    local response = requireDarkRP()
    if response then return response end

    -- Support both GET and PATCH requests.
    local amount = tonumber(request.body:Get("amount", ""))
    if not amount then
        return GNIL.API.Responses.JSON({
            success = false,
            error_message = "Missing/Invalid 'amount' body argument."
        }, 400)
    else
        amount = math.floor(amount)
    end

    local ply = player.GetBySteamID64(args.target)
    if ply then

        -- Get the money var again instead of just doing (before + amount)
        -- since the 'playerWalletChanged' hook is called which could modify
        -- the total before its set.
        local before = tonumber(ply:getDarkRPVar("money"))
        ply:addMoney(amount)
        local after = tonumber(ply:getDarkRPVar("money"))

        return GNIL.API.Responses.JSON({
            success = true,
            found = true,
            data = {
                before = before,
                after = after
            }
        })
    end

    return DarkRPOfflineDataResponder(args.target, function(data)

        -- Get the before and after wallet/money amount, and then
        -- actually store the new money amount. The storeOfflineMoney
        -- func does not call any hooks, so we must ensure that the
        -- amount is not negative ourselves.
        local before = tonumber(data[1]["wallet"])
        local after = before + amount
        if after < 0 then after = 0 end
        if after != before then DarkRP.storeOfflineMoney(args.target, after) end

        return GNIL.API.Responses.JSON({
            success = true,
            found = true,
            data = {
                before = before,
                after = after
            }
        })
    end)
end)