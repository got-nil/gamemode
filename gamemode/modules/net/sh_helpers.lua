local MODULE = MODULE
GNIL.Net.Helpers = GNIL.Net.Helpers or {}

local bitcount_map = {1, 3, 7, 15, 31, 63, 127, 255, 511, 1023, 2047, 4095, 8191, 16383, 32767, 65535, 131071, 262143, 524287, 1048575, 2097151, 4194303, 8388607, 16777215, 33554431, 67108863, 134217727, 268435455, 536870911, 1073741823, 2147483647, 4294967295}

---@param bitcount integer
---@param is_uint boolean
---@return boolean
function GNIL.Net.Helpers.GetBitcountMaxValue(bitcount, is_uint)
    if 1 > bitcount or bitcount > 32 then return false end
    return bitcount_map[bitcount + Either(is_uint == true, 0, 1)]
end

---Since its a small set we can just test each
---value until a valid bitcount is found, or false.
---@param value integer
---@param is_uint boolean
---@return boolean
function GNIL.Net.Helpers.GetBitcount(value, is_uint)
    local offset, value = Either(is_uint == true, 0, 1), math.abs(value)

    if 0 >= value then return false end
    if is_uint != true and 3 > value then return false end
    if value > bitcount_map[#bitcount_map] then return false end

    for i = 1 + offset, #bitcount_map do
        if value > bitcount_map[i] then
            continue
        end
        return i + offset
    end
    return false
end

---Wrapper for a reciever that auto replies with the
---DISABLED error. Also a little bit of logging.
---@param messageName string
---@return fun(len: integer, ply: Player, reply: NetworkReply)
function GNIL.Net.Helpers.DisabledMessageReciever(messageName)

    return function(_, ply, reply)

        if SERVER then MODULE:log(ply:ToString() .. " attempted to send to disabled message '" .. messageName .. "'", "debug")
        else MODULE:log("The server attempted to send disabled message '" .. messageName .. "'", "debug") end

        -- If the message has a reply header, respond
        -- with the DISABLED error (to possibly prevent
        -- repeat calls or just for serverside logging).
        if reply then
            return reply:SetError(GNIL_NET_ERRORS.DISABLED)
        end
    end
end