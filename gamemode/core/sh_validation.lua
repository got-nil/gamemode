GNIL.Validation = {}

/*

Validate a provided table against a type structure.
These look like:

{
    ["key"] = {default, validator, required?},
    ...
}

default - The default value that should be used if the key is ommitted in the provided table.
validator - Either a table of values that should be accepted, or a TYPE enum to validate against value.
required? - Optional, is the key required in the provided table? (Default: false)

*/

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
        end
        if istable(v[2]) then
            if not table.HasValue(v[2], provided[k]) then
                return false, "Required key '" .. k .. "' is not in accepted values"
            end
        else
            if provided[k] != v[1] and isnumber(v[2]) and TypeID(provided[k]) != v[2] then
                return false, "Required key '" .. k .. "' is an invalid type: " .. type(provided[k])
            end
        end
    end
    return true, provided
end

function GNIL.Validation.IsType(provided, type_enum)
    if isnumber(type_enum) then return TypeID(provided) == type_enum
    else return type(provided) == type_enum end
end