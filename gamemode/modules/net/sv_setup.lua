
-- Add the core required network strings.
local netstrings = {
    "gnil",   -- GNIL Network (default message entrypoint)
    "gnilr",  -- GNIL Ready (sent when the client is ready to receive net messages)
    "gnilc",  -- GNIL Chunked (chunked messages for large datasets)
    "gnils"   -- GNIL Sync (sync pooled netstrings between client and server)
}
for _, v in ipairs(netstrings) do
    util.AddNetworkString(v)
end

-- This is used to sync the player netmessage pool between
-- the server and specified clients.
local function syncNetworkIDs(ply)
    net.Start("gnils")
        net.WriteUInt(#GNIL.Net["_r"], GNIL.Net["_idsize"])
        for _, v in ipairs(GNIL.Net["_r"]) do
            net.WriteString(v)
        end

    -- If there is a specified player, send it to the provided
    -- player specifically. If none is provided, broadcast to all.
    if ply then net.Send(ply) else net.Broadcast() end
end

-- When a player has loaded (and they're able to recieve net messages)
-- we should send the netmessage pool back to the client.
hook.Add("PlayerNetLoad", "gnil_net_sync", function(ply)
    syncNetworkIDs(ply)
end)

-- Add network string alias, works the exact same.
function GNIL.Net.AddNetworkString(str)
    local l = #GNIL.Net["_r"] + 1
    GNIL.Net["_r"][l] = str
    GNIL.Net["_i"][str] = l
    return l
end
