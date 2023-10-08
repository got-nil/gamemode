
-- Base server info
GNIL.API.Routes.Get("/server", function(request)

    -- Format all enabled modules name and author.
    local all_modules, modules = GNIL.Modules.GetAll(true), {}
    for k, v in pairs(all_modules) do
        if GNIL.Modules.IsLoaded(k) then
            modules[#modules + 1] = {
                name = v.name,
                author = v.author
            }
        end
    end

    return GNIL.API.Responses.JSON({
        success = true,
        data = {
            players = {
                current = player.GetCount(),
                max = game.MaxPlayers()
            },
            map = game.GetMap(),
            ip = game.GetIPAddress(),
            dedicated = game.IsDedicated(),
            modules = modules
        }
    })
end)
