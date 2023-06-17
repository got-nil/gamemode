GNIL.Net.Helpers = GNIL.Net.Helpers or {}

local bitcount_map = {1, 3, 7, 15, 31, 63, 127, 255, 511, 1023, 2047, 4095, 8191, 16383, 32767, 65535, 131071, 262143, 524287, 1048575, 2097151, 4194303, 8388607, 16777215, 33554431, 67108863, 134217727, 268435455, 536870911, 1073741823, 2147483647, 4294967295}

function GNIL.Net.Helpers.GetBitcountMaxValue(bitcount, is_uint)
    if 1 > bitcount or bitcount > 32 then return false end
    return bitcount_map[bitcount + Either(is_uint == true, 0, 1)]
end

-- Since its a small set we can just test each
-- value until a valid bitcount is found, or false.
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
