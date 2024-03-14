
---@class Net.Readable: middleclass
---@field private _buffer table Read buffer.
---@field _i number Current index position.
local NetworkReadable = GNIL.Thirdparty.middleclass("NetworkReadable")
ClassAccessorFunc(NetworkReadable, {
    Buffer = FuncAccessors.ReadOnly("_buffer")
})

-- Read from a class that uses NetworkWriteable.
-- This is specifically for unit tests, detouring net.Read* to
-- read from this class instead.

-- TODO: BytesLeft

function NetworkReadable:Initialize(writeable)
    self._buffer = writeable == nil && {} || writeable:_GetWriteBuffer()
    self._i = 1
end

---@param args table
---@param typeName string
---@return any
function NetworkReadable:Read(args, typeName)

    local current = self._buffer[self._i]
    if not current then return nil end

    -- Validate that the typeName and second argument match.
    if current[2] != typeName then return nil end
    if #current[1] > 1 and current[1][2] != args[1] then
        return nil
    end

    self._i = self._i + 1
    return current[1][1]
end

return NetworkReadable