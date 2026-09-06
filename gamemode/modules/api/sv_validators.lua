local MODULE = MODULE
GNIL.API.Validators = GNIL.API.Validators or {}

---Check if a provided string is numeric.
---@param str string
---@return boolean
function GNIL.API.Validators.IsNumeric(str)
    if string.match(str, "%D") then return false end
    return true
end

local ResponseTypeConverters = {
    [TYPE_FUNCTION] = function(v) return v end, -- for promises.
    [TYPE_NUMBER] = function(v) return GNIL.API.Responses.Empty(v) end,
    [TYPE_STRING] = function(v) return GNIL.API.Responses.Text(v) end,
    [TYPE_BOOL] = function(v) return GNIL.API.Responses.Empty(v && 200 || 500) end
}

---Convert some output type to a Response.
---@param route any
---@param out any
---@return API.Response|API.Route.PromiseCallback
function GNIL.API.Validators.ToResponse(route, out)
    local type_converter = ResponseTypeConverters[TypeID(out)]
    if type_converter then

        -- Run the type converter.
        out = type_converter(out)
    else

        -- If we're not handling type conversion ourselves, then make
        -- sure that the callback actually returns a Response instance.
        if not IsInstanceOf(out, GNIL.API.Response) then
            MODULE:log("Route '" .. route:__tostring() .. "' did not return a Response value. Returning an empty 500 status.", "error")
            out = GNIL.API.Responses.Empty(500)
        end
    end
    return out
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
        for _, p in ipairs(player.GetAll())() do
            if p:SteamID64() == v or p:SteamID() == v then
                return p
            end
        end
        return nil
    end,

    -- Patterns provided by Virtualraptor.
    ["steamid64"] = function(v)
        if string.find(v, "^(7656119%d%d%d%d%d%d%d%d%d%d)$") then
            return v
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

---Run the validator/converter on a value.
---@param arg_type string
---@param value any
---@return any?
function GNIL.API.Validators.Argument(arg_type, value)
    local validator = GNIL.API.Validators._argumentValidators[arg_type]
    if validator == nil then return nil end
    return validator(value)
end

---Check that an argument validator actually exists.
---@param arg_type string
---@return boolean
function GNIL.API.Validators.Exists(arg_type)
    return GNIL.API.Validators._argumentValidators[arg_type] != nil
end