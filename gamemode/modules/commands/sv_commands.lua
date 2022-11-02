local MODULE = MODULE

-- Cache all hashed names
GNIL.Commands.HashedNames = {}
local function getHashedName(name)
    if not GNIL.Commands.HashedNames[name] then
        GNIL.Commands.HashedNames[name] = util.SHA256(name)
    end
    return GNIL.Commands.HashedNames[name]
end 

-- The network structure will remain the same, however eventually all the
-- net code will be replaced with the GNIL net lib once I get around to it.
util.AddNetworkString("gnil_cmds")

-- The "flush" argument determines if the client should completely reset their
-- command registry when recieving this command structure. Therefore it should
-- only be used when broadcasting all commands to invalidate previously stored
-- commands (useful for rank changes etc).
local function sendPlayerCommandStructure(ply, command_name, flush)
    if ply == nil then return end
    
    -- Change the command_pool depending on if a command_name was provided.
    local command_pool = GNIL.Commands["_r"]
    if command_name then
        if not GNIL.Commands["_r"][command_name] then GNIL.log("Provided command name is unknown, cannot send command net structure.", "warning") return end

        GNIL.log("Sending " .. ply:Nick() .. " command structure for '" .. command_name .. "'", "debug")
        command_pool = {[command_name] = GNIL.Commands["_r"][command_name]}
    end

    local command_arguments = nil
    for k, v in pairs(command_pool) do
        if not GNIL.Commands.CanAccess(k, ply) then continue end -- Remove commands the player cant access

        if command_arguments == nil then command_arguments = {} end
        command_arguments[k] = v
    end

    net.Start("gnil_cmds") -- Start the net message
    net.WriteBool(isbool(flush) and flush != false and flush or false) -- Send the registry flush signal
    
    -- If there aren't any commands collected, then there either no defined commands or
    -- the user doesn't have access to any of the commands to begin with. We should still
    -- network this to the client, essentially informing them that they have access to no
    -- commands so it doesnt look like they just never recieved any commands to begin with.
    if command_arguments == nil then
        net.WriteBool(false) -- Literally tell the player they're getting nothing.
    else
        net.WriteBool(true) -- Signify that commands are actually going to be sent
        net.WriteUInt(#table.GetKeys(command_arguments), 10) -- The amount of commands that will be sent
        
        for name, data in pairs(command_arguments) do
            net.WriteBool(data[4]) -- Is the string below plaintext?
            net.WriteString(data[4] and name or getHashedName(name)) -- The hashed command name 
            net.WriteBool(data[2] != false) -- Are there arguments defined

            -- Only write the argument types if the command actually has defined arguments.
            if data[2] != false then
                net.WriteUInt(#table.GetKeys(data[2]), 8) -- The amount of arguments within the command
                for _, argument in ipairs(data[2]) do
                    net.WriteUInt(argument, 7) -- Write the argument type
                end
            end
        end    
    end

    -- Send the constucted message to the client.
    net.Send(ply)
end

-- Send the command structure to all connected clients.
-- Also allows for specific commands to be sent to a client
-- instead of having to resend all of them (used for late commands).
local function broadcastCommandsStructure(command_name, flush)
    if flush == nil then flush = true end
    GNIL.log("Broadcasting commands structure to clients. " .. (flush and "Flushing registries." or "Appending to registries."), "debug")
    for _, v in ipairs(player.GetAll()) do
        sendPlayerCommandStructure(v, command_name, flush)
    end
end

-- Get a flag value from command flags table, or return provided default
-- if the given flag does not exist within the command (safe checking).
local function getFlagFromCommand(command_data, flag, default)
    if command_data[5] == false then return default end
    if command_data[5][flag] then return command_data[5][flag]
    else return default end
end

-- Generic access validator callbacks
local genericAccessValidators = {
    [GNIL_CMD_ACCESS_SERVER] = function(ply) return ply == nil end,
    [GNIL_CMD_ACCESS_ADMIN] = function(ply) return ply:IsAdmin() end,
    [GNIL_CMD_ACCESS_SUPERADMIN] = function(ply) return ply:IsSuperAdmin() end,
    [GNIL_CMD_ACCESS_DEVELOPER] = function(ply) return false end -- TODO
}

function GNIL.Commands.CanAccess(command_name, ply)
    if not GNIL.Commands["_r"][command_name] then return end
    local command = GNIL.Commands["_r"][command_name]

    -- If there is no player caller (server called command) then we should ensure the
    -- command does not have the 'SERVER_EXECUTION_ALLOWED' flag disabled. If it doesn't
    -- then we should bypass any additional validation.
    if ply == nil then
        local rtrn = getFlagFromCommand(command, "SERVER_EXECUTION_ALLOWED", true)
        if isbool(rtrn) then return rtrn else return false end
    end

    -- If the command doesnt not have an access validator we should just allow anyone
    -- and hope that the person who created the command has a good reason for doing so.
    if command[3] == false then return true end

    if isfunction(command[3]) then
        return command[3](ply)        
    else
        if genericAccessValidators[command[3]] then
            return genericAccessValidators[command[3]](ply)            
        else
            GNIL.log("Invalid generic access validator used for command '" .. command_name .. "'", "warning")
            return false
        end
    end
end

-- Set by the Initialize hook to allow late commands to still broadcast to clients.
if SHOULD_BROADCAST_NEW_COMMANDS == nil then
    SHOULD_BROADCAST_NEW_COMMANDS = false
end

-- Create a new OOP command instance.
-- THIS DOES NOT ACTUALLY ADD THE COMMAND, YOU NEED TO CALL :End ON THE INSTANCE
-- AFTER YOU'VE FINISHED EDITING IT. !!!PLEASE KEEP THIS IN MIND!!!
function GNIL.Commands.Create(name, callback)
    assert(GNIL.Commands.IsSuitableName(name), "The command name is unsuitable")
    assert(isfunction(callback), "The callback argument must be a function")

    return GNIL.Commands.OOP:New(name, callback)
end

-- Another method of creating commands. Accepts an associative table, where each key
-- is a named argument (see GNIL.Commands.Add parameters).
function GNIL.Commands.AddFromTable(tbl)
    assert(istable(tbl) and not table.IsSequential(tbl), "The provided value must be an associative table")
    return GNIL.Commands.Add(
        tbl["name"],
        tbl["callback"],
        tbl["arguments"],
        tbl["access_check"],
        tbl["public"],
        tbl["flags"]
    )
end

-- Ensure that the arguments 
-- target should be a GNIL_COMMAND_ const value.
function GNIL.Commands.Add(name, callback, arguments, access_check, public, flags)
    assert(GNIL.Commands.IsSuitableName(name), "The command name is unsuitable")
    assert(isfunction(callback), "The callback argument must be a function")

    assert(arguments == nil or istable(arguments), "The arguments table is optional, however it must either be nil or a structured arguments table")
    assert(access_check == nil or isnumber(access_check) or isfunction(access_check), "The access check callback is optional, however it must either be nil or a function callback (or a GNIL_CMD_ACCESS_ enum)")
    assert(public == nil or isbool(public), "The public argument is optional, however it must either be nil or boolean")
    assert(flags == nil or (istable(flags) and not table.IsSequential(flags)), "The flags argument is optional, however is must be either nil or an associative table of flags.")

    -- Take an additional step to validate arguments if provided.
    if arguments then
        local valid, issue = GNIL.Commands.Arguments.Validate(arguments)
        if not valid then error("Arguments validation error: " .. issue) end
    end

    -- Use false instead of nil in the table to represent nothingness.
    if arguments == nil then arguments = false end
    if access_check == nil then access_check = false end
    if public == nil then public = false end
    if flags == nil then flags = false end

    -- Validate that the flags table only contains strings if provided.
    -- Also convert all strings to uppercase for standardisation.
    if flags then
        local upper_flags = {}
        for k, v in pairs(flags) do
            assert(isstring(k), "All keys within the flags table must be strings.")
            upper_flags[string.upper(k)] = v
        end

        flags = upper_flags
    end

    -- Actually push the command
    name = string.lower(name)
    GNIL.log("Created command '" .. name .. "' in server reference.", "debug")
    GNIL.Commands._r[name] = {
        callback,       -- Callback for command execution
        arguments,      -- Arguments the command uses
        access_check,   -- Access check callback (or GNIL_CMD_ARGUMENT_ enum)
        public,         -- Should the command name be sent as plaintext?
        flags           -- A list of any additional flags applied to the command
    }

    -- If a new command has just been pushed, we should broadcast if we've already
    -- initialised and sent the original command set (delayed command setup).
    if SHOULD_BROADCAST_NEW_COMMANDS then
        GNIL.log("Broadcasting newly created command '" .. name .. "' structure to clients. For optimisation commands should be added before server initialization.", "warning")
        broadcastCommandsStructure(name, false)
    end

    return true
end

-- Send the command structure to clients when possible.
hook.Add("Initialize", "gnil_cmds_init_send", function() broadcastCommandsStructure() SHOULD_BROADCAST_NEW_COMMANDS = true end)
hook.Add("PlayerNetLoad", "gnil_cmds_load_send", function(ply) sendPlayerCommandStructure(ply) end)

-- Broadcast the command structure whenever theres a lua refresh.
if _broadcastLuaRefresh then
    GNIL.log("Broadcasting command structure due to LUA refresh.", "success")
    broadcastCommandsStructure()
else
    _broadcastLuaRefresh = true
end

/*

    When a players usergroup is changed, we should send the
    command structure back to them, ensuring that it flushes
    their command registry/discovered commands.

    This forces the server to re-run the access checks for the
    player revoking/adding commands depending on their new
    usergroup permissions.

    Obviously the server still checks their access when they run
    the command, this is just to hide/show commands they lost/gained
    from the group change.

*/

hook.Add("CAMI.PlayerUsergroupChanged", "gnil_cmds_refresh", function(ply)
    GNIL.log(ply:Nick() .. "'s usergroup has changed, re-sending command structure to them.", "debug")
    sendPlayerCommandStructure(ply, nil, true) -- no specific command, flush
end)