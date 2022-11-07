
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
    return GNIL.Net.NetworkMessage:New(messageName)
end

-- Start a net message, inserting the message id
-- header and using the blanket gnil message name.
function GNIL.Net.Start(messageName, unreliable)
    local mid = GNIL.Net.NetworkStringToID(messageName)
    if mid == 0 then error("The provided message name '" .. messageName .. "' is unpooled. Ensure you're using GNIL.Net.AddNetworkString beforehand.") end

    if unreliable then GNIL.log("Net message '" .. messageName .. "' is being sent unreliably.", "debug") end

    net.Start("gnil", unreliable)
    net.WriteUInt(mid, GNIL.Net["_idsize"]) -- Write the network ID.
end

------------------------------------------------

net.Receive("gnil", function(len, ply)

    -- Get the message name string from the sent
    -- message id in the header. (Double headers)
    local mstr = GNIL.Net.NetworkIDToString(net.ReadUInt(GNIL.Net["_idsize"]))
    if mstr == nil or GNIL.Net["_c"][mstr] == nil or GNIL.Net["_c"][mstr][1] == nil then return end

    -- Call the associated network receiver with the
    -- provided length (- idsize) and the calling ply
    GNIL.Net["_c"][mstr][1](len - GNIL.Net["_idsize"], ply)
end)
