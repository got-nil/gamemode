GNIL.Modules = GNIL.Modules or {}
local _defaults = {
    ["_loaded"] = {},
    ["_tmp_dev_files"] = {},
    ["_first_loaded"] = {},
    ["_cached_modules"] = {}
}
for k, v in pairs(_defaults) do
    if GNIL.Modules[k] == nil then
        GNIL.Modules[k] = v
    end
end

local function EmitModuleEvent(eventName, moduleInstance)
    return not (
        hook.Run("GNIL.Modules.Pre" .. eventName, tostring(moduleInstance), moduleInstance) == false or
        moduleInstance:EmitEvent(eventName, moduleInstance) == false or
        hook.Run("GNIL.Modules." .. eventName, tostring(moduleInstance), moduleInstance) == false
    )
end

local function CreateAndCacheModule(name, base_path)
    local moduleInstance = GNIL.Classes.Module:New(name, base_path)
    GNIL.Modules["_cached_modules"][name] = moduleInstance
    return moduleInstance
end


local function GetOrCreateModule(name, base_path)
    local out = GNIL.Modules["_cached_modules"][name]
    if out == nil then
        out = CreateAndCacheModule(name, base_path)
    end
    return out
end


local function IsModule(v)
    return istable(v) and IsInstanceOf(v, GNIL.Classes.Module)
end

------------------------------------------------------------------------------------------------------------

local function InitializeModule(moduleInstance, reload, _returnLastModuleFn)

    local initFiles, basePath = {}, moduleInstance:GetBasePath()
    if basePath then

        -- Find valid init files for the module. There can now be multiple
        -- init files for a single module to split initialization across realms.
        local realmInits = {
            [1] = {"init.lua", "sv_init.lua", "sh_init.lua"},
            [2] = {"cl_init.lua", "sh_init.lua"}
        }
        local iRealm = Either(SERVER, 1, 2)
        for i, files in ipairs(realmInits) do
            for _, v in pairs(files) do
                local filepath = basePath .. "/" .. v
                if not file.Exists(filepath, "LUA") then continue end               -- Ignore non-existant files.
                if i == iRealm then table.insert(initFiles, v) end                  -- If its correct realm, add it as initFile.
                if SERVER and i == 2 then GNIL.Utils.Include(filepath, "cl_") end   -- If its client only, add CSLuaFile.
            end
        end
    else
        moduleInstance:log("Module base_path is not set, cannot find any init files.", "debug")
    end

    -- Log the init file directly to moduleInstance instead of globally.
    if #initFiles == 0 then moduleInstance:log("Couldn't find suitable realm init file for module.", "warning")
    else moduleInstance:log("Found init file(s): " ..  table.concat(initFiles, ", "), "debug") end

    -- If we're reloading, check if the module if the module has already
    -- been initialized. If it has, unload the module without unloading
    -- dependencies (since we're not really unloading it). Also send
    --- the 'Reinitialize' signal for listeners.
    if reload and moduleInstance._initialized then

        moduleInstance:log("Reloading module as its already been initialized.", "debug")
        GNIL.Modules.Unload(moduleInstance, nil, true)
    end

    -- Set the MODULE const for the module to access its local instance.
    local lastModule = _G["MODULE"] or nil
    _G["MODULE"] = moduleInstance

    -- Restore the previous MODULE value. Can be called externally.
    -- The env should only be closed on local exit if the callback isn't
    -- being returned (keep open if callback is requested).
    local _hasRestored = false
    local _restoreModuleFn = function()

        -- Prevent the restoreModuleFn from being called twice.
        -- Although this shouldn't happen anyway, it does allow the
        -- function to always be called safely (even if its already closed).
        if _hasRestored then return false end
        _hasRestored = true

        _G["MODULE"] = lastModule
        return true
    end
    local restoreModuleFn = function()
        if _returnLastModuleFn then return end
        _restoreModuleFn()
    end

    -- Actually include the init file if the init file is suitable for the
    -- current execution realm (can be server or client).
    if #initFiles > 0 then

        -- Include all the init files for the module (since there can be multiple).
        for _, initFile in ipairs(initFiles) do
            moduleInstance:log("Loading init file '" .. initFile .. "'", "debug")
            GNIL.Utils.Include(basePath .. "/" .. initFile)
        end
    end

    -- Allow modules to be disabled, preventing loading.
    if moduleInstance._disabled then
        moduleInstance:log("Module is disabled.", "warning")
        restoreModuleFn()
        return false, nil, nil
    end

    -- Allow the module load to be stopped in Init, before dependencies.
    if not EmitModuleEvent("Init", moduleInstance) then
        moduleInstance:log("Module init was prevented by init.", "debug")
        restoreModuleFn()
        return false, nil, nil
    end

    -- Load all required module dependencies.
    if moduleInstance.dependencies then
        moduleInstance:log("Resolving dependencies.", "debug")
        for k, _ in pairs(moduleInstance.dependencies) do
            if moduleInstance._loaded_dependencies[k] then continue end
            moduleInstance:_ResolveRequirement(k)
        end
    end

    -- Initialize after dependencies hook.
    if hook.Run("GNIL.Modules.InitAfterDependencies", name, moduleInstance) == false then
        moduleInstance:log("Module init was prevented by hook after dependencies were loaded.", "debug")
        restoreModuleFn()
        return false, nil, nil
    end

    -- GNIL.Modules.Load delays the MODULE from being reset until the end. Instead the resetter
    -- callable should be returned so the env closing can be handled when needed.
    if _returnLastModuleFn then
        return true, moduleInstance, _restoreModuleFn
    else

        -- Restore the MODULE const to last module to handle loading inside another module.
        restoreModuleFn()
        return true, moduleInstance, nil
    end
end

-- value: Module | string
-- base_path: nil | string
local function LoadModule(value, base_path, _reload, _dependency_chain)

    -- Just incase.
    assert(base_path == nil or isstring(base_path), "The module base_path argument must be nil or a string")
    local moduleInstance = false

    if not IsModule(value) then
        assert(isstring(value), "Provided name must be a string if not a Module")

        -- Get the cached module from name if there is one, or create
        -- a new module and cache it.
        local moduleInstance = GNIL.Modules.Get(value, {
            _base_path = base_path
        })
        if not moduleInstance then
            moduleInstance = CreateAndCacheModule(value, base_path)
        end
    else

        -- Allow a module instance to be directly loaded instead of a name.
        moduleInstance = value
    end

    -- If there is a dependency chain, apply it to the module.
    if _dependency_chain then
        moduleInstance._dependency_chain = _dependency_chain
    end

    -- Initialize the module to get the moduleInstance ready to be loaded.
    -- The MODULE const is kept as the loading module until the end.
    local initialized, moduleInstance, restoreModuleFn = InitializeModule(moduleInstance, _reload, true)
    if not initialized then return false end

    -- Include the rest of the module directory without any of the init files.
    -- Also call OnLoad hook, allowing a final chance to reject a load.
    if not EmitModuleEvent("Load", moduleInstance) then
        moduleInstance:log("Module refused to load.", "warning")
        restoreModuleFn()
        return false
    end

    -- Only do the file load cycle if there is a base_path provided.
    local moduleBasePath = moduleInstance._base_path
    if moduleBasePath then

        -- Allow modules to disable autoloading. Allows init file to essentially "disable" modules.
        if moduleInstance.autoload then
            moduleInstance:log("Starting top level autoload cycle.", "debug")

            -- Get all of the directories that should be used when including all of the module.
            -- If there are defined autoload directories then convert them all to absolute paths
            -- to be included also.
            local directories = {moduleBasePath}
            if moduleInstance._added_delayed then
                for _, v in ipairs(table.GetKeys(moduleInstance._delayed_autoload[2])) do
                    table.insert(directories, v)
                end
            end

            -- Load all of the directories that were gathered above. Ensure that
            -- the module init file is not included on the base directory as it will
            -- always be first. Ignore any files already included.
            local ignored_root_files, base_ignored_files = {"init.lua", "sv_init.lua", "sh_init.lua", "cl_init.lua", "config.lua"}, moduleInstance._ignored_files

            -- Remove any other restricted files (developer files + ignored files).
            -- Since this runs on the root it should only be ran once.
            local files, _ = file.Find(moduleBasePath .. "/*.lua", "LUA")
            for _, v in ipairs(files) do
                local l = v[1]
                if l == "_" or l == "~" then
                    local path = moduleBasePath .. "/" .. v
                    base_ignored_files[path] = true

                    -- If its a developer file (tilde prefix) then we should add the path
                    -- to the temp developer files table (until the dev module is loaded).
                    if l == "~" then

                        -- If the developer module is loaded, just call the add dev file directly
                        -- if its not yet loaded, then store it temporarily until its loaded.
                        moduleInstance:log("Adding developer only file '" .. v .. "'", "debug")
                        if GNIL.Modules.IsLoaded("dev") then
                            GNIL.Dev.AddDeveloperOnlyFile(path)
                        else
                            moduleInstance:log("Developer module is not yet loaded, storing dev file in temp until loaded.", "debug")
                            table.insert(GNIL.Modules["_tmp_dev_files"], path)
                        end
                    end
                end
            end

            -- Add any already included files and add to ignored root files.
            for i, directory_path in ipairs(directories) do

                -- Ensure that the ignored files table is persisted while loading the
                -- top level directory and any other requested directories by the init.
                -- On the root level, also ignore anything that looks like an init file.
                local ignored_files = {}
                for k, _ in pairs(base_ignored_files) do
                    ignored_files[k] = true
                end
                if i == 1 then
                    moduleInstance:log("Loading module top level directory contents.", "debug")
                    for _, v in ipairs(ignored_root_files) do
                        ignored_files[directories[i] .. "/" .. v] = true
                    end
                end

                -- Load the directory removing ignored files.
                GNIL.Utils.IncludeDirectory(directory_path, ignored_files, true)
            end
        else
            moduleInstance:log("Default autoload disabled.", "debug")
        end

        -- Finally include the rest of the delayed files.
        if moduleInstance._added_delayed then
            for path, _ in pairs(moduleInstance._delayed_autoload[1]) do
                GNIL.Utils.Include(path)
            end
        end
    else
        moduleInstance:log("Skipping module file load cycle as there is no base_path set.", "debug")
    end

    local name = moduleInstance._module_name
    GNIL.Modules._loaded[name] = true

    -- Once everything has finished loading, we should call the OnLoadFinished hook function.
    hook.Run("GNIL.Modules.Loaded", name, moduleInstance)
    moduleInstance:EmitSignal("LoadFinished", moduleInstance)

    -- Call the FirstLoaded hook once per module load, even if the modules loaded have been
    -- cleared on refresh the hook should still be called at most once per server runtime.
    if not GNIL.Modules["_first_loaded"][name] then
        hook.Run("GNIL.Modules.FirstLoaded", name, moduleInstance)
        GNIL.Modules["_first_loaded"][name] = true
    end

    -- Restore the MODULE global to the last module.
    moduleInstance:log("Finished loading!", "debug")
    restoreModuleFn()
    return true
end

------------------------------------------------------------------------------------------------------------

-- Should only really be used for testing.
function GNIL.Modules._InitializeModule(...)
    return InitializeModule(...)
end

-- moduleinstance_or_string: string | Module
-- base_path: nil | string
function GNIL.Modules.Load(moduleinstance_or_string, base_path, _dependency_chain)
    local moduleInstance = moduleinstance_or_string
    if isstring(moduleinstance_or_string) then
        moduleInstance = GetOrCreateModule(moduleinstance_or_string, base_path)
    end
    assert(IsInstanceOf(moduleInstance, GNIL.Classes.Module), "A moduleInstance or string must be provided.")

    -- Do not attempt to load a module that has already been loaded.
    if GNIL.Modules._loaded[moduleInstance._module_name] then
        moduleInstance:log("Not attempting module load as its already been loaded!", "warning")
        return true
    end

    return LoadModule(moduleInstance, base_path, false, _dependency_chain)
end

-- A helper function for the shared gamemode file to use when loading
-- all modules at once. It constantly checks to ensure that the module
-- isnt loaded incase of dependency loading.
function GNIL.Modules.LoadAll(_reload)
    GNIL.log("Loading all modules", "debug")
    for _, v in ipairs(GNIL.Modules.FindAll()) do
        if GNIL.Modules._loaded[v._module_name] then
            v:log("Skipping Load call in LoadAll, as the module has already been loaded probably as a dependency.", "debug")
            continue
        end
        LoadModule(v, nil, _reload)
    end
    hook.Run("GNIL.Modules.LoadedAll")
end

-- Return all cached modules.
function GNIL.Modules.GetAll(associative, just_names, ignore_disabled)
    local modules = {}

    for k, v in pairs(GNIL.Modules["_cached_modules"]) do
        if not ignore_disabled and v._disabled then continue end
        modules[associative and k or (#modules + 1)] = just_names and k or v
    end
    return modules
end

-- Find all modules. If associative is true the return table is a key value
-- mapping {name = module}, if false the table is a sequential list of module instances.
-- If associative is false, just_names can be true which makes a sequential array of string names.
function GNIL.Modules.FindAll(associative, just_names)
    local modules = {}

    -- Check both the gamemode modules directory and base lua path so addons can also add modules.
    for _, base_path in ipairs({GNIL.Utils.ResolveGamemodePath("modules"), "gnil-modules"}) do
        local _, directories = file.Find(base_path .. "/*", "LUA")
        for _, name in ipairs(directories) do
            if name[1] == "_" then continue end

            -- TODO: Prevent addon module from overwriting gamemode.
            local v = nil
            if just_names then
                v = name
            else

                -- Get the module from cache, or create a new one with
                -- the current base_path and name (and cache it).
                local moduleInstance = GNIL.Modules.Get(name)
                if not moduleInstance then
                    moduleInstance = CreateAndCacheModule(name, base_path .. "/" .. name)
                end
                v = moduleInstance
            end
            if not v then continue end
            modules[associative and name or (#modules + 1)] = v
        end
    end
    return modules
end

-- Checks if a module name has been loaded. Does not preform any additional validation
-- such as exist checks since this function is called quite a lot.
-- Also makes sure that the module is actually cached.
function GNIL.Modules.IsLoaded(name) return GNIL.Modules._loaded[name] == true and GNIL.Modules._cached_modules[name] != nil end
function GNIL.Modules.Reload(name)
    if not GNIL.Modules.IsLoaded(name) then
        return false
    end
    local moduleInstance = GNIL.Modules["_cached_modules"][name]
    hook.Run("GNIL.Modules.Reload", name, moduleInstance)
    return LoadModule(moduleInstance, nil, true)
end

-- Get a module instance from cache. Module must be loaded beforehand.
function GNIL.Modules.Get(name, additional) -- ?Module
    if not GNIL.Modules["_cached_modules"][name] then
        return nil
    end

    -- Apply additional data directly to the module instance.
    if additional != nil then
        for k, v in pairs(additional) do
            GNIL.Modules["_cached_modules"][name][k] = v
        end
    end

    return GNIL.Modules["_cached_modules"][name]
end

-- Unload a module, recursively unloading all its dependencies.
-- If _reload is specified, some unload steps are ignored (BOOL).
function GNIL.Modules.Unload(name_or_module, _caller, _reload)

    -- Allow a module to be provided directly instead of name.
    local moduleInstance, name = false, false
    if IsModule(name_or_module) then
        moduleInstance, name = name_or_module, name_or_module._module_name
    else
        if not GNIL.Modules.IsLoaded(name_or_module) then return false end
        moduleInstance, name = GNIL.Modules["_cached_modules"][name_or_module], name_or_module
    end

    -- Unload all modules that depend on the module being unloaded.
    if not _reload and moduleInstance.dependencies then
        for _, v in ipairs(moduleInstance.dependencies) do
            if v == _caller or v == name then continue end
            GNIL.Modules.Unload(v, name)
        end
    end
    hook.Run("GNIL.Modules.Unloaded", name, moduleInstance)

    -- Call the module unloader and cleanup the module.
    moduleInstance:EmitSignal("Unload", moduleInstance, _reload == true)
    moduleInstance:_Cleanup()

    moduleInstance:log("Module has been unloaded!", "debug")
    GNIL.Modules._loaded[name] = false
    return true
end

-- Check if a module exists. Will attempt to used cached existance check unless
-- the ignore_cache argument is true. Efficiency is a bitch.
GNIL.Modules["_cached_existances"] = {}
function GNIL.Modules.Exists(name, ignore_cache)

    -- If we're not ignoring the cache, and there is a cached existance value for
    -- the module name then we should use that instead of re-checking.
    if not ignore_cache and GNIL.Modules["_cached_existances"][name] then
        return GNIL.Modules["_cached_existances"][name]
    end
    if GNIL.Modules["_cached_modules"][name] then
        return true
    end

    -- TODO: Support addons too.
    local exists = GNIL.Utils.DirectoryExists(GNIL.GamemodeBasePath .. "/modules/" .. name, "LUA")
    GNIL.Modules["_cached_existances"][name] = exists
    return exists
end