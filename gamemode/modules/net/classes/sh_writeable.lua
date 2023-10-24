
-- This is a mixin that can be included on classes
-- that should be writeable. Since subclassing default
-- message isn't usually the best idea. Used by Message & Reply.

-- Im not making a seperate directory just for this one
-- mixin, so sadly it'll have to live in the Classes namespace.

-- TODO: BytesWritten

return {

    -- Each function should expect the write buffer to possibly
    -- not exist just incase the parent class is doing some fuckery.
    _FlushWriteBuffer = function(self) self.__write_buffer = {} end,
    _GetWriteBuffer = function(self) return self.__write_buffer or {} end,
    _WriteToBuffer = function(self, args, typeName)
        if self.__write_buffer == nil then self:_FlushWriteBuffer() end
        table.insert(self.__write_buffer, {args, typeName})
        return self
    end,
    _WriteBufferToStream = function(self)
        if self.__write_buffer == nil then return end
        for _, v in ipairs(self.__write_buffer) do
            local fn = net["Write" .. v[2]]
            if fn then fn(unpack(v[1])) end
        end
    end,

    -- Instead of using the function directly, reference
    -- the typename since the function is just "Write<Type>".
    -- Also makes it easier for other things to read writeables.
    WriteAngle =    function(self, ...) return self:_WriteToBuffer({...}, "Angle")  end,
    WriteBit =      function(self, ...) return self:_WriteToBuffer({...}, "Bit")    end,
    WriteBool =     function(self, ...) return self:_WriteToBuffer({...}, "Bool")   end,
    WriteColor =    function(self, ...) return self:_WriteToBuffer({...}, "Color")  end,
    WriteData =     function(self, ...) return self:_WriteToBuffer({...}, "Data")   end,
    WriteDouble =   function(self, ...) return self:_WriteToBuffer({...}, "Double") end,
    WriteEntity =   function(self, ...) return self:_WriteToBuffer({...}, "Entity") end,
    WriteFloat =    function(self, ...) return self:_WriteToBuffer({...}, "Float")  end,
    WriteInt =      function(self, ...) return self:_WriteToBuffer({...}, "Int")    end,
    WriteMatrix =   function(self, ...) return self:_WriteToBuffer({...}, "Matrix") end,
    WriteString =   function(self, ...) return self:_WriteToBuffer({...}, "String") end,
    WriteType =     function(self, ...) return self:_WriteToBuffer({...}, "Type")   end,
    WriteUInt =     function(self, ...) return self:_WriteToBuffer({...}, "UInt")   end,
    WriteVector =   function(self, ...) return self:_WriteToBuffer({...}, "Vector") end,
    WriteUInt64 =   function(self, ...) return self:_WriteToBuffer({...}, "UInt64") end,
    WritePlayer =   function(self, ...) return self:_WriteToBuffer({...}, "Player") end

}