# GotNil Commands Module
This module provides a server interface for creating concommands with extra features, such as console argument autocomplete, hidden/hashed commands and pre-send access checks. (by morgverd)

## Implementation Notes

**Commands can only be created by the server**, since personally I believe that client created commands make very little sense. If you really need to have a command run stuff on a client, either network it over (like a real man) or just use the standard `concommand.Add` function. (Although the second was a joke).

**Commands should be created as soon as possible**, any commands added after server initialization will result in the server having to re-broadcast the command structure to clients (just the command created since its optimised, ik im a pro).

## Command arguments

These are the arguments that are used in every interface when creating a command. If an option is not required, then it may be `nil` to ignore it.

### Types/Structures
|Name|Description|
|----|-----------|
|suitablestring|All command names must be suitable, Specifically, it must contain only alphabetical characters and numbers, no punctuation or spaces.
|argtable|This is a sequential array of `GNIL_CMD_ARGUMENT` enums.

### Arguments
|Name|Required|Type|Description|
|----|--------|----|-----------|
|name|Yes|suitablestring|Believe it or not, this is the name of the command.|
|callback|Yes|function|This is the function that is called when the command is ran.|
|arguments|No|argtable|A table of argument types (see above) for autocomplete.
|access_check|No|enum or function|Either a `GNIL_CMD_ACCESS` enum, or callback that accepts the player and returns if they can access the command or not.|
|public|No|bool|Should the command be sent to the client as already discovered.|

## How to create a command
There is three ways to create/configure commands depending on what interface/style you decide to use.

### Functional
This is how commands are actually added, all other interfaces are simply abstractions that ultimately call `GNIL.Commands.Add(name, callback, arguments, access_check, public)`.

```lua

-- ply is the command caller
local callback = function(ply, args)
	
	-- Arguments are sent back in the same order
	-- they are defined (if there are any). So the
	-- first argument will be the player instance
	-- targeted.
	args[1]:Kill()
	args[1]:PrintMessage(args[2])
end

local arguments = {
	GNIL_CMD_ARGUMENT_PLAYER, -- Target a player in the server
	GNIL_CMD_ARGUMENT_STRING  -- Accept any string
}

-- Create/Add the command, setting the default access level to admin and making
-- the command public. This means that it will automatically show for admins.
GNIL.Commands.Add("murder", callback, arguments, GNIL_CMD_ACCESS_ADMIN, true) 
```

### From Table
This really is the simplest method for creating commands. It uses `GNIL.Commands.AddFromTable(tbl)` and works the exact same as above (functional), however the arguments are put into an associative table with each key being the argument name. You'll get it when you see how easy the example is.

```lua

GNIL.Commands.AddFromTable({
	["name"] = "kickme",
	["public"] = true,		-- Arguments do not have to be in order
	["callback"] = function(ply)
		
		-- Im running out of example commands if you cant tell.
		ply:Kick()
	end
})

```

### Object Oriented Programming
If you're feeling fancy, you can create a `GNCommand` command instance using `GNIL.Commands.Create(name, callback)`. **Keep in mind that the create function simply returns an un-added command instance, you still have to run `:End()` on it to actually add it as a command.**

```lua

local cmd = GNIL.Commands.Create("ban", function(ply, args)
	
	-- Ban the targetted player with the length integer.
	local name = args[1]:Nick() -- Get the name before banning them.
	args[1]:Ban(args[3], true)
	
	-- Completely unneeded but its an example.
	for _, v in ipairs(player.GetAll()) do
		v:PrintMessage(HUD_PRINTTALK, name .. " was banned for: " .. args[2])
	end
end)

cmd:AddArgument(GNIL_CMD_ARGUMENT_PLAYER)   -- Targetted player
   :AddArgument(GNIL_CMD_ARGUMENT_STRING)   -- Ban reason
   :AddArgument(GNIL_CMD_ARGUMENT_INTEGER)  -- Ban length

-- Heres an example of using a custom access validator to
-- only let my steam ID use/see the ban command.
cmd:SetAccessCheck(function(ply)
	return ply:SteamID() == "STEAM_0:1:170509247"
end)

-- You MUST remember to end the command or it will not be added.
cmd:End()
```

