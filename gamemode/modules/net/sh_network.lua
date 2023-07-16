local MODULE = MODULE

-- These functions are the exact same as the default net functions
-- in terms of input arguments and return values.

function GNIL.Net.NetworkIDToString(id)
    if id == 0 or id > #GNIL.Net["_r"] then return nil end
    return GNIL.Net["_r"][id]
end
function GNIL.Net.NetworkStringToID(str)

    -- For maximum optimisation, the ids are pre-cached as a reverse
    -- of the registry table instead of re-finding it each time.
    if GNIL.Net["_i"][str] then return GNIL.Net["_i"][str] end
    return 0
end

-- Each messagename can have two receivers, a standard network
-- callback and a chunked data callback.
local function _addReceiverAtPos(name, pos, callback)
    if not GNIL.Net["_c"][name] then
        GNIL.Net["_c"][name] = {nil, nil}
    end
    GNIL.Net["_c"][name][pos] = callback
end

-- Seperate adding receivers for standard messages and chunked
-- data. This is because each uses different callback arguments.
-- (ReceiveChunked can only be used by clients).
function GNIL.Net.Receive(messageName, callback) _addReceiverAtPos(messageName, 1, callback) end
function GNIL.Net.ReceiveChunked(messageName, callback) assert(CLIENT, "Only the client can receive chunked data.") _addReceiverAtPos(messageName, 2, callback) end

------------------------------------------------

-- Create a network message instance with the given
-- message name (class constructor alias basically).
function GNIL.Net.Create(messageName)
    return GNIL.Net.Classes.Message:New(messageName)
end
 
-- Start a net message, inserting the message id
-- header and using the blanket gnil message name.
function GNIL.Net.Start(messageName, unreliable, _has_reply, _ignore_nonexistant)
    local mid = GNIL.Net.NetworkStringToID(messageName)
    if not _ignore_nonexistant and mid == 0 then error("The provided message name '" .. messageName .. "' is unpooled. Ensure you're using GNIL.Net.AddNetworkString beforehand.") end
    if unreliable then MODULE:log("Net message '" .. messageName .. "' is being sent unreliably.", "debug") end

    net.Start("gnil", unreliable)
    net.WriteUInt(mid, GNIL.Net["_idsize"]) -- Write the network ID.
    net.WriteBool(_has_reply == true) -- Write reply signal.
end

------------------------------------------------

local function recieveMessage(len, ply, _receiver)

    local _debug = _receiver != nil and isfunction(_receiver)

    -- Get the message name string from the sent
    -- message id in the header. (Double headers)
    local mstr = GNIL.Net.NetworkIDToString(net.ReadUInt(GNIL.Net["_idsize"]))
    if not _debug and (mstr == nil or GNIL.Net["_c"][mstr] == nil or GNIL.Net["_c"][mstr][1] == nil) then return end
    local offset = GNIL.Net["_idsize"] -- Base id size.

    -- If the message has a reply signal, read the
    -- reply_id for the receiver callback.
    offset = offset + 1 -- Has reply header bool.
    local has_reply, reply_id, reply = net.ReadBool(), false, nil
    if has_reply then
        reply_id = net.ReadUInt(15)
        if not GNIL.Net.Reply.IsValidReplyID(reply_id) then
            MODULE:log((SERVER && "Player " .. ply:ToString() || "The server") .. " sent message '" .. mstr .. "' with a reply signal, yet an invalid reply_id.", "error")
            return
        end
        reply = GNIL.Net.CreateReply(reply_id, ply)
        offset = offset + 15 -- Reply ID size.
    end

    -- Check for network abuse patterns.
    if SERVER and not GNIL.Net.AntiAbuse.Check(mstr, ply, reply) then
        MODULE:log("Rejecting player " .. ply:ToString() .. " message '" .. mstr .. "' as abuse was detected.", "debug")
        return
    end
    
    -- Call the associated network receiver with the
    -- provided length (- idsize) and the calling ply.
    local out, reciever_args = false, {len - offset, ply, reply}
    if _debug then out = _receiver(unpack(reciever_args))
    else out = GNIL.Net["_c"][mstr][1](unpack(reciever_args)) end

    -- Finally handle reply response from receiver.
    if not _debug and has_reply then
        GNIL.Net.Reply.ReceiverWrap(reply_id, out, ply)
    end
end

net.Receive("gnil", recieveMessage)
if SERVER then GNIL.Net._Receiver = recieveMessage end