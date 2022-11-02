
MODULE.name = "Commands"
MODULE.author = "morgverd"
MODULE.description = "Register callbacks as chat/console commands."

GNIL.Commands = GNIL.Commands or {
    ["_r"] = {} -- The command registry. (THIS IS VERY DIFFERENT FROM SERVER TO CLIENT)
}

-- Ensure that the constants are loaded before
-- anything else since they're used a fair bit
-- as references in other files. Also load arguments
-- as it defines some shared functions.
MODULE:Include("sh_const.lua")
MODULE:Include("sh_arguments.lua")

if SERVER then

    -- Once the module has finished loading all
    -- its required files, we should load the default
    -- command set.
    function MODULE:OnLoadFinished()
        self:IncludeDirectory("commands")
    end
end