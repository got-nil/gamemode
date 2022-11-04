
-- Net message queue
GNIL.Net["_q"] = GNIL.Net["_q"] or {}

-- Send the network message to all players (+ NetMessage passthrough.)
function GNIL.Net.Broadcast(_nm)
    for _, v in ipairs(player.GetAll()) do
        GNIL.Net.Send(v, _nm)
    end
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

            GNIL.log("Message '" .. _nm.name .. "' to player '" .. ply:Nick() .. "' has been queued ", "debug")
            return
        end

        -- If there is a netmessage provided, then we should actually write the
        -- network header and write buffer to the started net stream.
        if _nm then
            _nm:_WriteToStream()
        end

        -- Actually send the message.
        net.Send(ply)

    else
        error("Unknown datatype input provided. May be a: CRecipientFilter, Player or sequential table of players.")
    end
end

-- When a player has loaded to the point where they can send/recieve
-- network messages, then we should send any messages that are queued.
hook.Add("PlayerNetLoad", "gnil_net_send_queue", function(ply)
    
    -- Ensure that there actually are queued net
    -- messages for the loaded player's steamid.
    local sid = ply:SteamID()
    local messages = GNIL.Net["_q"][sid]
    if messages == nil then return end

    GNIL.log("Client '" .. ply:Nick() .. "' has netloaded, with messages queued. Sending now.", "debug")

    -- Send all of the messages within the queue.
    -- If the message still somehow fails to send, it
    -- will not be re-queued (to prevent loops).
    for _, v in ipairs(messages) do
        GNIL.Net.Send(v[1], v[2], false)
    end

    -- Empty the queue for the given player.
    GNIL.Net["_q"][sid] = {}
end)