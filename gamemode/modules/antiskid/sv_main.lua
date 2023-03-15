
-- A cheater has been detected.
function GNIL.AntiSkid.Cheater(ply, check)

    -- TODO: Submit with nonerd.

    GNIL.log("According to skidcheck " .. ply:ToString() .. " is cheating.", "info")
    --ply:Ban(0, "Cheater, and not even a good one.")
end

-- Add a check to be used as a cheater test.
function GNIL.AntiSkid.AddCheck(check)
    if not (check.class && check.class.name == "SkidCheck") then return end
    GNIL.AntiSkid["_checks"][check.name] = check
end
