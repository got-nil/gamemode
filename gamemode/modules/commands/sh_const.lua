
-- Command access types
GNIL_CMD_ACCESS_ADMIN = 0           -- Only allow administrator access
GNIL_CMD_ACCESS_SUPERADMIN = 1      -- Superadmin rank only
GNIL_CMD_ACCESS_DEVELOPER = 2       -- Verified GNIL developers only

-- Command argument types
GNIL_CMD_ARGUMENT_PLAYER = 1        -- The argument should be another player
GNIL_CMD_ARGUMENT_INTEGER = 2       -- The argument should be a positive integer
GNIL_CMD_ARGUMENT_STRING = 3        -- The argument is a string
GNIL_CMD_ARGUMENT_VECTOR = 10       -- The argument should be a vector representation

-- Command argument flow control, allows for variable argument count or ending string combination.
GNIL_CMD_ARGUMENT_REPEAT = 99   -- Ends the arguments by making any following argument type repeat the one previous, argument becomes sequential table of types.
GNIL_CMD_ARGUMENT_END = 100     -- Marks the end of the argument list. If the last argument was a string, all following arguments are appended.

-- DO NOT TOUCH THIS UNLESS YOU'RE ADDING ANOTHER ARGUMENT ENUM!
GNIL_CMD_ARGUMENTS = {
    GNIL_CMD_ARGUMENT_PLAYER,
    GNIL_CMD_ARGUMENT_INTEGER,
    GNIL_CMD_ARGUMENT_STRING,
    GNIL_CMD_ARGUMENT_VECTOR,
    GNIL_CMD_ARGUMENT_REPEAT,
    GNIL_CMD_ARGUMENT_END    
}