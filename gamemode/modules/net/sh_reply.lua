local MODULE = MODULE
GNIL.Net.Reply = GNIL.Net.Reply or {
    ["_waiting"] = {},
    ["_default_timeout"] = 5
}

function GNIL.Net.Reply._StartReplyMessage(reply_id, reply_success)
    MODULE:log("Writing reply message '" .. reply_id .. "', state: " .. (reply_success && "success" || "unsuccessful"), "debug")
    
    net.Start("gnilr")
    net.WriteUInt(tonumber(reply_id), 15)
    net.WriteBool(reply_success)
end

function GNIL.Net.Reply.IsValidReplyID(reply_id)
    assert(isnumber(reply_id), "The reply_id should already be a number")
    return reply_id >= 1023 and 32767 >= reply_id
end

function GNIL.Net.Reply.ReceiverWrap(reply_id, reciever_out, ply)

    -- Only allow the reciever to return a valid NetworkReply
    -- or 'false' (meaning error) to allow for async operations.
    local reply_success = IsClass(reciever_out, "NetworkReply")
    if not (reply_success or reciever_out == false) then
        return
    end

    -- The reply is only successful when a valid
    -- NetworkReply object is returned from the reciever.
    GNIL.Net.Reply._StartReplyMessage(reply_id, reply_success)
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
        assert(istable(targets) and table.IsSequential(targets) and #targets > 0, "Provided targets must be a table of one or more players.")

        -- If there are targets provided, ensure they're
        -- all players before storing.
        if istable(targets) then
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
end

net.Receive("gnilr", function(len, ply)

    -- Read reply_id string and reply_success status.
    local reply_id, reply_success = tostring(net.ReadUInt(15)), net.ReadBool()
    if not GNIL.Net.Reply["_waiting"][reply_id] then
        return
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
    reply_data.callback(reply_success, len, ply)
    if should_delete then
        MODULE:log("Removing reply_id: " .. reply_id, "debug")
        GNIL.Net.Reply["_waiting"][reply_id] = nil
    end
end)

-- Reply factory (and an easier alias).
function GNIL.Net.Reply.Create(reply_id, ply) return GNIL.Net.Classes.Reply:New(reply_id, ply) end
GNIL.Net.CreateReply = GNIL.Net.Reply.Create

timer.Create("gnil_net_reply_gc", 1, 0, function()

    local toDelete = {}
    for k, v in pairs(GNIL.Net.Reply["_waiting"]) do
        if os.time() > (v.time + v.timeout) then
            MODULE:log("NetworkReply '" .. k .. "' has timedout.", "warning")
            
            -- Run the callback with each player that is
            -- still being waited for as unsuccesful.
            for ply, waiting in pairs(v.targets) do
                if waiting then
                    v.callback(false, 0, ply)
                end
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