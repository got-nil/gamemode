GNIL.Commands.Arguments = GNIL.Commands.Arguments or {}

-- The pattern for this function was very kindly donated by
-- VirtualRaptor#0001 as I am too retarded to make it myself.
-- Even thought I'd move it into a shared file so the scumbags
-- that eventually filesteal all our client stuff get to see it.
function GNIL.Commands.IsSuitableName(name)
    return not string.match(name, "[^_%-.%a%d]") and true or false
end

-- Parse an argument string into a table of arguments.
-- Shamelessly "borrowed" from SAMs admin system.
function GNIL.Commands.Arguments.Parse(argstr)
    argstr = string.Trim(argstr)
    local args, buffer, in_text = {}, "", false
    for i = 1, #argstr do
        local c = string.sub(argstr, i, i)
        if c == "\"" then
            in_text = not in_text
            if buffer != "" or not in_text then
                args[#args + 1], buffer = buffer, ""
            end
        elseif c != " " or in_text then
            buffer = buffer .. c
        elseif buffer != "" then
            args[#args + 1], buffer = buffer, ""
        end
    end
    if buffer != "" then args[#args + 1] = buffer end    
    return args
end

-- Validate provided command arguments as being a
-- table structured in the way we expect it to be.
function GNIL.Commands.Arguments.Validate(arguments)
    if not (istable(arguments) and table.IsSequential(arguments)) then return false, "Table must be a sequential table of GNIL_CMD_ARGUMENT_ enums" end
    for _, v in ipairs(arguments) do
        if v != nil and isnumber(v) and (v == GNIL_CMD_ARGUMENT_REPEAT or v == GNIL_CMD_ARGUMENT_END) then continue end
        if not (isnumber(v) and table.HasValue(GNIL_CMD_ARGUMENTS, v)) then return false, "An argument must be a GNIL_CMD_ARGUMENT_ enum" end
    end
    return true, nil
end

-- Convert a provided input using the typeid validator/converter.
-- Returns nil if invalid, or anything else if valid.
function GNIL.Commands.Arguments.Convert(arg, typeid, ply)
    typeid = tostring(typeid)
    if not GNIL.Commands.Arguments.Types[typeid] then return nil end
    return GNIL.Commands.Arguments.Types[typeid][1](arg, ply)
end

/*
    The structure for this table should be as follows:
    
    GNIL_CMD_ARGUMENT_? = {
        validatorFunction,
        autocompleteFunction?
    }

    The validatorFunction should accept any type and either return the
    type that should be passed to the command callable, or nil representing
    that the value provided is invalid.

    The autocompleteFunction is optional, and can be omitted. If its provided
    it functions basically the same as a normal concommand autocomplete, however
    the command is not passed through (as thats handled internally).

    The autocompleteFunction could also be a static string/table that is used
    as a static suggestion(s). This is most useful for generic option sets or
    typehints.

*/

local genericTypeNames = {
    [GNIL_CMD_ARGUMENT_PLAYER] = "Player",
    [GNIL_CMD_ARGUMENT_INTEGER] = "Integer",
    [GNIL_CMD_ARGUMENT_STRING] = "String",
    [GNIL_CMD_ARGUMENT_VECTOR] = "Vector"
}

local genericArguments = {
    [GNIL_CMD_ARGUMENT_PLAYER] = {
        function(arg, ply)

            -- If the argument provided is ^ then we should
            -- return the calling player as a shortcut for
            -- self referencing. This is common in admin systems.
            if arg == "^" then return ply end

            for _, v in ipairs(player.GetAll()) do
                if v:SteamID64() == arg then return v end
                if v:SteamID() == arg then return v end
                if v:Nick() == arg then return v end
            end
            return nil
        end,
        function(arg)
            if arg[1] == "\"" and arg[#arg] == "\"" then
                return {arg}
            end

            local plys = {}
            for _, v in ipairs(player.GetAll()) do
                local n = v:Nick()
                if 3 > #arg or string.find(string.lower(n), arg) then
                    table.insert(plys, "\"" .. n .. "\"")
                end
            end
            return plys
        end
    },
    [GNIL_CMD_ARGUMENT_INTEGER] = {
        function(arg)
            if (arg == "" or string.find(arg, "%D")) then return nil end
            return tonumber(arg)
        end,
        "<integer>"
    },
    [GNIL_CMD_ARGUMENT_STRING] = {
        function(arg) return tostring(arg) end,
        "<string>"
    },
    [GNIL_CMD_ARGUMENT_VECTOR] = {
        function(arg)
            if not isstring(arg) then return nil end
            
            -- Validate that the provided argument looks like a vector
            -- then explode it and construct an actual vector pos from it.

            -- Thankyou again to VirtualRaptor#0001 for this pattern.
            local x, y, z = string.match(arg, "(%-?%d+%.*%d*)[,%s]%s-(%-?%d+%.*%d*)[,%s]%s-(%-?%d+%.*%d*)")
            if x and y and z then return Vector(tonumber(x), tonumber(y), tonumber(z)) end
            return nil
        end,
        function(arg)
            return {"\"" .. tostring(LocalPlayer():GetPos()) .. "\""}
        end
    }
}

-- Convert the table to use string keys instead of numbers.
local function stringKeyTable(tbl)
    local newtbl = {}
    for k, v in pairs(tbl) do
        newtbl[tostring(k)] = v
    end
    return newtbl
end

GNIL.Commands.Arguments.Types = stringKeyTable(genericArguments)
GNIL.Commands.Arguments.TypeNames = stringKeyTable(genericTypeNames)