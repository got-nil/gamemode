GNIL.Validation = {}

--[[

Validate a provided table against a type structure.
These look like:

{
    ["key"] = {default, validator, required?},
    ...
}

Validator function returns:
    bool - Is the value accepted?
    str - Reason for rejection if first arg is false.

default - The default value that should be used if the key is ommitted in the provided table.
validator - Either a table of values that should be accepted, or a TYPE enum to validate against value, or validator function.
required? - Optional, is the key required in the provided table? (Default: false)

--]]

---@param provided table
---@param structure table
---@return boolean success Validity state.
---@return string|table output Error message if unsuccesful, or structured table if valid.
function GNIL.Validation.Structure(provided, structure)
    if not istable(provided) or not istable(structure) then
        return false, "Provided and Structure must both be tables."
    end
    for k, v in pairs(structure) do
        if provided[k] == nil then
            if #v >= 3 and v[3] then
                return false, "Missing required key " .. k
            end
            provided[k] = v[1]
        else
            local t = TypeID(v[2])
            if t == TYPE_TABLE then
                if not table.HasValue(v[2], provided[k]) then
                    return false, "Required key '" .. k .. "' is not in accepted values"
                end
            elseif t == TYPE_FUNCTION then
                local success, err = v[2](provided[k])
                if not success then
                    return false, Either(isstring(err), err, "Key '" .. k .. "' was rejected by validator callback without reason")
                end
            else
                if provided[k] != v[1] and t == TYPE_NUMBER and TypeID(provided[k]) != v[2] then
                    return false, "Key '" .. k .. "' is an invalid type '" .. type(provided[k]) .. "'"
                end
            end
        end
    end
    return true, provided
end

---Check if a provided object is type of TYPE_ENUM.
---@param provided any
---@param type_enum integer
---@return boolean
function GNIL.Validation.IsType(provided, type_enum)
    if isnumber(type_enum) then return TypeID(provided) == type_enum
    else return type(provided) == type_enum end
end