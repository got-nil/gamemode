GNIL.Commands.Receiver = {}

-- The server concommand handler! (Does not support autocomplete etc).
concommand.Add(
    "gnil",
    function(_, __, args, argstr)

        -- If there are no arguments provided, show the default view with all commands.
        if #args == 0 then
            GNIL.Commands.print_logo()

            -- Find all commands that the server has permission to execute.
            -- This is basically all commands execpt those that have the
            -- 'SERVER_EXECUTION_ALLOWED' flag explictly disabled.
            local server_cmds = {}
            for k, v in pairs(GNIL.Commands["_r"]) do
                if GNIL.Commands.CanAccess(k, nil) then
                    server_cmds[k] = v
                end
            end

            -- If there are no commands, show a little message.
            if #table.GetKeys(server_cmds) == 0 then
                GNIL.log("There are no commands found (or no commands that the server has access to).", "warning")
                return
            end

            -- Print all the commands found.
            Msg("Server commands:\n")
            for name, v in pairs(server_cmds) do
                MsgC(GNIL.Commands.logo_color, "    gnil " .. name)

                -- If there arguments for the command, we should display them here.
                if v[2] then
                    MsgC(GNIL.Commands.logo_color, " " .. GNIL.Commands.Arguments.GetArgumentsPreview(v[2]))
                end
                Msg("\n")
            end
            Msg("\n")
            return
        end

        -- If there are arguments provided, directly call the reciever execute.
        GNIL.Commands.Receiver.Execute(argstr, nil)
    end,
    "The GotNil core gamemode commands"
)

function GNIL.Commands.Receiver.Execute(argstr, ply)
    if argstr == "" then return end

    -- Get the logger that should be used for errors. (Player logger if
    -- provided, or just the default log function for server executions.)
    local rlog = function(...)
        if ply then return ply:log(...)
        else return GNIL.log(...) end
    end

    -- Parse the raw argument string into its individual parts.
    local args = GNIL.Commands.Arguments.Parse(argstr)
    if #args == 0 then rlog("Invalid arguments string provided.", "error") return end

    -- For "Security" the same error message should be used irregardless
    -- of validation issue. This means that a client cant use the different
    -- error messages to slowly map out the commands. (People can be dedicated).
    -- (Unless we're server, in which case we should just show the raw errors)
    local error_message_fn = function(m)
        if ply then return "Invalid/Unknown command provided."
        else return m end
    end

    -- Check to see if the requested command exists.
    local command = GNIL.Commands["_r"][string.lower(args[1])]
    if command == nil then rlog(error_message_fn("Provided command does not exist."), "error") return end

    -- Ensure that the required arguments are present. (If there are arguments
    -- defined by the command to begin with)
    if command[2] and (#args - 1) != #command[2] then rlog(error_message_fn("Missing required argument count for command."), "error") return end

    -- Check to see if the player can access the command.
    if not GNIL.Commands.CanAccess(args[1], ply) then rlog(error_message_fn("Cannot access requested command."), "error") return end

    -- At this point, we know that the client has sent a valid command, with the
    -- correct amount of arguments (if applicable) and they have access. We should
    -- now continue with validating each argument individually.
    local arguments = {}
    if command[2] then
        for i = 2, #args do

            -- Convert the provided argument with the defined type id.
            local converted = GNIL.Commands.Arguments.Convert(args[i], command[2][i-1], ply)
            if converted == nil then
                rlog("Couldn't validate provided argument #" .. i, "error")
                return
            end
            table.insert(arguments, converted)
        end
    end

    -- Finally, call the command callback!
    command[1](ply, arguments)
end

GNIL.Net.Receive("module_commands_executed", function(_, ply)
    GNIL.Commands.Receiver.Execute(net.ReadString(), ply)
end)