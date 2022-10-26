GNIL.Commands.Receiver = {}

-- !!!TEMP NET!!!
net.Receive("gnil_cmds", function(_, ply)
    local argstr = net.ReadString()
    if argstr == "" then return end

    -- Parse the raw argument string into its individual parts.
    local args = GNIL.Commands.Arguments.Parse(argstr)
    if #args == 0 then ply:log("Invalid arguments string provided.", "error") return end
    
    -- For "Security" the same error message should be used irregardless
    -- of validation issue. This means that a client cant use the different
    -- error messages to slowly map out the commands. (People can be dedicated).
    local error_message = "Invalid/Unknown command provided."

    -- Check to see if the requested command exists.
    local command = GNIL.Commands["_r"][string.lower(args[1])]
    if command == nil then ply:log(error_message, "error") return end

    -- Ensure that the required arguments are present. (If there are arguments
    -- defined by the command to begin with)
    if command[2] and (#args - 1) != #command[2] then ply:log(error_message, "error") return end

    -- Check to see if the player can access the command.
    if not GNIL.Commands.CanAccess(args[1], ply) then ply:log(error_message, "error") return end
    
    -- At this point, we know that the client has sent a valid command, with the
    -- correct amount of arguments (if applicable) and they have access. We should
    -- now continue with validating each argument individually.
    local arguments = {}
    if command[2] then
        for i = 2, #args do

            -- Convert the provided argument with the defined type id.
            local converted = GNIL.Commands.Arguments.Convert(args[i], command[2][i-1])
            if converted == nil then
                ply:log("Couldn't validate provided argument #" .. i, "error")
                return
            end
            table.insert(arguments, converted)
        end
    end
    
    -- Finally, call the command callback!
    command[1](ply, arguments)
end)