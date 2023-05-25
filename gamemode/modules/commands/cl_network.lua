local MODULE = MODULE

-- Recieve serverside commands manifest and store on the client, allowing
-- for basic autocomplete to be handled as the client knows the argument structure.
-- Default state is nil meaning that the server has not sent anything yet. Even when
-- the server explictly sends no commands, this just becomes an empty table.

GNIL.Net.Receive("module_commands_sync", function()
    local commands, discovered = {}, {}

    -- The server will send a "flush" signal to tell the client that
    -- it should fully reset its command registry and use the provided
    -- commands as the new ones instead of just adding to it.
    local flush = net.ReadBool()

    -- Check if we're actually recieving any commands.
    if not net.ReadBool() then
        MODULE:log("The server sent no commands", "debug")
        GNIL.Commands["_r"] = {}
        return
    end

    local command_count = net.ReadUInt(10)
    for i = 1, command_count do

        -- Get the command name and if its been hashed.
        local command_plaintext, command_hash, command_arguments = net.ReadBool(), net.ReadString(), {}
        
        -- If the provided command is plaintext, we should add it to
        -- the list of discovered commands and generate the actual hash
        -- for it.
        if command_plaintext then
            new_hash = util.SHA256(command_hash)
            discovered[command_hash] = new_hash
            MODULE:log("Discovered plaintext command '" .. command_hash .. "'", "debug")
        end

        if net.ReadBool() then
            for x = 1, net.ReadUInt(8) do
                command_arguments[x] = net.ReadUInt(7)
            end
            MODULE:log("Found " .. #command_arguments .. " arguments for command '" .. command_hash .. "'", "debug")
        else
            command_arguments = true -- cant be nil
            MODULE:log("Command '" .. command_hash .. "' does not provide any arguments.", "debug")
        end

        commands[command_plaintext and new_hash or command_hash] = command_arguments
    end
    MODULE:log("Successfully synchronised " .. command_count .. " commands. " .. (flush and "Flushing registry" or "Appending to registry") .. ".", "debug")

    if flush then
        GNIL.Commands["_r"] = commands
        GNIL.Commands.DiscoveredCommands = {}
    else
        if GNIL.Commands["_r"] == nil then GNIL.Commands["_r"] = {} end
        for k, v in pairs(commands) do GNIL.Commands["_r"][k] = v end
    end

    -- Finally, if there are any discovered commands
    -- (public commands) we should add them here (after flush).
    for k, v in pairs(discovered) do
        GNIL.Commands.DiscoveredCommands[k] = v
    end
end)