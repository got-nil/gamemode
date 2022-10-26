MODULE.name = "Commands"
MODULE.author = "morgverd"
MODULE.description = "Register callbacks as chat/console commands."

GNIL.Commands = GNIL.Commands or {
    ["_r"] = {} -- The command registry. (THIS IS VERY DIFFERENT FROM SERVER TO CLIENT)
}

if SERVER then
    MODULE:Include("sh_const.lua")
end