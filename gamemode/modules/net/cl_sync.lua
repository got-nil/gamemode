
-- Receive ID pool sync from the server and store it.
-- Pretty simple really, although it should be remembered
-- that the recieved table will have hashed keys.

net.Receive("gnils", function()
    local network_strings = {}
    local network_ids = {}

    for i = 1, net.ReadUInt(GNIL.Net["_idsize"]) do
        local network_string = net.ReadString()
        if network_string == "" then break end

        -- Store the network ID for the registry, and the
        -- id cache (just registry but reversed for optimisation).
        network_strings[i] = network_string
        network_ids[network_string] = i
    end
    GNIL.log("Read " .. #network_strings .. " network strings from server.", "debug")

    -- Overwrite current cached values in place of new ones.
    GNIL.Net["_r"] = network_strings
    GNIL.Net["_i"] = network_ids
end)
