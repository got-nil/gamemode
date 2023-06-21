GNIL.Modules = GNIL.Modules or {
    ["_loaded"] = {},
    ["_cached_modules"] = {},
    ["_tmp_dev_files"] = {},
    ["_first_loaded"] = {}
}

-- Clear all loaded modules each time theres a LUA refresh.
if GNIL._ENVIRONMENT == "dev" then
    GNIL.Modules["_loaded"] = {}
end

-- A helper function for the shared gamemode file to use when loading
-- all modules at once. It constantly checks to ensure that the module
-- isnt loaded incase of dependency loading.
function GNIL.Modules.LoadAll()
    GNIL.log("Loading all modules", "debug")
    for name, _ in pairs(GNIL.Modules.GetAll(true, true)) do
        if GNIL.Modules.IsLoaded(name) then
            GNIL.log("Module '" .. name .. "' is already loaded, ignoring autoload.", "debug")
            continue
        end
        GNIL.Modules.Load(name)
    end
    hook.Run("GNIL.Modules.LoadedAll")
end

-- Get all modules. If associative is true the return table is a key value
-- mapping {name = module}, if false the table is a sequential list of module instances.
-- If associative is false, just_names can be true which makes a sequential array of string names.
function GNIL.Modules.GetAll(associative, just_names)
    local modules = {}
    
    local _, directories = file.Find(GNIL.Utils.ResolveGamemodePath("modules/*"), "LUA")
    for i, name in ipairs(directories) do
        GNIL.log("Found module directory: " .. name, "debug")
        if name[1] == "_" then continue end
        modules[associative and name or i] = just_names and name or GNIL.Modules.Get(name)
    end
    return modules
end

-- Checks if a module name has been loaded. Does not preform any additional validation
-- such as exist checks since this function is called quite a lot.
function GNIL.Modules.IsLoaded(name) return GNIL.Modules._loaded[name] == true end

-- Load a module by its name.
--  name: The directory name of the module.
--  _dependency_chain: Internally used to prevent dependency recursion.
function GNIL.Modules.Load(name, _dependency_chain)
    if GNIL.Modules.IsLoaded(name) then GNIL.log("Refusing to load module '" .. name .. "' as it is already loaded.", "debug") return false end
    if not GNIL.Modules.Exists(name) then GNIL.log("Refusing to load module '" .. name .. "' as it does not exist.", "warning") return false end

    -- Find the module init file to allow it to setup other things.
    local initFilesOrder, initFile = {
        "init.lua",     -- sv_init alias
        "sv_init.lua",
        "sh_init.lua",
        "cl_init.lua"
    }, nil
    for _, v in ipairs(initFilesOrder) do
        if file.Exists(GNIL.Utils.ResolveGamemodePath("modules/" .. name .. "/" .. v), "LUA") then
            initFile = v
            break
        end
    end
    if not initFile then GNIL.log("Couldn't find suitable init file for module '" .. name .. "'", "warning")
    else GNIL.log("Found init file '" .. initFile .. "' for module '" .. name .. "'", "debug") end

    -- Once the init file has been found, we should load it individually.
    -- Ensuring that the dependency chain is passed through to the module.
    local moduleInstance = GNIL.Modules.Get(name, {
        ["_dependency_chain"] = _dependency_chain
    })

    -- Set the MODULE const for the module to access its local instance.
    local lastModule = _G["MODULE"] or nil
    _G["MODULE"] = moduleInstance

    -- Actually include the init file if the init file is suitable for the
    -- current execution realm (can be server or client).
    if initFile and GNIL.Utils.IsFilenameForCurrentRealm(initFile == "init.lua" and "sv_init.lua" or initFile) then

        moduleInstance:log("Loading init file '" .. initFile .. "'", "debug")
        GNIL.Utils.Include(GNIL.Utils.ResolveGamemodePath("modules/" .. name .. "/" .. initFile), initFile == "init.lua" and "sv_" or nil)

        -- Allow modules to be disabled, preventing loading.
        if moduleInstance._disabled then
            moduleInstance:log("Module is disabled.", "warning")
            return false
        end

        -- Call the module hook before anything.
        if moduleInstance:OnInit() == false then
            moduleInstance:log("Module refused to initialize.", "warning")
        end

        -- Allow for other utilities etc to process the init file output.
        if hook.Run("GNIL.Modules.Init", name, moduleInstance) == false then
            moduleInstance:log("Module load was prevented by init hook.", "debug")
            return false
        end
 
        -- Load all required module dependencies.
        if moduleInstance.dependencies then
            moduleInstance:log("Resolving dependencies.", "debug")
            for k, _ in pairs(moduleInstance.dependencies) do
                if moduleInstance._loaded_dependencies[k] then continue end
                moduleInstance:_ResolveRequirement(k)
            end
        end  
    else
        if initFile then moduleInstance:log("Init file '" .. initFile .. "' is not suitable for the current realm.", "debug")
        else moduleInstance:log("Init file could not be found, skipping.", "debug") end
    end

    -- Include the rest of the module directory without any of the init files.
    -- Also call OnLoad hook, allowing a final chance to reject a load.
    if moduleInstance:OnLoad() == false then
        moduleInstance:log("Module refused to load.", "warning")
        return false
    end

    -- Allow modules to disable autoloading. Allows init file to essentially "disable" modules.
    if moduleInstance.autoload then

        -- Get all of the directories that should be used when including all of the module.
        -- If there are defined autoload directories then convert them all to absolute paths
        -- to be included also.
        local directories = {GNIL.GamemodeBasePath .. "/modules/" .. name}
        if moduleInstance._added_delayed then
            for _, v in ipairs(table.GetKeys(moduleInstance._delayed_autoload[2])) do
                table.insert(directories, v)
            end
        end

        -- Load all of the directories that were gathered above. Ensure that
        -- the module init file is not included on the base directory as it will
        -- always be first. Ignore any files already included.
        local ignored_root_files, base_ignored_files = {"init.lua", "sv_init.lua", "sh_init.lua", "cl_init.lua"}, moduleInstance._ignored_files

        -- Remove any other restricted files (developer files + ignored files).
        -- Since this runs on the root it should only be ran once.
        local files, _ = file.Find(GNIL.GamemodeBasePath .. "/modules/" .. name .. "/*.lua", "LUA")
        for _, v in ipairs(files) do
            if v[1] == "_" or v[1] == "~" then
                local path = GNIL.GamemodeBasePath .. "/modules/" .. name .. "/" .. v
                base_ignored_files[path] = true

                -- If its a developer file (tilde prefix) then we should add the path
                -- to the temp developer files table (until the dev module is loaded).
                if v[1] == "~" then

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
    GNIL.Modules._loaded[name] = true

    -- Once everything has finished loading, we should call the OnLoadFinished hook function.
    hook.Run("GNIL.Modules.Loaded", name, moduleInstance)
    moduleInstance:OnLoadFinished()

    -- Call the FirstLoaded hook once per module load, even if the modules loaded have been
    -- cleared on refresh the hook should still be called at most once per server runtime.
    if not GNIL.Modules["_first_loaded"][name] then
        hook.Run("GNIL.Modules.FirstLoaded", name, moduleInstance)
        GNIL.Modules["_first_loaded"][name] = true
    end

    -- Once finished, restore the MODULE const to the previous, or nil.
    -- Allows other modules to load modules without losing their const.
    _G["MODULE"] = lastModule

    GNIL.log("Finished loading module '" .. name .. "'", "debug")
    return true
end

-- Unload a module, recursively unloading all its dependencies.
function GNIL.Modules.Unload(name, _caller)
    if not GNIL.Modules.IsLoaded(name) then return false end
    local moduleInstance = GNIL.Modules["_cached_modules"][name]

    -- Unload all modules that depend on the module being unloaded.
    if moduleInstance.dependencies != nil then
        for _, v in ipairs(moduleInstance.dependencies) do
            if v == _caller or v == name then continue end
            GNIL.Modules.Unload(v, name)
        end
    end
    hook.Run("GNIL.Modules.Unloaded", name, moduleInstance)

    -- Call the module unloader.
    moduleInstance:OnUnload()

    GNIL.log("The module '" .. name .. "' has been unloaded.", "debug")
    GNIL.Modules._loaded[name] = false
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

    -- https://github.com/Facepunch/garrysmod-issues/issues/1038
    -- On the client, this will return false since files added with AddCSLua doesn't
    -- satisfy IsDir as the file specifically was sent to the client. Because of this,
    -- if its a client we take a weird approach to validation.
    local rtrn = nil
    if SERVER then
        rtrn = file.IsDir(GNIL.GamemodeBasePath .. "/modules/" .. name, "LUA")
    else
        local _, directories = file.Find(GNIL.GamemodeBasePath .. "/modules/*", "LUA")
        for _, v in ipairs(directories) do
            if v == name then rtrn = true break end
        end
        if rtrn == nil then rtrn = false end
    end

    GNIL.Modules["_cached_existances"][name] = rtrn
    return rtrn
end

-- Get a module instance from cache, or create a new one. This ensures that
-- the same module instances are returned each time to persist class mutations.
function GNIL.Modules.Get(name, additional) -- ?Module
    if not GNIL.Modules["_cached_modules"][name] then 
        if not GNIL.Modules.Exists(name) then return nil end

        -- Create/Cache the module 
        GNIL.Modules["_cached_modules"][name] = GNIL.Classes.Module:New(name)
    end

    -- Apply additional data directly to the module instance.
    if additional != nil then
        for k, v in pairs(additional) do
            GNIL.Modules["_cached_modules"][name][k] = v
        end
    end

    return GNIL.Modules["_cached_modules"][name]
end

-- Remove hooks from module if it is being unloaded
hook.Add("GNIL.Modules.Unloaded", "gnil_module_unload_clearhooks", function(_, m) m:ClearHooks() end)
