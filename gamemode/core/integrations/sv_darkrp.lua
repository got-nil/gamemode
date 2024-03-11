
-- Make sure a players wallet never goes negative.
hook.Add("playerWalletChanged", "GNIL.DarkRP.NoNegativeMoney", function(ply, amount, wallet)
    local total = wallet + amount
    if total < 0 then return 0 end
end)

-- Used to prevent darkrp gamemode from lua refreshing.
-- Edit: At the top of both files, add the hook line.
-- Files: darkrp/gamemode/<init.lua, cl_init.lua>
-- Code:
--   if hook.Run("DarkRPInit") == false then return end
hook.Add("DarkRPInit", "gnil_luarefresh", function()

    -- If we're already loaded (luarefresh) + darkrp is already loaded + the
    -- DARKRP_REFRESH env setting is off then the darkrp reload should be stopped.
    if GNIL._LOADED and not GNIL.ENV.DARKRP_REFRESH then
        return false
    end
end)