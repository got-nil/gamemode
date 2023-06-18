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

------------------------ HEADER ------------------------

MODULE.name = "Example Module" -- [REQUIRED] A simple and short module name.
MODULE.author = "morgverd" -- [REQUIRED] The author of the module. This is used for error logs so ALWAYS put your real username to make it easier.
MODULE.description = "This module is never actually loaded, and does nothing." -- [REQUIRED] A brief description of the module and what it does.
MODULE.config = "example" -- [OPTIONAL] The name of a required configuration file.

------------------------ GENERAL ------------------------

-- When logging something from the module, you can use the log builtin to the module. This
-- will automatically add the current module name to the log prefix to make debugging easier.
MODULE:log("Woah look at this", "debug")

-- Allows for a module to be disabled in its init file. This prevents the autoload from continuing
-- and should be used only when a module is unable to function (missing dependencies etc).
MODULE:SetDisabled(false)

-- Returns a Config object for the module if the 'MODULE.config' attribute is set, or nil.
MODULE:Config()

-- Once the init file has been executed, the default MODULE behaviour is to autoload all correctly
-- prefixed files in the module base directory. If you want the init file to directly handle all
-- file includes via its own loaders, disable the rest of the module entirely, etc then the autoload
-- can be disabled using the function below.
MODULE:SetAutoload(false) -- Disabled, after this file no other files will be loaded unless from this file.

-- Ignore allows for specific files (including files that are nested within other directories)
-- to remain unloaded. These files are completely skipped when loading directories, and are therefore
-- useful for files that should only be loaded in certain environments, etc. This ignore list
-- persists for subsequent Include calls on the module. 
MODULE:Ignore("relative_file.lua")
MODULE:Ignore("nested/relative_file.lua")

-- "Require" is used to signify that this module requires another module to function. When
-- requiring a module its init file is loaded and executed, along with all top level module
-- files. Essentially its loading the module with some added protection to prevent loops.
MODULE:Require("OtherModule")

-- Iterative over the require function above.
MODULE:Requires({"ModuleTwo", "ModuleThree"})

-- Get all module dependencies (requirements).
-- Returns a sequential table of required module names.
MODULE:GetDependencies()

-- Load a directory in base, calling each file with handler.
-- handler: 'core/loadears' 
MODULE:LoadDirectory(base, directory, handler)

-- This is used for loading 'entities' directories etc.
-- A directory that contains other files/directories that
-- should be loaded with the given handler (see above).
MODULE:LoadDirectories(directory, handler)

-- ** BY NEW DESIGN (MODULE FILE IGNORING) YOU SHOULD ALWAYS USE THE MODULE VERSIONS OF
-- INCLUDE AND INCLUDEDIRECTORY OVER ITS GLOBAL. THE MODULE VERSION WILL HANDLE THE IGNORED
-- FILES FOR YOU, BUT USING THE GLOBAL UTILITY WILL NOT. ** 

-- If your module needs to load other directories, the module class provides a simple interface
-- for including relative directories without having to resolve it yourself. The second argument
-- allows the include to be "delayed" until the init file has finished executing (once the other
-- top level files are loaded). **Even if there are no ignored files provided, any files ignored
-- using the Ignore class method will be ignored by default, this cannot be disabled.
MODULE:IncludeDirectory("other_shit")       -- Will include the directory immidiately.
MODULE:IncludeDirectory("other_shit", true) -- Will include the directory when the root directory files are being loaded.
MODULE:Include(path, ignoredFiles, delayed) -- The same functionality as IncludeDirectory with the last argument being the delayed flag.

------------------------- FILES -------------------------

-- file.Find in LUA path relative to module base.
MODULE:Find(path, sorting)

-- Resolves a relative filepath to an absolute LUA path.
-- Out: "gnil/gamemode/modules/example/nestedDirectory/sh_whatever.lua"
MODULE:ResolvePath("nestedDirectory/sh_whatever.lua")

------------------------- HOOKS ---------------------------

-- Hooks can be given identifiers allowing them to be specifically removed,
-- alternatively no identifier can be provided giving it a sequentially generated
-- hook name. It can then be cleared using ClearHooks() if needed.

MODULE:AddHook("Think", function() ... end) -- Anonymous hook
MODULE:AddHook("Think", "identifier", function() ... end) -- Named hook

MODULE:RemoveHook("Think", "identifier") -- Remove a named hook.
MODULE:ClearHooks() -- Clear all hooks within module.
MODULE:GetHooks() -- Returns hook table similar to hook.GetTable

----------------------- FUNCTIONS -------------------------

function MODULE:OnLoad() self:log("The module load has started!") end
function MODULE:OnUnload() self:log("The module is being unloaded!") end
function MODULE:OnLoadFinished() self:log("The module has finished loading!") end