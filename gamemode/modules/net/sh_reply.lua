local MODULE = MODULE
GNIL.Net.Reply = GNIL.Net.Reply or {
    ["_waiting"] = {},
    ["_default_timeout"] = 5
}

function GNIL.Net.Reply._StartReplyMessage(reply_id, reply_success, error_enum, error_int)
    MODULE:log("Writing reply message '" .. reply_id .. "', state: " .. (reply_success && "success" || "unsuccessful"), "debug")

    net.Start("gnilr")
    net.WriteUInt(tonumber(reply_id), 15)
    net.WriteBool(reply_success)

    -- If the reply was unsuccessful, also write the error enum. If
    -- there is an error_int provided, also write that (with signal).
    if not reply_success then
        net.WriteUInt(error_enum, 3)
        net.WriteBool(error_int != nil)
        if error_int != nil then net.WriteUInt(error_int, 16) end
    end
end

function GNIL.Net.Reply.IsValidReplyID(reply_id)
    if not isnumber(reply_id) then return false end
    return reply_id >= 1023 and 32767 >= reply_id
end

function GNIL.Net.Reply.ReceiverWrap(reply_id, reciever_out, ply)

    -- Only allow the reciever to return a valid NetworkReply
    -- or 'false' (meaning error) to allow for async operations.
    local reply_success = IsClass(reciever_out, "NetworkReply")
    if not (reply_success or reciever_out == false) then
        return
    end

    -- If theres a reply provided, check it for errors.
    local error_enum, error_int = false, 0
    if reciever_out != false then
        reply_success = reciever_out._error.enum == false

        -- If the reply was unsuccesful get the enum and int
        -- to write in the reply header.
        if not reply_success then
            error_enum = reciever_out._error.enum
            error_int = reciever_out._error.int
        end
    end

    -- The reply is only successful when a valid
    -- NetworkReply object is returned from the reciever.
    GNIL.Net.Reply._StartReplyMessage(reply_id, reply_success, error_enum, error_int)
    if reply_success then
        reciever_out:_WriteBufferToStream()
    end
    if SERVER then net.Send(ply) else net.SendToServer() end
end

function GNIL.Net.Reply.WriteHeader(targets, callback, timeout)
    assert(isfunction(callback), "Provided reply callback must be a function.")
    assert(timeout == nil or (isnumber(timeout) and timeout > 0), "Provided timeout must either be a number greater than 0, or nil for default.")

    -- Messages from the server must include a table of
    -- players to accept responses from.
    local message_targets = {}
    if SERVER then
        assert(targets == nil or (istable(targets) and table.IsSequential(targets) and #targets > 0), "Provided targets must be a table of one or more players, or nil.")

        -- If there are targets provided, ensure they're
        -- all players before storing.
        if targets != nil then
            for _, v in ipairs(targets) do
                assert(IsPlayer(v), "If a table of targets is provided, they should all be players.")
                message_targets[v] = true
            end
        end
    end

    -- Generate a reply_id that isn't in-use.
    local reply_id
    while true do
        reply_id = tostring(math.random(1023, 32767)) -- 15 bits
        if not GNIL.Net.Reply["_waiting"][reply_id] then
            break
        end
    end
    MODULE:log("Sending reply_id header '" .. reply_id .. "'.", "debug")

    -- Store the reply_id with callback and targets.
    GNIL.Net.Reply["_waiting"][reply_id] = {
        time = os.time(),
        timeout = timeout or GNIL.Net.Reply["_default_timeout"],
        callback = callback,
        targets = message_targets
    }

    -- Write the reply_id as a uint.
    net.WriteUInt(tonumber(reply_id), 15)
    return reply_id
end

net.Receive("gnilr", function(len, ply)

    -- Read reply_id string and reply_success status.
    local offset = 16 -- reply_id + reply_success
    local reply_id, reply_success = tostring(net.ReadUInt(15)), net.ReadBool()
    if not GNIL.Net.Reply["_waiting"][reply_id] then
        return
    end

    -- Read error enum data and error int for reply errors.
    local error_enum, error_int = false, 0
    if not reply_success then
        offset = offset + 4 -- error_enum + has_error_int
        error_enum, has_error_int = net.ReadUInt(3), net.ReadBool()
        if has_error_int then
            offset = offset + 16 -- error_int
            error_int = net.ReadUInt(16)
        end

        -- Validate the recieved error enum.
        if error_enum == 0 or error_enum > GNIL_NET_ERRORS_COUNT then
            MODULE:log("Recieved unsuccessful reply with an invalid error_enum.", "warning")

            -- Fallback to an error failure state.
            error_enum = GNIL_NET_ERRORS_FAIL
        end
    end

    local reply_data = GNIL.Net.Reply["_waiting"][reply_id]
    local should_delete = true

    if SERVER then

        -- Ensure the replying player is actually a target.
        if reply_data.targets[ply] == nil then
            MODULE:log("Player " .. ply:ToString() .. " attempted to reply to a message they're not a target of.", "warning")
            return
        end

        -- Prevent multiple responses to the same message.
        if reply_data.targets[ply] == false then
            return
        end

        -- Set the responding player as a responder. Then
        -- check all other targets to see if everyone has
        -- replied yet.
        reply_data.targets[ply] = false
        for k, v in pairs(reply_data.targets) do
            if v then
                should_delete = false
                break
            end
        end
    end

    -- Finally call the reply callback and delete reply_id
    -- if required (always on client, or when all have replied for server).
    reply_data.callback(reply_success, len - offset, ply, {
        enum = error_enum,
        int = error_int
    })
    if should_delete then
        MODULE:log("Removing reply_id: " .. reply_id, "debug")
        GNIL.Net.Reply["_waiting"][reply_id] = nil
    end
end)

-- Reply factory (and an easier alias).
function GNIL.Net.Reply.Create(reply_id, ply) return GNIL.Net.Classes.Reply:New(reply_id, ply) end
GNIL.Net.CreateReply = GNIL.Net.Reply.Create

timer.Create("gnil_net_reply_gc", 1, 0, function()

    -- Timeout error object provided to callback.
    local timeout_error = {
        enum = GNIL_NET_ERRORS_TIMEOUT,
        int = 0
    }

    local toDelete = {}
    for k, v in pairs(GNIL.Net.Reply["_waiting"]) do
        if os.time() > (v.time + v.timeout) then
            MODULE:log("NetworkReply '" .. k .. "' has timedout.", "debug")

            if SERVER then

                -- Run the callback with each player that is
                -- still being waited for as unsuccesful.
                for ply, waiting in pairs(v.targets) do
                    if waiting then
                        v.callback(false, 0, ply, timeout_error)
                    end
                end
            else
                v.callback(false, 0, nil, timeout_error)
            end
            table.insert(toDelete, k)
        end
    end

    -- Avoid modifying in the loop.
    if #toDelete > 0 then
        for _, v in ipairs(toDelete) do
            GNIL.Net.Reply["_waiting"][v] = nil
        end
    end
end)