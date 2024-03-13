GNIL.Commands.Arguments = GNIL.Commands.Arguments or {}

-- The pattern for this function was very kindly donated by
-- VirtualRaptor#0001 as I am too retarded to make it myself.
-- Even thought I'd move it into a shared file so the scumbags
-- that eventually filesteal all our client stuff get to see it.
function GNIL.Commands.IsSuitableName(name)
    return not string.match(name, "[^_%-.%a%d]") and true or false
end

-- Get a preview of the arguments types. Eg: <integer> <player> ...
function GNIL.Commands.Arguments.GetArgumentsPreview(arguments)
    if arguments == nil or not istable(arguments) then return "" end
    local typeSummary = {}
    for _, argumentid in ipairs(arguments) do
        table.insert(typeSummary, "<" .. string.lower(GNIL.Commands.Arguments.TypeNames[tostring(argumentid)]) .. ">")
    end
    return table.concat(typeSummary, " ")
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

    The validatorFunction function should be a callable with a structure as:
        Input Arguments:
            - argument: string = The user inputted argument
            - caller: ?ply = The command caller or nil when command called from server

        Returns:
            - ?output: Any = The output from the converter. Or nil for invalid inputs

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
    [GNIL_CMD_ARGUMENT_VECTOR] = "Vector",
    [GNIL_CMD_ARGUMENT_ENTITY_SINGLE] = "Entity",
    [GNIL_CMD_ARGUMENT_ENTITY_MULTI] = "Entities"
}

local genericArguments = {
    [GNIL_CMD_ARGUMENT_PLAYER] = {
        function(arg, ply)

            -- If the argument provided is ^ then we should
            -- return the calling player as a shortcut for
            -- self referencing. This is common in admin systems.
            -- (Provided there is a player argument for the caller)
            if ply != nil and arg == "^" then return ply end

            for _, v in player.Iterator() do
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
            for _, v in player.Iterator() do
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
            if (arg == "" or string.match(arg, "%D")) then return nil end
            return tonumber(arg)
        end,
        "<integer>"
    },
    [GNIL_CMD_ARGUMENT_STRING] = {
        function(arg) return tostring(arg) end,
        "<string>"
    },
    [GNIL_CMD_ARGUMENT_VECTOR] = {
        function(arg, ply)

            -- If the argument begins with a hashtag and contains just numbers then
            -- we should treat it as an alias to a players location.
            if arg[1] == "#" and string.match(arg, "#([%d]+)") then
                local target = Player(tonumber(string.sub(arg, 2)))
                if target == nil then return nil end
                return target:GetPos()
            end

            -- If the argument is an alias, then return that position instead.
            -- However, also note that this only works when the caller is a player
            -- (not server called commands) so we must also validate that.
            if ply != nil then
                local aliases = {
                    ["here"] = function(ply) return ply:GetPos() end,
                    ["there"] = function(ply) return ply:GetEyeTrace().HitPos end
                }
                arg = string.lower(arg)

                -- If the argument matches a known alias, run the callback and return
                -- its output directly.
                if aliases[arg] then
                    return aliases[arg](ply)
                end
            end

            -- Validate that the provided argument looks like a vector
            -- then explode it and construct an actual vector pos from it.
            -- Thankyou again to VirtualRaptor#0001 for this pattern.
            local x, y, z = string.match(arg, "(%-?%d+%.*%d*)[,%s]%s-(%-?%d+%.*%d*)[,%s]%s-(%-?%d+%.*%d*)")
            if x and y and z then return Vector(tonumber(x), tonumber(y), tonumber(z)) end
            return nil
        end,
        function()
            return {
                "\"" .. tostring(LocalPlayer():GetPos()) .. "\"",
                "here", -- Alias to the players current location
                "there", -- Alias to the players view position
                "#<playerid>" -- Alias to player id current location
            }
        end
    },

    -- A very simple way to target the entity you're directly looking at,
    -- or if you're calling from server you can use the direct ent id.
    [GNIL_CMD_ARGUMENT_ENTITY_SINGLE] = {
        function(arg, ply)

            -- If there is no caller provided, use the argument as
            -- the entity id number directly. Cannot be world.
            if ply == nil then
                arg = tonumber(arg, 10)
                if arg == nil or arg == 0 then return false end
                return Entity(arg)
            end

            -- If there is a player, return the eye trace result.
            -- (or nil if theres no result, which is handy for invalid)
            return ply:GetEyeTrace().Entity
        end,
        function()

            -- Since this autocomplete only runs clientside, we can put
            -- whatever we want here, since the validator completely ignores
            -- the inputted argument as a client.
            local e = ply:GetEyeTrace().Entity
            if e == nil then return {"<entity (Not Found)>"} end
            return {"<entity (" .. e:GetClass() .. " #" .. e:EntIndex() .. ")>"}
        end
    },

    -- This is the far more advanced entity targetting system that uses the
    -- syntax defined in sv_ent_parser. It allows for multiple entities to be
    -- selectively targetted for mass actions.
    [GNIL_CMD_ARGUMENT_ENTITY_MULTI] = {
        function(arg, ply)

            -- Simply execute the provided argument as a macro, validation etc
            -- happens within the execute function anyway.
            return GNIL.Commands.EntParser.Execute(arg, ply)
        end,

        -- Really neat autocomplete and help previews!
        function(arg)
            if arg == "" or arg == "?" then
                return {
                    "% - Range lookup",
                    "@ - Direct selector",
                    "* - World lookup",
                    "^ - Current player",
                    "+ - Combine multiple command outputs, remove duplicates",
                    "; - Combine multiple command outputs, keep duplicates"
                }
            else

                -- If there is more text typed, we should attempt to show hints
                -- depending on the first character of the argument (operator).
                local operatorHints = {
                    ["%"] = "%[ ?class_name, ?range ]",
                    ["@"] = "@",
                    ["*"] = "*[ class_name ]",
                    ["^"] = "^",
                    ["+"] = "+[ a | b ... ]",
                    [";"] = ";[ a | b ... ]"
                }

                local operator = arg[1]
                if operatorHints[operator] then
                    return {operatorHints[operator]}
                end
            end
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