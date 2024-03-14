
---Basically just a writer with some additional functionality.
---uses the writeable mixin instead of subclassing Message since
---a bunch of functions had to be overriden/removed from parent.
---@class Net.Reply: Net.Writeable
---@field id string
local NetworkReply = GNIL.Thirdparty.middleclass("NetworkReply"):IncludeMixin(GNIL.Net.Classes.WriteableMixin)
ClassAccessorFunc(NetworkReply, {
    ID = FuncAccessors.ReadOnly("id")
})

---Initialize the message without a name since it will not
---be sent directly anyway.
---@param reply_id string
function NetworkReply:Initialize(reply_id, ply)
    self.id = tostring(reply_id)
    self.ply = ply
    self._error = {
        set = false,
        enum = GNIL_NET_ERRORS.FAIL,
        int = 0
    }
end

---Allow initialized replies to be sent after the reciever
---has finished. This allows the reciever to do async things
---and then NetworkReply when possible.
function NetworkReply:Send()
    assert(isstring(self.id), "Cannot send an uninitialized NetworkReply.")
    GNIL.Net.Reply._StartReplyMessage(self.id, self._error.set, self._error.enum, self._error.int)
    self:_WriteBufferToStream()
    if SERVER then net.Send(self.ply) else net.SendToServer() end
end

---Set an error to be sent back as reply.
---@param error_enum GNIL_NET_ERRORS
---@param error_int? number
---@return self
function NetworkReply:SetError(error_enum, error_int)
    self._error = {
        set = true,
        enum = error_enum,
        int = error_int or 0
    }
    return self
end
function NetworkReply:IsError() return self._error.set != false end
function NetworkReply:RemoveError() self._error.set = false return self end

-- Class metafunctions.
function NetworkReply:__tostring()
    return "NetworkReply<" .. self.id .. ">"
end

return NetworkReply
