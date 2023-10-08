
-- Make sure a players wallet never goes negative.
hook.Add("playerWalletChanged", "GNIL.DarkRP.NoNegativeMoney", function(ply, amount, wallet)
    local total = wallet + amount
    if total < 0 then return 0 end
end)
