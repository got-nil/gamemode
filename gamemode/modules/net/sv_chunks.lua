local MODULE = MODULE
GNIL.Net.Chunks = GNIL.Net.Chunks or {
    ["return_codes"] = {},
    ["max_chunk_size"] = 65500,
    ["chunk_rate"] = 1 / 2
}

---@param ply Player
---@param message string
---@param data string|string[]
---@param verify_checksum? boolean
---@param callback? fun(success: boolean, error_message: string?): nil
function GNIL.Net.Chunks.Send(ply, message, data, verify_checksum, callback)
    assert(IsEntity(ply) and ply:IsPlayer(), "The provided player argument must be a player entity")
    assert(isstring(message), "The message name argument provided must be a string")
    assert(isstring(data) or (istable(data) and table.IsSequential(data)), "The data argument to be chunked may either be a string, or a sequential table of strings")
    assert(verify_checksum == nil or isbool(verify_checksum), "The verify_checksum argument must be nil or a bool value")
    assert(callback == nil or isfunction(callback), "The callback argument must be null or a function")

    -- Get the messageid from the given message string to validate
    -- that it actually exists (this id is also sent in some chunks)
    local messageid = GNIL.Net.NetworkStringToID(message)
    if messageid == 0 then
        MODULE:log("Unknown/Unpooled message '" .. message .. "', refusing to send chunked data.", "error")
        return
    end

    local has_header, header, header_size = istable(data), "", 0
    if has_header then ---@cast data string[]

        -- A header and a buffer is created. The header is a comma seperated
        -- string of integers each representing the string length of an individual
        -- data string within the buffer. The buffer is simply all the data strings
        -- concatenated. Once both have been written, the data becomes the header
        -- followed by the buffer, with the terminating chunk sending the header
        -- size to be decoded by the client.
        local headers, buffer = {}, ""
        for i, v in ipairs(data) do
            assert(isstring(v), "All data values must be strings")

            table.insert(headers, #v)
            buffer = buffer .. v
        end

        -- Convert the header to a string seperated by commas.
        header = table.concat(headers, ",")
        header_size = string.len(header)

        -- Format the data as described above.
        data = header .. buffer
    end
    ---@cast data string

    -- Create a return code that is used by the client to identify
    -- the chunks being sent (allows for multiple to be sent to the
    -- same message at the same time without conflict).
    local return_code
    while true do
        return_code = tostring(math.random(1023, 32767)) -- 15 bits
        if not GNIL.Net.Chunks["return_codes"][return_code] then
            break
        end
    end

    GNIL.Net.Chunks["return_codes"][return_code] = {ply:SteamID64(), verify_checksum == true and util.CRC(data) or nil, callback}

    -- Calculate the amount of chunks that are required to send all data.
    local chunk_count = math.ceil(string.len(data) / GNIL.Net.Chunks["max_chunk_size"])
    MODULE:log("Sending " .. chunk_count .. " chunks to " .. ply:Nick() .. ", message '" .. message .. "' (" .. messageid .. ") with return code '" .. return_code .. "'", "debug")

    -- Iterate over all chunks sending each in a timer to ensure that
    -- the client isn't overwhelmed.
    for i = 1, chunk_count + 1 do
        timer.Simple(GNIL.Net.Chunks["chunk_rate"] * (i - 1), function()
            if not IsValid(ply) then return end -- Ensure the player is still valid
            local final_chunk, chunk, chunk_size = i > chunk_count, nil, 0

            if not final_chunk then
                chunk = string.sub(data, (i - 1) * GNIL.Net.Chunks["max_chunk_size"] + 1, i * GNIL.Net.Chunks["max_chunk_size"])
                chunk_size = string.len(chunk)
            end

            -- If the return code is nil then we should just return, as
            -- a previous chunk has failed, or the client has rejected
            -- the first chunk. (For whatever reason).
            if GNIL.Net.Chunks["return_codes"][return_code] == nil then return end

            net.Start("gnilc") -- Start netmessage
            net.WriteUInt(tonumber(return_code), 15) -- The return id
            net.WriteBool(final_chunk) -- Used to indicate if this is the last chunk

            -- Standard chunk message. If this is the first message,
            -- then we should send some additional data to the client
            -- (specifying the message id target).
            if not final_chunk then
                net.WriteUInt(chunk_size, 16) -- Size of the data being sent
                net.WriteData(chunk, chunk_size) -- Write the actual data

                -- If its the first message, send the id to validate that
                -- the client has required chunk reciever.
                if i == 1 then
                    net.WriteUInt(messageid, GNIL.Net["_idsize"])
                end

            else
                -- Terminating message, send checksum (if enabled) and the target message id
                net.WriteBool(verify_checksum == true) -- Checksum existance
                if verify_checksum == true then net.WriteString(GNIL.Net.Chunks["return_codes"][return_code][2]) end -- Checksum?
                net.WriteUInt(messageid, GNIL.Net["_idsize"]) -- Target message id

                -- If the data contains a header with individual length data, then we should
                -- inform the client of this and give the header size so it can decode.
                net.WriteBool(has_header)
                if has_header then
                    net.WriteUInt(header_size, 32) -- Just incase 😉
                end
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
        MODULE:log("Player '" .. ply:Nick() .. "' attempted to use a chunk returnid that does not belong to them.", "warning")
        return
    end

    -- Read the success bool (and if unsuccessful also read the error message)
    local success, error_message = net.ReadBool(), nil
    if not success then error_message = net.ReadString() end
    MODULE:log("Player '" .. ply:Nick() .. "' sent a " .. (success and "successful response" or "unsuccessful response ('" .. error_message .. "')") .. " to returnid '" .. return_code .. "'", "debug")

    -- If there is a callback associated with the return code
    -- then we should call that now with the return values.
    if return_data[3] then return_data[3](success, error_message) end
end)