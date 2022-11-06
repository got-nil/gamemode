
GNIL.Net.Chunks = GNIL.Net.Chunks or {
    ["return_codes"] = {},
    ["max_chunk_size"] = 65500,
    ["chunk_rate"] = 1 / 2
}

function GNIL.Net.Chunks.Send(ply, message, data, verify_checksum, callback)
    assert(IsEntity(ply) and ply:IsPlayer(), "The provided player argument must be a player entity")
    assert(isstring(message), "The message name argument provided must be a string")
    assert(isstring(data), "The data argument to be chunked must be a string")
    assert(verify_checksum == nil or isbool(verify_checksum), "The verify_checksum argument must be nil or a bool value")
    assert(callback == nil or isfunction(callback), "The callback argument must be null or a function")

    -- Get the messageid from the given message string to validate
    -- that it actually exists (this id is also sent in some chunks)
    local messageid = GNIL.Net.NetworkStringToID(message)
    if messageid == 0 then
        GNIL.log("Unknown/Unpooled message '" .. message .. "', refusing to send chunked data.", "debug")
        return
    end

    -- Create a return code that is used by the client to identify
    -- the chunks being sent (allows for multiple to be sent to the
    -- same message at the same time without conflict).
    local return_code = tostring(math.random(1023, 32767)) -- 15 bits
    GNIL.Net.Chunks["return_codes"][return_code] = {ply:SteamID64(), verify_checksum == true and util.CRC(data) or nil, callback}

    -- Calculate the amount of chunks that are required to send all data.
    local chunk_count = math.ceil(string.len(data) / GNIL.Net.Chunks["max_chunk_size"])
    GNIL.log("Sending " .. chunk_count .. " chunks to " .. ply:Nick() .. ", targetting message '" .. message .. "' with return code '" .. return_code .. "'", "debug")

    -- Iterate over all chunks sending each in a timer to ensure that
    -- the client isn't overwhelmed.
    for i = 1, chunk_count do
        timer.Simple(GNIL.Net.Chunks["chunk_rate"] * (i - 1), function()
            local chunk = string.sub(data, (i - 1) * GNIL.Net.Chunks["max_chunk_size"] + 1, i * GNIL.Net.Chunks["max_chunk_size"])
            local chunk_size = string.len(chunk)

            -- If the return code is nil then we should just return, as
            -- a previous chunk has failed, or the client has rejected
            -- the first chunk. (For whatever reason).
            if GNIL.Net.Chunks["return_codes"][return_code] == nil then return end
            
            net.Start("gnilc") -- Start netmessage
            net.WriteUInt(tonumber(return_code), 15) -- The return id
            net.WriteUInt(chunk_size, 16) -- Size of the data being sent
            net.WriteData(chunk, chunk_size) -- Write the actual data
            net.WriteBool(i == chunk_count) -- Used to indicate if this is the last chunk

            if i != chunk_count then
                -- Standard chunk message. If this is the first message,
                -- then we should send some additional data to the client
                -- (specifying the message id target).
                if i == 1 then
                    net.WriteUInt(messageid, GNIL.Net["_idsize"])               
                end
            
            else
                -- Terminating message, send checksum (if enabled) and the target message id
                net.WriteBool(verify_checksum == true) -- Checksum existance
                if verify_checksum == true then net.WriteString(GNIL.Net.Chunks["return_codes"][return_code][2]) end -- Checksum?
                net.WriteUInt(messageid, GNIL.Net["_idsize"]) -- Target message id
            end

            -- Finally send the constructed message to the client
            net.Send(ply)
        end)
    end
end

net.Receive("gnilc", function(len, ply)
    
    -- Get the return code from the netmessage to correlate to
    -- the returncodes table (to validate response id)
    local return_code = tostring(net.ReadUInt(15))
    local return_data = GNIL.Net.Chunks["return_codes"][return_code]
    if return_data == nil then return end
    GNIL.Net.Chunks["return_codes"][return_code] = nil -- Invalidate return code

    -- Validate that the calling player matches the specified
    -- return code original player (verify ownership)
    if return_data[1] != ply:SteamID64() then
        GNIL.log("Player '" .. ply:Nick() .. "' attempted to use a chunk returnid that does not belong to them.", "warning")
        return
    end

    -- Read the success bool (and if unsuccessful also read the error message)
    local success, error_message = net.ReadBool(), nil
    if not success then error_message = net.ReadString() end
    GNIL.log("Player '" .. ply:Nick() .. "' sent a " .. (success and "successful response" or "unsuccessful response ('" .. error_message .. "')") .. " to returnid '" .. return_code .. "'", "debug")

    -- If there is a callback associated with the return code
    -- then we should call that now with the return values.
    if return_data[3] then return_data[3](success, error_message) end
end)