GNIL.Commands.Autocomplete = {}

function GNIL.Commands.AutocompleteType(typeid, argstr)
    if not GNIL.Commands.Arguments.Types[typeid] then return end
    
    -- Ensure that the argument type actually defines an autocomplete
    local argumentType = GNIL.Commands.Arguments.Types[typeid]
    if 2 > #argumentType then return end 

    -- Run the argument autocomplete
    return argumentType[2](argstr)
end


-- Add a prefix to a sequential table of strings
local function prefixStringsTable(tbl, prefix)
    local new_tbl = {}
    for i, v in ipairs(tbl) do
        new_tbl[i] = prefix .. v
    end
    return new_tbl
end

-- Process the autocomplete for the GNIL root command.
function GNIL.Commands.Autocomplete.Process(cmd, strargs)
    if GNIL.Commands["_r"] == nil then return end
    local args = GNIL.Commands.Arguments.Parse(strargs)

    if #args >= 1 then GNIL.Commands.Discover(args[1]) end
    if 1 >= #args and not GNIL.Commands.DiscoveredCommands[args[1]] then
    
        -- If there are no/one argument we should just show the discovered commands
        return prefixStringsTable(table.GetKeys(GNIL.Commands.DiscoveredCommands), cmd .. " ")

    else
        local currentArgumentPos = #args - 1
        
        -- If there are additional arguments after the command name, we should check to
        -- see if the first command argument has been discovered, and if it has registered
        -- arguments attached to it.
        local cmd_arguments = GNIL.Commands.GetCommandArgumentsByPlaintext(args[1])
        if not cmd_arguments or cmd_arguments == true then return end

        -- If the command exists and we're on the first argument then we should show a
        -- summary of the arguments data types.
        if (currentArgumentPos == 0) then

            local typeSummary = {}
            for _, argumentid in ipairs(cmd_arguments) do
                table.insert(typeSummary, "<" .. string.lower(GNIL.Commands.Arguments.TypeNames[tostring(argumentid)]) .. ">")
            end

            return {"gnil " .. args[1] .. " " .. table.concat(typeSummary, " ")}
        end

        -- Ensure that the current argument doesn't exceed the max permitted arguments.
        if (currentArgumentPos > #cmd_arguments) then return end

        -- Check to see if the current argument has a defined autocomplete function.
        local arg = tostring(cmd_arguments[currentArgumentPos])
        local argumentTypeData = GNIL.Commands.Arguments.Types[arg]
        if 2 > #argumentTypeData then return end

        -- Call the argument autocomplete callback.
        local autocompleteOutput = nil
        if isfunction(argumentTypeData[2]) then
            autocompleteOutput = argumentTypeData[2](args[currentArgumentPos + 1])
        else

            -- If the callback isn't a function we should just use whatever the second
            -- argument is as the suggestion table (ensuring that its a table).
            autocompleteOutput = argumentTypeData[2]
            if not istable(autocompleteOutput) then autocompleteOutput = {autocompleteOutput} end
        end
        if not autocompleteOutput then return end

        -- Return the constructed autocomplete suggestions, prefixing them with the other
        -- arguments and a final space character to pad the suggestion.
        return prefixStringsTable(autocompleteOutput, "gnil " .. table.concat(args, " ", 1, currentArgumentPos) .. " ")
    end
end