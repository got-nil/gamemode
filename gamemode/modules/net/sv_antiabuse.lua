local MODULE = MODULE
GNIL.Net.AntiAbuse = GNIL.Net.AntiAbuse or {
    ["_r"] = {}, -- Internal buckets registry.
    ["_d"] = {}, -- Default messages buckets.
    ["_p"] = {}, -- Abuse player tracker buckets.

    -- Default bucket settings.
    -- msg = Default message bucket settings for individual messages.
    -- ply = Default player bucket settings for shared ratelimiting.
    -- BARE IN MIND, 'ply' BUCKET IS ONLY INCREASED WHEN 'msg' BUCKET IS EMPTY.
    defaults = {
        msg = {
            capacity = 25,
            delay = 1,
            amount = 1
        },
        ply = {
            capacity = 10,
            delay = 5,
            amount = 1
        }
    }
}

--[[

    Hello! Here is a quick explaination of how the server identifies network abuse.
    (A 'bucket' is used in ratelimiting as a limited token store: https://en.wikipedia.org/wiki/Token_bucket)

    1. Every network message, internal (using GNIL.Net.AddNetworkString) or default (using util.AddNetworkString)
       has a bucket created either when the message is pooled (internal messages can specify a ratelimit conf as
       second argument to AddNetworkString) or the first time the message is recieved on the server (for default messages).
       One bucket is able to handle multiple individual players.

    2. When a netmessage is recieved, the bucket "tested" to see if the player is able to make the request. If they're
       not (because they're being ratelimited) the message is blocked and the player is marked as "Abusing".

    3. When a player is "abusing" the network system, an individual bucket is created just for that one player. This
       is used to track the players abuse across multiple messages (internal or default). This ensures that a player isn't
       able to just rotate attack messages to avoid limiting.

--]]

function GNIL.Net.AntiAbuse.Abusing(messageName, ply, is_default_message)
    MODULE:log(ply:ToString() .. " is abusing " .. (is_default_message && "default" || "internal") .. " message '" .. messageName .. "'.", "debug")

    -- If the player does not yet have an abuse bucket, create one.
    local steamid, limits = ply:SteamID64(), GNIL.Net.AntiAbuse["defaults"]["ply"]
    if not GNIL.Net.AntiAbuse["_p"][steamid] then
        GNIL.Net.AntiAbuse["_p"][steamid] = GNIL.Net.Classes.Bucket:New(limits.capacity, limits.delay, limits.amount)
    end

    -- If the players own bucket is limited, then the player has sent
    -- multiple abusive net messages (could be across multiple messages).
    -- Here they should actually be sanctioned, kicking the player by default.
    if not GNIL.Net.AntiAbuse["_p"][steamid]:Check(steamid) then

        if hook.Run("GNIL.Net.AntiAbuse.IsAbusing", ply) == false then return end
        ply:Kick("Detected attempted network abuse patterns")
    end
end

function GNIL.Net.AntiAbuse.SetLimits(messageName, limits, is_default_message)

    -- Validate the ratelimits configuration structure.
    local defaults = GNIL.Net.AntiAbuse["defaults"]["msg"]
    local isvalid, out = GNIL.Validation.Structure(limits or {}, {
        ["capacity"] = {defaults.capacity, TYPE_NUMBER, false}, -- Max bucket capacity.
        ["delay"] = {defaults.delay, TYPE_NUMBER, false}, -- Delay between token refills.
        ["amount"] = {defaults.amount, TYPE_NUMBER, false} -- Token refill amount per delay.
    })
    if not isvalid then
        MODULE:log("Ratelimits configuration for message '" .. messageName .. "': " .. out, "error")
        return false
    end

    -- If the message bucket already exists, check if the provided config
    -- is the same to prevent needless discarding of previous bucket.
    local existingBucket = GNIL.Net.AntiAbuse["_r"][messageName]
    if existingBucket then

        -- If there is no limits config provided, or the provided config is
        -- the same as the existing bucket then we should not replace it.
        if not limits or existingBucket:IsSame(out.capacity, out.delay, out.amount) then
            return false
        end
        MODULE:log("Replacing existing ratelimiting bucket for message '" .. messageName .. "' with different config.", "debug")
    else
        MODULE:log("Creating ratelimit bucket for message '" .. messageName .. "'.", "debug")
    end

    -- Create/Replace the bucket store.
    GNIL.Net.AntiAbuse[is_default_message && "_d" || "_r"][messageName] = GNIL.Net.Classes.Bucket:New(out.capacity, out.delay, out.amount)
    return true
end

function GNIL.Net.AntiAbuse.Check(messageName, ply, reply, is_default_message)

    -- Allow developers to go ham.
    if ply and ply:IsDeveloper() then
        return true
    end

    -- If the message does not have any ratelimiting return.
    local bucket = GNIL.Net.AntiAbuse[is_default_message && "_d" || "_r"][messageName]
    if not bucket then

        -- If its a default message, create the ratelimit bucket if one doesn't
        -- already exist. This ensures that only used message buckets are pooled.
        if is_default_message then
            GNIL.Net.AntiAbuse.SetLimits(messageName, {}, is_default_message)
        end
        return true
    end

    -- Check that the players message is accepted by the message bucket.
    if bucket:Check(ply) then
        return true
    end
    GNIL.Net.AntiAbuse.Abusing(messageName, ply, is_default_message)

    -- If there is a message reply, set the ratelimited error.
    -- A default message does not have a reply, sanity check.
    if reply and not is_default_message then

        -- seconds_till: Seconds until message can be resent.
        reply:SetError(GNIL_NET_ERRORS_RATELIMITED, bucket.delay)
        reply:Send()
    end
    return false
end

function GNIL.Net.AntiAbuse.ApplyBaseRatelimits()

    -- Increased limits for base game stuff that spams net.
    local defaultLimits = {
        ["properties"] = {
            capacity = 50,
            delay = 1,
            amount = 5
        },
        ["editvariable"] = {
            capacity = 50,
            delay = 1,
            amount = 5
        }
    }
    for k, v in pairs(defaultLimits) do
        GNIL.Net.AntiAbuse.SetLimits(k, v, true)
    end
end

-- Remove the player from both registries and their personal bucket
-- if one exists. Basically just a gc to prevent a stale pool.
MODULE:AddHook("PlayerDisconnected", "antiAbuseGc", function(ply)
    local steamid = tostring(ply:SteamID64())
    for _, k in ipairs({"_r", "_d"}) do
        for _, v in pairs(GNIL.Net.AntiAbuse[k]) do
            v:Remove(steamid)
        end
    end
    GNIL.Net.AntiAbuse["_p"][steamid] = nil
end)
