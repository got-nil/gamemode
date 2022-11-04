
-- The NetworkMessage is an OOP interface for writing network data
-- to a write buffer instead of directly to the write stream. This
-- allows for messages to be queued etc. 
local NetworkMessage = GNIL.Thirdparty.middleclass("NetworkMessage")
function NetworkMessage:Initialize(name)
    self.name = name
    self._write_buffer = {}
end

-- This is pretty ugly, but its the result of having to alias
-- everything into the write cache.
function NetworkMessage:_WriteToBuffer(args, fn) table.insert(self._write_buffer, {args, fn}) return self end
function NetworkMessage:WriteAngle(...)  return self:_WriteToBuffer({...}, net.WriteAngle)  end
function NetworkMessage:WriteBit(...)    return self:_WriteToBuffer({...}, net.WriteBit)    end
function NetworkMessage:WriteBool(...)   return self:_WriteToBuffer({...}, net.WriteBool)   end
function NetworkMessage:WriteColor(...)  return self:_WriteToBuffer({...}, net.WriteColor)  end
function NetworkMessage:WriteData(...)   return self:_WriteToBuffer({...}, net.WriteData)   end
function NetworkMessage:WriteDouble(...) return self:_WriteToBuffer({...}, net.WriteDouble) end
function NetworkMessage:WriteEntity(...) return self:_WriteToBuffer({...}, net.WriteEntity) end
function NetworkMessage:WriteFloat(...)  return self:_WriteToBuffer({...}, net.WriteFloat)  end
function NetworkMessage:WriteInt(...)    return self:_WriteToBuffer({...}, net.WriteInt)    end
function NetworkMessage:WriteMatrix(...) return self:_WriteToBuffer({...}, net.WriteMatrix) end
function NetworkMessage:WriteString(...) return self:_WriteToBuffer({...}, net.WriteString) end
function NetworkMessage:WriteType(...)   return self:_WriteToBuffer({...}, net.WriteType)   end
function NetworkMessage:WriteUInt(...)   return self:_WriteToBuffer({...}, net.WriteUInt)   end
function NetworkMessage:WriteVector(...) return self:_WriteToBuffer({...}, net.WriteVector) end

-- Allow for the write buffer to be flushed or written to an
-- existing network stream (these should be used internally).
function NetworkMessage:_FlushWriteBuffer() self._write_buffer = {} end
function NetworkMessage:_WriteBufferToStream()
    for _, v in ipairs(self._write_buffer) do
        v[2](unpack(v[1]))
    end
end

-- Start the netmessage (writing the header id) and the buffer.
function NetworkMessage:_WriteToStream()
    GNIL.log("Writing message '" .. self.name .. "' to stream.", "debug")
    GNIL.Net.Start(self.name)
    self:_WriteBufferToStream()
end

-- Literally just alias the actual send function, providing the self
-- NetworkMessage instance (which could be queued, so nothing is written yet).
-- **Send can be used by both server and client (client realm aliasing SendToServer)
function NetworkMessage:Send(ply) if SERVER then GNIL.Net.Send(ply, self) else self:SendToServer() end end
function NetworkMessage:Broadcast() assert(SERVER, "This function may only be used by the server.") GNIL.Net.Broadcast(self) end
function NetworkMessage:SendToServer() assert(CLIENT, "This function may only be used by a client.") GNIL.Net.SendToServer(self) end

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
    for _, v in ipairs(player.GetAll()) do
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

-- Basically just an alias to the default, but the buffer is also written.
function NetworkMessage:SendToServer() assert(CLIENT, "This function may only be used by a client.") self:_WriteToStream() net.SendToServer() end

function NetworkMessage:__tostring()
    return "NetMessage " .. self.name
end

GNIL.Net.NetworkMessage = NetworkMessage