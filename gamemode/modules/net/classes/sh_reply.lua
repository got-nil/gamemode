
-- Basically just a writer with some additional functionality.
-- Uses the writeable mixin instead of subclassing Message since
-- a bunch of functions had to be overriden/removed from parent.
local NetworkReply = GNIL.Thirdparty.middleclass("NetworkReply"):IncludeMixin(GNIL.Net.Classes.WriteableMixin)
ClassAccessorFunc(NetworkReply, {
    ID = FuncAccessors.ReadOnly("id")
})

-- Initialize the message without a name since it will not
-- be sent directly anyway.
function NetworkReply:Initialize(reply_id, ply)
    self.id = tostring(reply_id)
    self.ply = ply
    self._error = {
        enum = false,
        int = false
    }
end

-- Allow initialized replies to be sent after the reciever
-- has finished. This allows the reciever to do async things
-- and then NetworkReply when possible.
function NetworkReply:Send()
    assert(isstring(self.id), "Cannot send an uninitialized NetworkReply.")
    GNIL.Net.Reply._StartReplyMessage(self.id, self._error.enum == false, self._error.enum, self._error.int)
    self:_WriteBufferToStream()
    if SERVER then net.Send(self.ply) else net.SendToServer() end
end
--NetworkReply.SendToServer = NetworkReply.Send

-- Error interface.
function NetworkReply:SetError(error_enum, error_int)
    assert(error_enum == false or (isnumber(error_enum) and error_enum > 0 and GNIL_NET_ERRORS_COUNT >= error_enum), "Provided error must be type of GNIL_NET_ERRORS ENUM.")
    assert(error_int == nil or isnumber(error_int), "Provided error_int must be a number or nil.")
    self._error = {
        enum = error_enum,
        int = error_int
    }
    return self
end
function NetworkReply:IsError() return self._error.enum != false end
function NetworkReply:RemoveError() self._error.enum = false return self end

-- Class metafunctions.
function NetworkReply:__tostring()
    return "NetworkReply<" .. self.id .. ">"
end

return NetworkReply
