
/*
    Route arguments support strict type specification.
    These can be used for pre-route validation such as
    ensuring an argument is an int (or in this case a
    valid steamid64).

    By default, a global server is started and routes
    are added to that when using the static router methods.
    However, as everything is designed entirely in classes
    you could run multiple seperate HTTP servers (on diff ports)
    with seperate routers (and therefore seperate routes). 

*/ 
GNIL.API.Routes.Get("/player/{target:ply}", function(request)
    local ply = request.args["target"]
    return GNIL.API.Responses.JSON({
        name = ply:Nick(),
        pos = ply:GetPos()
    })
end)
