
GNIL.API.Routes.Get("/darkrp/{target:steamid64}", function(request)

    local ply = player.GetBySteamID64(request.args["target"])
    if ply then
        
        -- If the player is currently online we can return the
        -- values from cache which is faster than waiting for the
        -- database query results.
        return GNIL.API.Responses.JSON({
            success = true,
            found = true,
            data = {
                rpname = ply:getDarkRPVar("rpname"),
                wallet = tonumber(ply:getDarkRPVar("wallet"))
            }
        })
    end
    
    -- If the player is offline, instead return a response promise.
    -- The router then returns a callback that can be called with the
    -- query response from the database.
    return function(respond)
        DarkRP.offlinePlayerData(
            util.SteamIDFrom64(request.args["target"]),
            function(data)

                -- If there were no results returned in the query then
                -- the player must not exist (or its an invalid steamid).
                if #data == 0 then
                    respond(
                        GNIL.API.Responses.JSON({
                            success = true,
                            found = false
                        }, 400)
                    )
                end

                -- Respond to the request with playerdata.
                respond(
                    GNIL.API.Responses.JSON({
                        success = true,
                        found = true,
                        data = {
                            rpname = data[1]["rpname"],
                            wallet = tonumber(data[1]["wallet"])
                        }
                    })
                )
            end
        )
    end
end)