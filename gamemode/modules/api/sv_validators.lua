GNIL.API.Validators = GNIL.API.Validators or {}

function GNIL.API.Validators.IsNumeric(str)
    if string.match(str, "%D") then return false end
    return true
end

GNIL.API.Validators._argumentValidators = {
    ["str"] = function(v) return tostring(v) end,
    ["int"] = function(v)
        if GNIL.API.Validators.IsNumeric(v) then
            return tonumber(v)
        end
        return nil
    end,
    ["ply"] = function(v)
        for _, p in ipairs(player.GetAll()) do
            if p:SteamID64() == v or p:SteamID() == v then
                return p
            end
        end
        return nil
    end,

    -- Patterns provided by Virtualraptor.
    ["steamid64"] = function(v)
        local startPos, endPos, str = string.find(v, "(7656119%d+)")
        if startPos == 1 and endPos == 17 then
            return str
        end
        return nil
    end,
    ["steamid"] = function(v)
        local startPos, _, str = string.find(v, "(STEAM_[0-3]:[01]:%d+)")
        if startPos == 1 then
            return str
        end
        return nil
    end
}

-- Run the validator/converter on a value.
function GNIL.API.Validators.Argument(arg_type, value)
    local validator = GNIL.API.Validators._argumentValidators[arg_type]
    if validator == nil then return nil end
    return validator(value)
end

-- Check that an argument validator actually exists.
function GNIL.API.Validators.Exists(arg_type)
    return GNIL.API.Validators._argumentValidators[arg_type] != nil
end