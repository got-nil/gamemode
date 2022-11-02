/*

    Parse entities argument target syntax. Since we process the command
    serverside this entire file can be hidden away on the server too!
    
    Command Syntax Format:
        Operator - The first character specifying the operation.
        Type - Each entity can either be a single or multiple.
            This is determined by the second character (after
            the operator). If it is not a bracket '[' or '(' then
            it is treated as a single by default.

            If there is a bracket, there must also be a matching closing
            bracket on the other side. Bracket types:
                ( - Single
                [ - Multiple

        Argument - The actual inputted arguments. Split by a comma.

    % - Range lookup
      - Arguments: ?class_name, ?range (default: 500)

    @ - Direct selector (nil if not looking at entity)
    
    * - World class lookup (using single returns the first found of class)
      - Arguments: class_name

    ^ - The current player if one is being used (nil on server)

    + - Combine the results of multiple commands
      - Arguments: commands (split with |)
        Each argument is parsed and executed as its own macro command with all results
        being put into a single return table, with duplicates removed.

    ; - The same as '+' however duplicate entities in the return table aren't removed


*/

GNIL.Commands.EntParser = GNIL.Commands.EntParser or {}

-- Very basic argument parser, does not support nested commands,
-- however it is alot faster than attempting to handle nested
-- commands for commands that don't actually need it.
local function basicArgumentParse(argstr)
    argstr = string.Trim(argstr)
    if string.find(argstr, ",") then return string.Explode(",", argstr)
    else return {argstr} end    
end

-- Get the classname from the argstr as the first argument. Also
-- ensure that the classname looks valid before returning it.
local function getClassnameFromArguments(argstr)
    local args = basicArgumentParse(argstr)
    if #args == 0 or args[1] == "" or not GNIL.Commands.IsSuitableName(args[1]) then return nil end
    return args[1]
end

local operators = {
    ["%"] = {
        true,
        function(single, argstr, ply)
            local arguments = basicArgumentParse(argstr)

            -- Use the provided radius argument if there is one, or 500
            local radius = #arguments >= 2 and tonumber(arguments[2]) or 500
            local found_ents = ents.FindInSphere(ply:GetPos(), radius)

            -- If there are no arguments provided, or no class provided then
            -- we should just return all the entities found in the range.
            if arguments == 0 or arguments[1] == "" then
                if single and #found_ents >= 1 then return {found_ents[1]} end
                return found_ents
            end

            -- If there is a class argument provided, then filter to only return
            -- entities matching the provided class_name argument.
            local rtrn_ents = {}
            for _, v in ipairs(found_ents) do
                if v:GetClass() == arguments[1] then
                    
                    -- If we're returning a single entity, we can just return immidiately
                    -- as one is found for maximum efficiency.
                    if single then return {v} end
                    table.insert(rtrn_ents, v)
                end
            end
            return rtrn_ents
        end
    },
    ["@"] = {
        true,
        function(single, argstr, ply)
            return {ply:GetEyeTrace().Entity}
        end
    },
    ["*"] = {
        false,
        function(_, argstr)
            local class_name = getClassnameFromArguments(argstr)
            if class_name then return ents.FindByClass(class_name)
            else return ents.GetAll() end
        end
    },
    ["^"] = {
        true,
        function(_, __, ply)
            return {ply}
        end
    },

    -- Plus operators, simply aliases to the plusArguments callback
    -- above since both operators do basically the same thing.
    ["+"] = { -- Remove duplicates
        false,
        function(_, argstr, ply) return GNIL.Commands.EntParser.Plus(true, argstr, ply) end
    },
    [";"] = { -- Do not remove duplicates
        false,
        function(_, argstr, ply) return GNIL.Commands.EntParser.Plus(false, argstr, ply) end
    }
}

-- Execute a provided singular macro.
function GNIL.Commands.EntParser.Execute(macro, ply)
    if macro == "" then return end
    macro = string.Trim(string.Replace(macro, " ", "")) -- Remove whitespaces and trim

    -- Get the operator from the first character.
    local operator = string.sub(macro, 1, 1)
    if not operators[operator] then return nil end

    -- If there is no player/caller provided ensure that the operator is
    -- able to handle this (first table value)
    if ply == nil and operators[operator][1] then return nil end

    -- Get the bracket type specified (if present).
    local single = true
    if #macro >= 3 then -- operator open_bracket close_bracket (minimum)
        local first_bracket = string.sub(macro, 2, 2)

        -- Opening bracket to expected closing
        local bracket_map = {
            ["["] = "]",
            ["("] = ")"
        }
        if not bracket_map[first_bracket] then

            -- If the first character isn't a valid bracket opening then default
            -- the macro to using single '( )' brackets.
            macro = operator .. "(" .. string.sub(macro, 2) .. ")"

        else
           
            -- If the first bracket is valid, ensure that there is a closing bracket
            -- that matches the first in the above table. If there isn't then return
            -- nil as the syntax is just super invalid.
            if not string.EndsWith(macro, bracket_map[first_bracket]) then
                return nil
            end

            if first_bracket == "[" then single = false end
        end
    
    else
        
        -- Default to single empty brackets if no arguments are provided.
        macro = operator .. "()"
    end

    -- If the macro is long enough, attempt to get the rest of the arguments
    -- from inside the brackets. (operator - opening_bracket - closing_bracket)
    local argstr = ""
    if #macro >= 3 then
        argstr = string.sub(macro, 3, #macro - 1)
    else

        -- If the argument is really really small then just remove the operator.
        argstr = string.sub(macro, 1)
    end

    -- Actually execute the operator callback.
    return operators[operator][2](single, argstr, ply)
end

-- Parse, but better. (Using a different seperator)
function GNIL.Commands.EntParser.Plus(remove_duplicates, argstr, ply)
    if string.find(argstr, "|") then

        -- There is a seperator so we should split the argstr at the
        -- seperator and evaluate each part as its own macro, adding
        -- the result into a single output table.
        local rtrn = {}
        for _, v in ipairs(string.Explode("|", argstr)) do
            GNIL.log(v)

            if v[1] == "+" then continue end
            local macroOutput = GNIL.Commands.EntParser.Execute(v, ply)
            if macroOutput != nil then
                for i = 1, #macroOutput do
                    table.insert(rtrn, macroOutput[i])
                end
            end
        end

        -- Before returning, we should remove any duplicate entities from
        -- the return table if the remove_duplicates argument is specified.
        if remove_duplicates then

            -- More efficient than having a single table that then gets made
            -- into a sequential afterwards (original design).
            local used_ids, new_rtrn = {}, {}
            for _, v in ipairs(rtrn) do
                local eid = tostring(v:EntIndex())
                if used_ids[eid] then continue end
                
                used_ids[eid] = true
                table.insert(new_rtrn, v)
            end
            
            return new_rtrn
        end
        return rtrn
        
    else
       
        -- There is no seperator, and therefore the entire argstr
        -- can be treated simply as another macro that should be
        -- executed directly.
        return GNIL.Commands.EntParser.Execute(argstr, ply)
    end
end