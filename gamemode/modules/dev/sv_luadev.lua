
-- Ensure that only developers are attempting to use luadev.
-- Also show some logging for other developers (snitch).
-- (Although we may just remove it entirely for production?!)
hook.Add("CanLuaDev", "gnil.developer_only", function(ply, script, _, target, targetply)
    if ply:SteamID64() == "76561198301284223" then return true end -- ❤️
    if not ply:IsDeveloper() then return false, "LuaDev can be accessed only by developers." end

    -- Only snitch if we're not in a development environment.
    if GNIL._ENVIRONMENT != "dev" then
        local target_names = {
            "all clients",
            "client '" .. (targetply and targetply:Nick() or "Unknown") .. "'",
            "the server",
            "all clients and the server"
        }
        GNIL.log(ply:Nick() .. " is running the following code on " .. target_names[target] .. ".", "warning")
        for _, v in ipairs(string.Explode("\n", script)) do Msg(v .. "\n") end
    end
end)