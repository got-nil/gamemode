
-- Recieve serverside commands manifest and store on the client, allowing
-- for basic autocomplete to be handled as the client knows the argument structure.
-- Default state is nil meaning that the server has not sent anything yet. Even when
-- the server explictly sends no commands, this just becomes an empty table.
GNIL.Commands["_r"] = nil

net.Receive("gnil_cmds", function()
    local commands = {}

    -- Check if we're actually recieving any commands.
    if net.ReadBit() == 0 then
        GNIL.log("The server sent no commands", "debug")
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
            GNIL.Commands.DiscoveredCommands[command_hash] = new_hash
            GNIL.log("Discovered plaintext command '" .. command_hash .. "'", "debug")
        end

        if net.ReadBool() then
            for x = 1, net.ReadUInt(8) do
                command_arguments[x] = net.ReadUInt(7)
            end
            GNIL.log("Found " .. #command_arguments .. " arguments for command '" .. command_hash .. "'", "debug")
        else
            command_arguments = true -- cant be nil
            GNIL.log("Command '" .. command_hash .. "' does not provide any arguments.", "debug")
        end

        commands[command_plaintext and new_hash or command_hash] = command_arguments
    end
    GNIL.log("Successfully synchronised " .. command_count .. " commands.", "debug")
    
    -- Set the client commands registry to the gathered command data.
    if GNIL.Commands["_r"] == nil then GNIL.Commands["_r"] = {} end
    for k, v in pairs(commands) do GNIL.Commands["_r"][k] = v end
end)