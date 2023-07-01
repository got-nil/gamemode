
local internal_messages = {}
for _, v in ipairs(GNIL.Net["_netstrings"]) do
    internal_messages[v] = true
end

--[[

    This handles ratelimiting for default messages. Internal messages
    are ignored as they're handled in the reciever for sub message
    specific limits.

--]]

-- Detour all incomming messages and read header.
net.Incoming = function(len, ply)
    
    -- Get the original message name.
    local messageName = util.NetworkIDToString(net.ReadHeader())
    if not messageName then
        
        -- If the player is requesting an invalid/unknown message
        -- we should assume that they're being abusive (as normal
        -- code shouldn't be trying to use non-existant messages).
        -- (Although im fairly sure that can't happen?)
        GNIL.Net.AntiAbuse.Abusing(messageName, ply, true)
        return
    end

    -- Find associated reciever.
    local reciever = net.Receivers[messageName:lower()]
    if not reciever then return end

    -- Default message header is sent as 16 bit uint, should
    -- be removed from total message length to keep offset.
    len = len - 16

    -- If its not an internal message (meaning its not using the
    -- GNIL net libary) we should apply a generic ratelimit.
    if not internal_messages[messageName] and not GNIL.Net.AntiAbuse.Check(messageName, ply, nil, true) then
        return
    end
    
    -- Call the original reciever if the bucket passed.
    reciever(len - 16, ply)
end
