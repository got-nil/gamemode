
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
    "_WriteToStream"
}
for _, v in ipairs(sendFunctions) do
    Reply[v] = errorCallback
end

-- Allow initialized replies to be sent after the reciever
-- has finished. This allows the reciever to do async things
-- and then reply when possible.
function Reply:Send()
    assert(isstring(self.id), "Cannot send an uninitialized reply.")
    GNIL.Net.Reply._StartReplyMessage(self.id, true)
    self:_WriteBufferToStream()
    if SERVER then net.Send(self.ply) else net.SendToServer() end
end
Reply.SendToServer = Reply.Send

function Reply:__tostring()
    return "<NetworkReply '" .. self.name .. "'>"
end

return Reply