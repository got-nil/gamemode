local MODULE = MODULE
GNIL.Net.Testing = GNIL.Net.Testing or {
    ["_original"] = {},
    ["_detoured"] = {},
    ["_buffer"] = {}
}

local Replacements = {
    ["Write"] = {
        ["Send"] = function(ply) GNIL.Net.Testing["_target"] = ply end,
        ["SendOmit"] = function(ply) GNIL.Net.Testing["_target"] = ply end,
        ["SendPAS"] = function(vector) GNIL.Net.Testing["_target"] = vector end,
        ["SendPVS"] = function(vector) GNIL.Net.Testing["_target"] = vector end,
        ["SendToServer"] = function() GNIL.Net.Testing["_target"] = 2 end,
        ["Broadcast"] = function() GNIL.Net.Testing["_target"] = 1 end,

        -- Whenever Start is called, the write buffer
        -- should be reset since its a "new" message.
        ["Start"] = function(name)
            GNIL.Net.Testing["_message_name"] = name
            GNIL.Net.Testing["_buffer"]["Write"]:_FlushWriteBuffer()
        end,

        -- TODO: Make this work properly.
        ["BytesWritten"] = function() return 0 end
    },
    ["Read"] = {

        -- TODO: Make this work properly.
        ["BytesLeft"] = function() return 0 end,
    }
}

local Types = {
    "Angle",
    "Bit",
    "Bool",
    "Color",
    "Data",
    "Double",
    "Entity",
    "Float",
    "Int",
    "Matrix",
    "Normal",
    "String",
    "Table",
    "Type",
    "UInt",
    "Vector",
    "UInt64",
    "Player"
}

---@param is_read boolean
---@param write_buffer NetworkWriteableMixin?
---@return NetworkWriteableMixin
local function createBuffer(is_read, write_buffer)
    if is_read then
        return GNIL.Net.Classes.Readable:New(write_buffer)
    else
        return GNIL.Thirdparty.middleclass("WriteBuffer"):IncludeMixin(GNIL.Net.Classes.WriteableMixin)
    end
end

---@param is_read boolean
---@param typeName string
---@return fun(...: table): nil
local function detourCallback(is_read, typeName)
    local prefix = is_read && "Read" || "Write"
    return function(...)
        local buffer = GNIL.Net.Testing["_buffer"][prefix]
        if is_read then
            return buffer:Read({...}, typeName)
        else
            buffer:_WriteToBuffer({...}, typeName)
        end
    end
end

--Detour all network writing functions.
---@param is_read boolean
---@param write_buffer? table
function GNIL.Net.Testing.Detour(is_read, write_buffer)

    -- Prevent double detouring.
    local prefix = is_read && "Read" || "Write"
    if GNIL.Net.Testing["_detoured"][prefix] then
        return
    end

    -- Create detour buffer to be written/read to/from.
    GNIL.Net.Testing["_buffer"][prefix] = createBuffer(is_read, write_buffer)

    -- Get original net callbacks and replace with detour.
    local originals = {}
    for _, v in ipairs(Types) do
        local name = prefix .. v
        originals[name] = net[name]
        net[name] = detourCallback(is_read, v)
    end

    -- Add any additional type replacements.
    for k, v in pairs(Replacements[prefix]) do
        originals[k] = net[k]
        net[k] = v
    end

    -- Cache the original callbacks and detour state.
    GNIL.Net.Testing["_original"][prefix] = originals
    GNIL.Net.Testing["_detoured"][prefix] = true
    if is_read then GNIL.Net["_receive"] = false end
end

---Restore network functions to originals.
---@param is_read boolean
---@return NetworkWriteableMixin?
function GNIL.Net.Testing.Restore(is_read)

    -- Ensure its already been detoured.
    local prefix = is_read && "Read" || "Write"
    if not GNIL.Net.Testing["_detoured"][prefix] then
        return
    end

    -- Restore original net lib callbacks.
    for k, v in pairs(GNIL.Net.Testing["_original"][prefix]) do
        net[k] = v
    end

    -- Remove/reset cache.
    GNIL.Net.Testing["_original"][prefix] = nil
    GNIL.Net.Testing["_detoured"][prefix] = false
    if is_read then GNIL.Net["_receive"] = true end

    -- Get the out buffer and reset it.
    local out = GNIL.Net.Testing["_buffer"][prefix]
    GNIL.Net.Testing["_buffer"][prefix] = nil
    return out
end

---Are we currently detoured?
---@param is_read boolean
---@return boolean
function GNIL.Net.Testing.IsDetoured(is_read)
    return GNIL.Net.Testing["_detoured"][is_read && "Read" || "Write"] == true
end

---Call the network reciever with a write buffer, wrapped in a detour.
---@param write_buffer NetworkWriteableMixin
---@param receiver any
---@return boolean
---@return string?
function GNIL.Net.Testing.CallReciever(write_buffer, receiver)
    if GNIL.Net.Testing.IsDetoured(true) then return false, nil end

    GNIL.Net.Testing.Detour(true, write_buffer)     -- 1. Detour
    local succ, err = pcall(function()              -- 2. Call reciever

        -- Call the primary network reciever with write buffer.
        -- TODO: Use BytesWritten on write_buffer instead of static.
        GNIL.Net._Receiver(25, player.GetAll()[1], receiver)

    end)
    GNIL.Net.Testing.Restore(true)                  -- 3. Restore

    -- If the callback errors, return the error itself.
    if not succ then
        MODULE:log("Testing CallReciever: " .. err, "error")
        return false, err
    end

    -- Returns: success, error
    return true, nil
end

---Wrap a writeable callback in a detour state.
---@param callback function
---@return boolean|NetworkWriteableMixin
---@return string|{messageName: string|boolean, target: any}?
function GNIL.Net.Testing.WrapWriteable(callback)
    if GNIL.Net.Testing.IsDetoured(false) then return false, nil end

    -- Since this is a write operation, there could be a
    -- message name or target set (Start/Send) callbacks.
    GNIL.Net.Testing.Detour(false)                  -- 1. Detour
    local succ, err = pcall(callback)               -- 2. Run callback
    local out = GNIL.Net.Testing.Restore(false)     -- 3. Restore

    -- Make sure that we got a valid write buffer from restore.
    if out == nil then
        MODULE:log("Could not restore a valid WriteableMixin from detoured network state.", "error")
        return false, "Couldn't restore a valid WriteableMixin class from detour"
    end

    -- If the callback errors, reutrn the error itself.
    if not succ then
        MODULE:log("Testing WrapWriteable: " .. err, "error")
        return false, err
    end

    -- Returns: Writeable, table
    return out, {
        messageName = GNIL.Net.Testing["_message_name"] or false,
        target = GNIL.Net.Testing["_target"] or false
    }
end