
-- This is a mixin that can be included on classes
-- that should be writeable. Since subclassing default
-- message isn't usually the best idea. Used by Message & Reply.

-- Im not making a seperate directory just for this one
-- mixin, so sadly it'll have to live in the Classes namespace.

-- TODO: BytesWritten

---@class Net.Writeable
local WriteableMixin = {

    -- Each function should expect the write buffer to possibly
    -- not exist just incase the parent class is doing some fuckery.
    _FlushWriteBuffer = function(self) self.__write_buffer = {} end,
    _GetWriteBuffer = function(self) return self.__write_buffer or {} end,

    ---@param self self
    ---@param args table Type arguments.
    ---@param typeName string The name of the type.
    ---@return any
    _WriteToBuffer = function(self, args, typeName)
        if self.__write_buffer == nil then self:_FlushWriteBuffer() end
        table.insert(self.__write_buffer, {args, typeName})
        return self
    end,

    ---Call all network writers on buffer, must be called with an open message.
    ---@param self self
    _WriteBufferToStream = function(self)
        if self.__write_buffer == nil then return end
        for _, v in ipairs(self.__write_buffer) do
            local fn = net["Write" .. v[2]]
            if fn then fn(unpack(v[1])) end
        end
    end,

    ---@generic T
    ---@param self T
    ---@param angle Angle
    ---@see net.WriteAngle
    ---@return T
    WriteAngle = function(self, angle) return self:_WriteToBuffer({angle}, "Angle") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param boolean boolean
    ---@see net.WriteBit
    ---@return T
    WriteBit = function(self, boolean) return self:_WriteToBuffer({boolean}, "Bit") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param boolean boolean
    ---@see net.WriteBool
    ---@return T
    WriteBool = function(self, boolean) return self:_WriteToBuffer({boolean}, "Bool") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param color table|Color
    ---@param writeAlpha? boolean
    ---@see net.WriteColor
    ---@return T
    WriteColor = function(self, color, writeAlpha) return self:_WriteToBuffer({color, writeAlpha}, "Color") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param binaryData string
    ---@param length? integer
    ---@see net.WriteData
    ---@return T
    WriteData = function(self, binaryData, length) return self:_WriteToBuffer({binaryData, length}, "Data") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param double number
    ---@see net.WriteDouble
    ---@return T
    WriteDouble = function(self, double) return self:_WriteToBuffer({double}, "Double") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param entity Entity
    ---@see net.WriteEntity
    ---@return T
    WriteEntity = function(self, entity) return self:_WriteToBuffer({entity}, "Entity") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param float number
    ---@see net.WriteFloat
    ---@return T
    WriteFloat = function(self, float) return self:_WriteToBuffer({float}, "Float") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param integer number
    ---@param bitCount number
    ---@see net.WriteInt
    ---@return T
    WriteInt = function(self, integer, bitCount) return self:_WriteToBuffer({integer, bitCount}, "Int") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param matrix VMatrix
    ---@see net.WriteMatrix
    ---@return T
    WriteMatrix = function(self, matrix) return self:_WriteToBuffer({matrix}, "Matrix") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param normal Vector
    ---@see net.WriteNormal
    ---@return T
    WriteNormal = function(self, normal) return self:_WriteToBuffer({normal}, "Normal") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param ply Player
    ---@see net.WritePlayer
    ---@return T
    WritePlayer = function(self, ply) return self:_WriteToBuffer({ply}, "Player") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param string string
    ---@see net.WriteString
    ---@return T
    WriteString = function(self, string) return self:_WriteToBuffer({string}, "String") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param data any
    ---@see net.WriteType
    ---@return T
    WriteType = function(self, data) return self:_WriteToBuffer({data}, "Type") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param unsignedInteger number
    ---@param bitCount number
    ---@see net.WriteUInt
    ---@return T
    WriteUInt = function(self, unsignedInteger, bitCount) return self:_WriteToBuffer({unsignedInteger, bitCount}, "UInt") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param uint64 string
    ---@see net.WriteUInt64
    ---@return T
    WriteUInt64 = function(self, uint64) return self:_WriteToBuffer({uint64}, "UInt64") end, ---@diagnostic disable-line

    ---@generic T
    ---@param self T
    ---@param vector Vector
    ---@see net.WriteVector
    ---@return T
    WriteVector = function(self, vector) return self:_WriteToBuffer({vector}, "Vector") end ---@diagnostic disable-line

}
return WriteableMixin