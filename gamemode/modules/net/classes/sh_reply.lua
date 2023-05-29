
-- The NetworkReply is used by the reply system. It's essentially
-- only used as a buffer with the write functions as it cannot be
-- sent directly without a reply header.
local Reply = GNIL.Thirdparty.middleclass("NetworkReply", GNIL.Net.Classes.Message)

-- Initialize the message without a name since it will not
-- be sent directly anyway.
function Reply:Initialize(reply_id, ply)
    GNIL.Net.Classes.Message.Initialize(self, nil)
    
    self.id = tostring(reply_id)
    self.ply = ply
    self._error = {
        enum = false,
        int = false
    }
end

local errorCallback = function(...)
    error("This is not supported on a NetworkReply")
end

-- Replace all message send functions with an error callback.
-- This should hopefully prevent some dumbass trying to send
-- a message that doesn't have a name.
local sendFunctions = {
    "Broadcast",
    "SendOmit",
    "SendPAS",
    "SendPVS",
    "SendChunked",

    -- Since this writes the message header, it cannot be used.
    -- '_WriteBufferToStream' just writes the message content.
    "_WriteToStream",

    -- Remove feature functions.
    "OnReply",
    "SetReplyTimeout",
    "OnError",
    "OnTimeout",
    "OnRatelimited"
}
for _, v in ipairs(sendFunctions) do
    Reply[v] = errorCallback
end

-- Allow initialized replies to be sent after the reciever
-- has finished. This allows the reciever to do async things
-- and then reply when possible.
function Reply:Send()
    assert(isstring(self.id), "Cannot send an uninitialized reply.")
    GNIL.Net.Reply._StartReplyMessage(self.id, self._error.enum == false, self._error.enum, self._error.int)
    self:_WriteBufferToStream()
    if SERVER then net.Send(self.ply) else net.SendToServer() end
end
Reply.SendToServer = Reply.Send

-- Error interface.
function Reply:SetError(error_enum, error_int)
    assert(error_enum == false or (isnumber(error_enum) and error_enum > 0 and GNIL_NET_ERRORS_COUNT >= error_enum), "Provided error must be type of GNIL_NET_ERRORS ENUM.")
    assert(error_int == nil or isnumber(error_int), "Provided error_int must be a number or nil.")
    self._error = {
        enum = error_enum,
        int = error_int
    }
    return self
end
function Reply:IsError() return self._error.enum != false end
function Reply:RemoveError() self._error.enum = false return self end

-- Class metafunctions.
function Reply:__tostring()
    return "<NetworkReply '" .. self.name .. "'>"
end

return Reply