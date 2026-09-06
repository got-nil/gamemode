
local MODULE, internal_messages = MODULE, {}
for _, v in ipairs(GNIL.Net["_netstrings"]) do
    internal_messages[v] = true
end

--[[

    This handles ratelimiting for default messages. Internal messages
    are ignored as they're handled in the reciever for sub message
    specific limits.

--]]

-- Localisation, potentially an optimisation?
local util_NetworkIDToString = util.NetworkIDToString
local net_ReadHeader = net.ReadHeader
local GNIL_Net_AntiAbuse_Abusing = GNIL.Net.AntiAbuse.Abusing
local GNIL_Net_AntiAbuse_Check = GNIL.Net.AntiAbuse.Check

---Detour all incomming messages and read header.
---@param len number
---@param ply Player
net.Incoming = function(len, ply)

    -- Get the original message name.
    local messageName = util_NetworkIDToString(net_ReadHeader())
    if not messageName then

        -- If the player is requesting an invalid/unknown message
        -- we should assume that they're being abusive (as normal
        -- code shouldn't be trying to use non-existant messages).
        -- (Although im fairly sure that can't happen?)
        GNIL_Net_AntiAbuse_Abusing(messageName, ply, true)
        return
    end

    -- Allow the server to block all incomming messages. This is
    -- used mainly to prevent receiving messages during a test.
    -- Only here as a sanity check, tests should not be ran live.
    if not GNIL.Net["_receive"] then
        MODULE:log("Message from " .. Either(ply, ply:ToString(), "'No Player'") .. " was rejected as receiver is disabled.", "warning")
        return
    end

    -- Find associated reciever.
    local reciever = net.Receivers[messageName:lower()]
    if not reciever then return end

    -- If its not an internal message (meaning its not using the
    -- GNIL net libary) we should apply a generic ratelimit.
    if not internal_messages[messageName] and not GNIL_Net_AntiAbuse_Check(messageName, ply, nil, true) then
        return
    end

    -- Call the original reciever if the bucket passed.
    -- Default message header is sent as 16 bit uint, should
    -- be removed from total message length to keep offset.
    reciever(len - 16, ply)
end
