
-- The return message name is a random string to stop dumbasses
-- from trying to filter out the specific name used.
GNIL.Net.AddNetworkString(GNIL.AntiSkid["_message_name"])

GNIL.Net.Receive(GNIL.AntiSkid["_message_name"], function(len, ply)
    local identifier, using_callback_id, callback_id = net.ReadString(), net.ReadBool(), nil
    if using_callback_id then
        callback_id = net.ReadString()
    end

    -- Find the message identifier in any registered checks.
    for _, check in pairs(GNIL.AntiSkid["_checks"]) do
        if identifier == check:GetNetIdentifier(ply) then

            -- If the check is waiting for the player to respond, then reset
            -- it so the check doesn't try to trigger NoResponse.
            local sid = ply:SteamID64()
            if check._net_waiting_for[sid] then
                check._net_waiting_for[sid] = false
            end

            -- Actually call the check reciever and call the callback if
            -- one was provided (by callback identifier).
            local out = check:Receive(len, ply)
            if using_callback_id then
                local callback = check._net_callbacks[callback_id]
                if not callback then
                    GNIL.log(ply:ToString() .. " sent a network message to AntiSkid reciever with an invalid callback ID. Weird.", "warning")
                    return
                end
                callback(true, out)
            end
            return
        end
    end

    -- If the identifier doesn't exist, assume the player is
    -- cheating anyway since why else would they be sending
    -- messages to the anticheat reciever??
    GNIL.log(ply:ToString() .. " has sent an invalid message to the SkidCheck reciever, they're probably a cheater.", "info")
    GNIL.AntiSkid.Cheater(ply, "NetRecieve")
end)