local MODULE = MODULE
GNIL.Net.AntiAbuse = GNIL.Net.AntiAbuse or {
    ["_r"] = {},
    ["_p"] = {}
}

function GNIL.Net.AntiAbuse.SetLimits(messageName, limits)

    -- Validate the ratelimits configuration structure.
    local isvalid, out = GNIL.Validation.Structure(limits, {
        ["max"] = {0, TYPE_NUMBER, true},
        ["delay"] = {1, TYPE_NUMBER, false}
    })
    if not isvalid then
        MODULE:log("Ratelimits configuration for message '" .. messageName .. "': " .. out, "warning")
        return false
    end
    
    -- Create the bucket store.
    GNIL.Net.AntiAbuse["_r"][messageName] = GNIL.Net.Classes.Bucket:New(limits.max, limits.delay)
    return true
end

function GNIL.Net.AntiAbuse.Check(messageName, ply, reply)

    -- If the message does not have any ratelimiting return.
    local bucket = GNIL.Net.AntiAbuse["_r"][messageName]
    if not bucket then
        return true
    end

    -- Check that the players message is accepted by the message bucket.
    if bucket:Check(ply) then
        return true
    end

    -- If there is a message reply, set the ratelimited error.
    if reply then

        -- seconds_till: Seconds until message can be resent.
        reply:SetError(GNIL_NET_ERRORS_RATELIMITED, bucket.delay)
        reply:Send()
    end
    return false
end

hook.Add("PlayerDisconnected", "gnil_net_antiabuse_gc", function(ply)
    local steamid = tostring(ply:SteamID64())
    for _, v in pairs(GNIL.Net.AntiAbuse["_r"]) do
        v:Remove(steamid)
    end
end)