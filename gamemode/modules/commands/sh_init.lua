local MODULE = MODULE

MODULE.name = "Commands"
MODULE.author = "morgverd"
MODULE.description = "Register callbacks as chat/console commands."

MODULE:Require("net") -- This module requires net messages.

GNIL.Commands = GNIL.Commands or {
    ["_r"] = {}, -- The command registry. (THIS IS VERY DIFFERENT FROM SERVER TO CLIENT)
    ["logo"] = string.Explode("\n", [[
        ______      __  _   ___ __   ____                 __                                 __ 
       / ____/___  / /_/ | / (_) /  / __ \___ _   _____  / /___  ____  ____ ___  ___  ____  / /_
      / / __/ __ \/ __/  |/ / / /  / / / / _ \ | / / _ \/ / __ \/ __ \/ __ `__ \/ _ \/ __ \/ __/
     / /_/ / /_/ / /_/ /|  / / /  / /_/ /  __/ |/ /  __/ / /_/ / /_/ / / / / / /  __/ / / / /_  
     \____/\____/\__/_/ |_/_/_/  /_____/\___/|___/\___/_/\____/ .___/_/ /_/ /_/\___/_/ /_/\__/  
                                                             /_/                                
   ]]),
   ["logo_color"] = Color(30, 194, 180),

   -- Shared function to print the logo in console. Used by both client and server.
   ["print_logo"] = function() 
        for _, v in ipairs(GNIL.Commands.logo) do
            MsgC(GNIL.Commands.logo_color, v .. "\n")
        end
    end
}

MODULE.OnLoad = function()

    -- Ensure that the constants are loaded before
    -- anything else since they're used a fair bit
    -- as references in other files. Also load arguments
    -- as it defines some shared functions.
    MODULE:Include("sh_const.lua")
    MODULE:Include("sh_arguments.lua")
end

if SERVER then
    MODULE.OnLoadFinished = function()
        MODULE:IncludeDirectory("commands")
    end
end