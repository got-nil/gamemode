# Got-Nil Gamemode

This is the core gamemode for our servers. The structure is relatively simple:

-  `gamemode/config` - Core configuration files.
-  `gamemode/core` - The core files used by the gamemode including utilities.
-  `gamemode/core/thirdparty` - All Thirdparty libaries used by the gamemode.
-  `gamemode/core/classes` - Core/Gamemode classes using the middleclass Thirdparty lib.
-  `gamemode/modules` - Gamemode modules.

**All files should start with a realm prefix, `sh_`/`cl_`/`sv_` with the exception of Module init files that may be simply `init.lua` (defaulting to the server realm).**

## Language server setup

The [lua-language-server](https://github.com/LuaLS/lua-language-server) allows for type analysis with the use of comment annotations. This can be used on any editor that supports Language Server Protocol (most), however this mini-guide is specifically for VisualStudio Code.

1. Install [lua-language-server](https://luals.github.io/#install) extension.
2. Install [glua-api-snippets](https://github.com/luttje/glua-api-snippets) by following the guide on their README. If you encounter some error popup when attempting to open the addon manager you should [install git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

Now the language server is installed, however there are some settings to change in Visual Studio Code for it to all play nice with GMod code. First start by opening the command palette with <kbd>F1</kbd> or <kbd>CTRL</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd>. Once open, search for "<code>Open User Settings (JSON)</code>" and hit enter.

Then add these settings (making sure to edit the `Lua.workspace.libary` path).
```json
"Lua.diagnostics.disable": [
	"undefined-global"
],
"Lua.runtime.special": {
	"include": "require",
	"IncludeCS": "require"
},
"Lua.runtime.nonstandardSymbol": [
	"continue",
	"&&",
	"||",
	"!=",
	"//"
],
"Lua.workspace.library": [
	"D:/Path/To/This/Gamemode"
],

```

With these settings loaded, you should now have full type support for the gamemode. You will also get access to gamemode classes and annotations outside of the gamemode workspace, so addon modules will still work.

### Using latest version

This gamemode uses new features from the language server that at the time of writing are not available in the default installed version.
In order to use these, you must:

1. Clone [lua-language-server](https://github.com/LuaLS/lua-language-server) master.
2. Build by running `make.bat` and allow it to run.
3. Open user settings and set `Lua.misc.executablePath` to the `bin/lua-language-server.exe` **absolute path**.
