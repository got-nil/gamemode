# Got-Nil Gamemode

This is the core gamemode for our servers. The structure is relatively simple:
 - `gamemode/config` - Core configuration files.
 - `gamemode/core` - The core files used by the gamemode including utilities.
 - `gamemode/core/thirdparty` - All Thirdparty libaries used by the gamemode.
 - `gamemode/core/classes` - Core/Gamemode classes using the middleclass Thirdparty lib.
 - `gamemode/modules` - Gamemode modules.
 
 **All files should start with a realm prefix, `sh_`/`cl_`/`sv_` with the exception of Module init files that may be simply `init.lua` (defaulting to the server realm).**
