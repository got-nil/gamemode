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
        for _, getter in pairs({player.GetBySteamID, player.GetBySteamID64}) do
            local ply = getter(v)
            if ply then return ply end
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