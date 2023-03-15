
-- The return message name is a random string to stop dumbasses
-- from trying to filter out the specific name used.
GNIL.Net.AddNetworkString(GNIL.AntiSkid["_message_name"])

GNIL.Net.Receive(GNIL.AntiSkid["_message_name"], function(len, ply)
    local identifier = net.ReadString()

    -- Find the message identifier in any registered checks.
    for _, check in pairs(GNIL.AntiSkid["_checks"]) do
        if identifier == check:GetNetIdentifier(ply) then

            -- If the check is waiting for the player to respond, then reset
            -- it so the check doesn't try to trigger NoResponse.
            local sid = ply:SteamID64()
            if GNIL.AntiSkid["_waiting_for"][sid] and GNIL.AntiSkid["_waiting_for"][sid][check.name] then
                GNIL.AntiSkid["_waiting_for"][sid][check.name] = false
            end

            -- Actually call the check reciever.
            check:Receive(len, ply)
            return
        end
    end

    -- If the identifier doesn't exist, assume the player is
    -- cheating anyway since why else would they be sending
    -- messages to the anticheat reciever??
    GNIL.log(ply:ToString() .. " has sent an invalid message to the SkidCheck reciever, they're probably a cheater.", "info")
    GNIL.AntiSkid.Cheater(ply, "NetRecieve")
end)