local MODULE = MODULE

-- Uses WriteableMixin (sh_writeable.lua).

-- The NetworkMessage is an OOP interface for writing network data
-- to a write buffer instead of directly to the write stream. This
-- allows for messages to be queued etc.
local NetworkMessage = GNIL.Thirdparty.middleclass("NetworkMessage"):IncludeMixin(GNIL.Net.Classes.WriteableMixin)
ClassAccessorFunc(NetworkMessage, {
    Name = FuncAccessors.ReadOnly("name"),
    Debug = FuncAccessors.Boolean("_debug")
})

function NetworkMessage:Initialize(name, _debug)
    self.name = name
    self.unreliable = false

    self._reply = {
        callback = nil,
        timeout = nil
    }
    self._errors = {
        callback = nil,
        timeout = nil,
        ratelimited = nil,
        _set = false
    }

    -- Debug messages should be used ONLY FOR TESTING.
    -- Ignores non-existant messages, disables checks.
    self._debug = Either(_debug != nil, _debug, false)
end

-- Start the netmessage (writing the header id) and the buffer.
function NetworkMessage:_WriteToStream(targets)
    MODULE:log("Writing message '" .. self.name .. "' to stream.", "debug")

    -- If there is a reply callback set, a reply header is added.
    local has_reply = self._reply.callback != nil or self._errors._set
    GNIL.Net.Start(self.name, self.unreliable, has_reply, self._debug)

    -- If the message has a reply callback, also add the
    -- reply header to the start of the message.
    if has_reply then

        -- If there are error callbacks set, wrap the reply callback.
        local reply_callback = self._reply.callback
        if self._errors._set then

            -- Wrap the actual reply_callback to handle inline errors.
            reply_callback = function(success, len, ply, err)
                if not success then
                    if self._errors.callback then self._errors.callback(err.enum, err.int) end

                    -- k = error enum, v = self._errors callback key
                    local error_callbacks = {
                        [GNIL_NET_ERRORS_TIMEOUT] = "timeout",
                        [GNIL_NET_ERRORS_RATELIMITED] = "ratelimited",
                        [GNIL_NET_ERRORS_DISABLED] = "disabled"
                    }

                    -- Handle specific error callbacks such as "OnTimeout" etc.
                    -- Maybe better than always calling generic error and checking there?
                    local key = error_callbacks[err.enum]
                    if key and isfunction(self._errors[key]) then
                        self._errors[key](err.enum, err.int)
                    end
                end
                if self._reply.callback != nil then
                    return self._reply.callback(success, len, ply, err)
                end
            end
        end
        GNIL.Net.Reply.WriteHeader(
            targets,
            reply_callback,
            self._reply.timeout
        )
    end

    self:_WriteBufferToStream()
end

-- Literally just alias the actual send function, providing the self
-- NetworkMessage instance (which could be queued, so nothing is written yet).
-- **Send can be used by both server and client (client realm aliasing SendToServer)
function NetworkMessage:Send(ply) if SERVER then GNIL.Net.Send(ply, self) else self:SendToServer() end end
function NetworkMessage:Broadcast() assert(SERVER, "This function may only be used by the server.") GNIL.Net.Broadcast(self) end
function NetworkMessage:SendToServer() assert(CLIENT, "This function may only be used by a client.") self:_WriteToStream() net.SendToServer() end

-- Again, no idea why someone would use this, but if they are we might
-- aswell try to make it as efficient as possible.
function NetworkMessage:SendOmit(ply)
    assert(SERVER, "This function may only be used by the server.")
    local targets, omitted_seq = {}, (istable(ply) and ply or {ply})

    -- If there are no omitted players, then this is just the same
    -- as broadcasting the message, so we might aswell call that.
    if #omitted_seq == 0 then return self:Broadcast() end

    -- For the sake of efficiency 🤓 we convert the omitted table
    -- to an associative table that can be used to quickly index.
    local omitted = {}
    for i, v in ipairs(omitted_seq) do
        omitted[v] = true
    end
    for _, v in player.Iterator() do
        if not omitted[v] then
            table.insert(targets, v)
        end
    end

    -- If there are any targets left, then we should simply iterate
    -- over all the targets and send the message to each individually.
    if #targets == 0 then return end
    for _, v in ipairs(targets) do
        self:Send(v)
    end
end

-- These functions are literally just aliases to a recipient filter
-- message send. I doubt anyone is going to use them, but they exist
-- in the default network module, so they exist here too.
function NetworkMessage:SendPAS(pos) assert(SERVER and isvector(pos), "Provided argument must be a vector, and from the server.") local rf = RecipientFilter() rf:AddPAS(pos) self:Send(rf) end
function NetworkMessage:SendPVS(pos) assert(SERVER and isvector(pos), "Provided argument must be a vector, and from the server.") local rf = RecipientFilter() rf:AddPVS(pos) self:Send(rf) end

-- Send the current net message as a chunked message to the client.
-- **Please read the module README before you use this, it does
-- not use the standard recievers on the client.**
-- **Requires ALL WRITES to be DATA ONLY**
function NetworkMessage:SendChunked(ply, verify_checksum, callback)
    assert(SERVER, "This function may only be used by the server.")

    local data = {}
    for _, v in ipairs(self:_GetWriteBuffer()) do
        if v[2] != "Data" then
            MODULE:log("To send as chunks, all writes MUST be written with WriteData, cannot send message.", "error")
            return
        end
        table.insert(data, v[1][1])
    end
    assert(#data >= 1, "There must be at least one data write to send chunked message.")

    -- If there is only one write, then we should send it as a single
    -- argument instead of a table to skip sizes etc from being sent
    -- as if it were a multi string sequence.
    if #data == 1 then data = data[1] end

    -- As with everything here, just call the real function to do all
    -- the heavy lifting with the data collected + optional arguments.
    GNIL.Net.Chunks.Send(ply, self.name, data, verify_checksum, callback)
end

-- Reply interface.
function NetworkMessage:OnReply(callback) assert(isfunction(callback), "Provided callback argument must be a function.") self._reply.callback = callback return self end
function NetworkMessage:SetReplyTimeout(timeout) assert(isnumber(timeout) and timeout > 0, "Provided timeout argument must be a number greater than 0.") self._reply.timeout = timeout return self end

-- Error interface.
function NetworkMessage:OnError(callback) assert(isfunction(callback), "Provided callback argument must be a function.") self._errors.callback = callback self._errors._set = true return self end
function NetworkMessage:OnTimeout(callback) assert(isfunction(callback), "Provided callback argument must be a function.") self._errors.timeout = callback self._errors._set = true return self end
function NetworkMessage:OnRatelimited(callback) assert(isfunction(callback), "Provided callback argument must be a function.") self._errors.ratelimited = callback self._errors._set = true return self end
function NetworkMessage:OnDisabled(callback) assert(isfunction(callback), "Provided callback argument must be a function.") self._errors.disabled = callback self._errors._set = true return self end

function NetworkMessage:__tostring()
    return "<NetworkMessage '" .. self.name .. "'>"
end

return NetworkMessage