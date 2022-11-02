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

## Command Arguments
Commands can choose to define existing argument types, or parse arguments themselves. Using existing types also allows for the command to be autocompleted in the console with helpful hint/suggestions etc.

There are multiple argument types, however only the trickier ones are documented (since cba documenting the really simple ones you should be able to get that yourself).

### GNIL_CMD_ARGUMENT_ENTITY_MULTI

Each "command" must start with an operator (below) to specify its type. Arguments are then (usually) split using a `,` character. After the operator, there should be a type specifier. This is `[` for multiples, or `(` for singles (different operators may or may not support this, as shown in the below table) (there must also be a matching closing bracket).

For example  `%[]` would return all entities  within the default range of the calling player, however using `%()` would specify that only a single entity should be returned (the closest).

**Just to be even more confusing, Commands that omit a type specifying bracket default to single types. For example, `%prop_physics` will become `%(prop_physics)` meaning that it will return the closest `prop_physics`, Although for some operators that do not support singles, it will return multiple. For example, `*prop_physics` will return all `prop_physics` despite not having a clear multiple type bracket etc.**

`Requires player` means that a player caller is required to use the operator. The only case where the caller is not a player is when the command is being ran from the server console.

#### Command Operators
|Operator|Requires Player|Supports Single|Arguments|Description|
|--------|--------|------|---------|-----------|
|`%`|Yes|Yes|`?class_name(str)`, `?range(int)`|Find all entities with classname in given range. If classname omitted, return all entities in range.|
|`@`|Yes|Always|None|Return the entity that is being looked at by the calling player.|
|`*`|No|No|`?class_name`|Returns all entities of given classname, or just all entities.|
|`^`|Yes|Always|None|Returns the current calling player.|
|`+`|No|No|`cmd1 cmd2 ...`|Combine the results of each macrocommand provided, seperated with `|` character. **Duplicate entities are removed**.
|`;`|No|No|`cmd1 cmd2 ...`|The exact same as the `+` operator, however **duplicate entities are not removed**.

#### Command Examples

1. Targeting all `printer` entities within a range of `900`:  `%[printer, 900]`
2. Targeting the entity you're looking at, and yourself: `+[^|@]`
3. Targeting the nearest `sent_ball` and all `prop_vehicle_jeep` ents: `+[%sent_ball|*prop_vehicle_jeep]`
