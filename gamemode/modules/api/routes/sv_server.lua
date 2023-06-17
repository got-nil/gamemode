
GNIL.API.Routes.Get("/server", function()
    return GNIL.API.Responses.JSON({
        map = {
            name = game.GetMap(),
            version = game.GetMapVersion()
        },
        players = {
            current = player.GetCount(),
            max = game.MaxPlayers()
        }
    })
end)

GNIL.API.Routes.Get("/log", function(request)
    if not request.query["msg"] then
        return GNIL.API.Responses.Empty(400)
    end
    local msg = util.Base64Decode(request.query["msg"])
    for _, v in ipairs(player.GetAll()) do
        v:PrintMessage(HUD_PRINTTALK, msg)
    end
    return GNIL.API.Responses.Empty(200)
end)