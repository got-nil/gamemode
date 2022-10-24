/*

    (This example module starts with an underscore. This skips the module when
    getting all modules via GNIL.Modules.GetAll as it is treated inoperable)

    This is the module init file, which is always called before any other
    files within the module. All modules MUST define some form of init file,
    however it can be in any realm.

    This init file doesn't have a realm prefix, which is just an alias for "sv_init"
    (This is the only time where you can have files in the core without a realm prefix).
    The following init files are also supported:
        - sv_init/init.lua: The module is server only.
        - sh_init.lua: The module is intended for both client and server.
        - cl_init.lua: The module is clientside only.
        
*/

-- You don't have to do this, but you should and not doing it will make us all laugh at you
-- for not doing it. All it does is creates a local reference to the current MODULE global.
local MODULE = MODULE

MODULE.name = "Example Module" -- A simple and short module name.
MODULE.author = "morgverd" -- The author of the module. This is used for error logs so ALWAYS put your real username to make it easier.
MODULE.description = "This module is never actually loaded, and does nothing." -- A brief description of the module and what it does.

-- When logging something from the module, you can use the log builtin to the module. This
-- will automatically add the current module name to the log prefix to make debugging easier.
MODULE:log("Woah look at this", "debug")

-- "Require" is used to signify that this module requires another module to function. When
-- requiring a module its init file is loaded and executed, along with all top level module
-- files. Essentially its loading the module with some added protection to prevent loops.
MODULE:Require("OtherModule")

-- Iterative over the require function above.
MODULE:Requires({"ModuleTwo", "ModuleThree"})

-- If your module needs to load other directories, the module class provides a simple interface
-- for including relative directories without having to resolve it yourself. The second argument
-- allows the include to be "delayed" until the init file has finished executing (once the other
-- top level files are loaded).
MODULE:IncludeDirectory("other_shit")       -- Will include the directory immidiately.
MODULE:IncludeDirectory("other_shit", true) -- Will include the directory when the root directory files are being loaded.
MODULE:Include(path, ignoredFiles, delayed) -- The same functionality as IncludeDirectory with the last argument being the delayed flag.

-- The module class also exposes two functional hooks that can be used when loading and unloading
-- the current module. This allows for connections (etc) to be established/destroyed appropriately.
function MODULE:OnLoad() self:log("Look we're being called!") end
function MODULE:OnUnload() self:log("We could clean up connections etc here!") end