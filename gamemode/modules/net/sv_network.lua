
-- Add the core required network strings.
local MODULE = MODULE
GNIL.Net["_q"] = GNIL.Net["_q"] or {}
GNIL.Net["_netstrings"] = {
    "gnil",   -- GNIL Network (default message entrypoint)
    "gnilc",  -- GNIL Chunked (chunked messages for large datasets)
    "gnils",  -- GNIL Sync (sync pooled netstrings between client and server)
    "gnilr"   -- GNIL Reply (message reply system)
}
for _, v in ipairs(GNIL.Net["_netstrings"]) do
    util.AddNetworkString(v)
end

-- This is used to sync the player netmessage pool between
-- the server and specified clients.
function GNIL.Net._SyncNetworkIDs(ply)
    GNIL.Net["_sent_netids"] = true

    net.Start("gnils")
        net.WriteUInt(#GNIL.Net["_r"], GNIL.Net["_idsize"])
        for _, v in ipairs(GNIL.Net["_r"]) do
            net.WriteString(v)
        end

    -- If there is a specified player, send it to the provided
    -- player specifically. If none is provided, broadcast to all.
    if ply then net.Send(ply) else net.Broadcast() end
end

-- Add network string alias, works the exact same.
function GNIL.Net.AddNetworkString(str, ratelimits, _d)
    assert(isstring(str), "The provided network string... must be a string.")
    assert(ratelimits == nil or istable(ratelimits), "The provided ratelimits must be nil or a ratelimits config table.")

    -- Prevent messages from being re-synced to clients.
    if GNIL.Net["_i"][str] then

        -- Allow ratelimits to be modified after the message creation.
        GNIL.Net.AntiAbuse.SetLimits(str, ratelimits)
        return false
    end

    -- Ensure that the idsize uint is always big enough to be able to send
    -- the newly created networkid. Cached in init file.
    local l = #GNIL.Net["_r"] + 1
    if GNIL.Net["_max_messages"] != nil and l > GNIL.Net["_max_messages"] then
        error("The configured network _idsize supports a maximum of " .. tostring(GNIL.Net["_max_messages"]) .. " messages!")
    else
        GNIL.Net["_r"][l] = str
        GNIL.Net["_i"][str] = l

        -- Set any provided ratelimits for the message.
        GNIL.Net.AntiAbuse.SetLimits(str, ratelimits)
    end

    -- If the netids have already been sent to a player, then this is a
    -- delayed pool addition (really bad for optimisation since we have to
    -- now re-broadcast the network ids to all players), so we complain.
    if _d != false and GNIL.Net["_sent_netids"] then
        MODULE:log("Network string '" .. str .. "' has been pooled late, which is VERY bad for optimisation.", "warning")
        GNIL.Net._SyncNetworkIDs()
    end

    return l
end

-- Add multiple network ids, with each argument being a string
-- network ID that should be pooled. (This is also better for
-- adding multiple delayed network ids, as it only resyncs once
-- the last message has been added, Although you shouldn't ever
-- need to add late messages anyway).
function GNIL.Net.AddNetworkStrings(...)
    local args, out = {...}, {}

    -- If the first argument is a table, use that instead.
    if #args >= 1 and istable(args[1]) then
        args = args[1]
    end
    for i, v in ipairs(args) do

        -- Add the network ID, while also only allowing the
        -- network ids to be resynced on the last message.
        -- (Although they shouldn't be added late anyway)
        out[v] = GNIL.Net.AddNetworkString(v, nil, i == #args)
    end
    return out
end

-- Send the network message to all players.
-- If a netmessage is provided, write it to stream and use the default
-- broadcast instead of sending each message individually.
function GNIL.Net.Broadcast(_nm)
    if _nm then

        -- Make sure there are actually players online before broadcasting.
        local players = player.GetAll()
        if #players == 0 then
            MODULE:log("Cannot broadcast message '" .. _nm.name .. "' as there are no players connected.", "debug")
            return
        end
        _nm:_WriteToStream(players)
    end
    net.Broadcast()
end

-- Send the net message to a given player. Like the
-- original send function this also supports CRecipientFilter
-- if you want to get fancy. (You can also use a table of players)
-- NetMessage instance can be provided as second argument to allow
-- for message queuing (and just being OOP which is automatically cool)
function GNIL.Net.Send(ply, _nm, _allowqueue)

    local t = TypeID(ply)
    if t == TYPE_RECIPIENTFILTER then

        -- If a recipient filter is provided, then we should simply get all
        -- the players that apply to the filter, and iteratively send the message
        -- to each of them.
        for _, v in ipairs(ply:GetPlayers()) do
            MODULE:log("Player in recipient filter for '" .. _nm.name .. "': " .. ply:ToString(), "debug")
            GNIL.Net.Send(v, _nm)
        end

    elseif t == TYPE_TABLE then

        -- If a table is provided, it must be a sequential table of players.
        assert(table.IsSequential(t), "If a table is provided, it must be a sequential table of players.")
        for i, v in ipairs(ply) do

            -- Don't bother validating the table value since the send functions
            -- will revalidate its type anyway. Micro optimisations add up 🙏
            GNIL.Net.Send(v, _nm)
        end

    elseif t == TYPE_ENTITY then

        -- If an entity is provided, then it must be a player.
        assert(ply:IsPlayer(), "If an entity is provided, it must be a player.")

        -- If a NetMessage instance is provided, and the player has not yet had
        -- their networking loaded then we should add the nm instance to the queue.
        local sid = ply:SteamID()
        if _allowqueue != false and not GNIL.Net.HasPlayerNetLoaded(sid) then
            if not GNIL.Net["_q"][sid] then
                GNIL.Net["_q"][sid] = {}
            end
            table.insert(GNIL.Net["_q"][sid], {ply, _nm})

            MODULE:log("Message '" .. _nm.name .. "' to player '" .. ply:Nick() .. "' has been queued ", "debug")
            return
        end

        -- If there is a netmessage provided, then we should actually write the
        -- network header and write buffer to the started net stream.
        if _nm then
            _nm:_WriteToStream({ply})
        end

        -- Actually send the message.
        net.Send(ply)

    else
        error("Unknown datatype input provided. May be a: CRecipientFilter, Player or sequential table of players.")
    end
end

-- When a player has loaded to the point where they can send/recieve
-- network messages, then we should send any messages that are queued.
MODULE:AddHook("PlayerNetLoad", "sendQueue", function(ply)

    -- Ensure that there actually are queued net
    -- messages for the loaded player's steamid.
    local sid = ply:SteamID()
    local messages = GNIL.Net["_q"][sid]
    if messages == nil then return end

    MODULE:log("Client '" .. ply:Nick() .. "' has netloaded, with messages queued. Sending now.", "debug")

    -- Send all of the messages within the queue.
    -- If the message still somehow fails to send, it
    -- will not be re-queued (to prevent loops).
    for _, v in ipairs(messages) do
        GNIL.Net.Send(v[1], v[2], false)
    end

    -- Empty the queue for the given player.
    GNIL.Net["_q"][sid] = {}
end)

-- Add an alias to the chunked send function.
function GNIL.Net.SendChunkedData(...) return GNIL.Net.Chunks.Send(...) end
