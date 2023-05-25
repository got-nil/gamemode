
-- Add the core required network strings.
local MODULE, netstrings = MODULE, {
    "gnil",   -- GNIL Network (default message entrypoint)
    "gnilc",  -- GNIL Chunked (chunked messages for large datasets)
    "gnils",  -- GNIL Sync (sync pooled netstrings between client and server)
    "gnilr"   -- GNIL Reply (message reply system)
}
for _, v in ipairs(netstrings) do
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
function GNIL.Net.AddNetworkString(str, _d)
    assert(isstring(str), "The provided network string... must be a string.")

    local l = #GNIL.Net["_r"] + 1
    GNIL.Net["_r"][l] = str
    GNIL.Net["_i"][str] = l

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
    local args = {...}

    -- If the first argument is a table, use that instead.
    if #args >= 1 and istable(args[1]) then
        args = args[1]
    end
    for i, v in ipairs(args) do

        -- Add the network ID, while also only allowing the
        -- network ids to be resynced on the last message.
        -- (Although they shouldn't be added late anyway)
        GNIL.Net.AddNetworkString(v, i == #args)
    end
end