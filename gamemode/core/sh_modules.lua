GNIL.Modules = GNIL.Modules or {
    ["_loaded"] = {},
    ["_cached_modules"] = {}
}

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

        -- Ensure that any dependencies that have not yet been resolved are resolved
        -- once the init file has finished. Essentially delayed module dependencies.
        if moduleInstance.dependencies then
            moduleInstance:log("Resolving delayed dependencies.", "debug")
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
    moduleInstance:OnLoad() -- Call the load function/hook.

    -- Get all of the directories that should be used when including all of the module.
    -- If there are defined autoload directories then convert them all to absolute paths
    -- to be included also.
    local directories = {GNIL.Utils.ResolveGamemodePath("modules/" .. name)}
    if moduleInstance._added_delayed then
        directories = table.Merge(directories, table.GetKeys(moduleInstance._delayed_autoload[2]))
    end

    -- Load all of the directories that were gathered above. Ensure that
    -- the module init file is not included on the base directory as it will
    -- always be first.
    local blocked_init_files = {"init.lua", "sv_init.lua", "sh_init.lua", "cl_init.lua"}
    for i, directory_path in ipairs(directories) do
        if i == 1 then moduleInstance:log("Loading module top level directory contents.", "debug") end
        GNIL.Utils.IncludeDirectory(directory_path, i == 1 and blocked_init_files or nil) -- Dont include base init file.
    end

    -- Finally include the rest of the delayed files.
    if moduleInstance._added_delayed then
        for path, _ in pairs(moduleInstance._delayed_autoload[1]) do
            GNIL.Utils.Include(path)
        end
    end
    GNIL.Modules._loaded[name] = true

    -- Once finished, restore the MODULE const to the previous, or nil.
    -- Allows other modules to load modules without losing their const.
    _G["MODULE"] = lastModule

    GNIL.log("Finished loading module '" .. name .. "'", "debug")
    return true
end

-- TODO
function GNIL.Modules.Unload(name)
    if not GNIL.Modules.IsLoaded(name) then return false end

    GNIL.Modules._loaded[name] = true
end

-- Check if a module exists. Will attempt to used cached existance check unless
-- the ignore_cache argument is true. Efficiency is a bitch.

GNIL.Modules["_cached_existances"] = {}
function GNIL.Modules.Exists(name, ignore_cache)
    

    -- https://github.com/Facepunch/garrysmod-issues/issues/1038
    -- On the client, this will return false since files added with AddCSLua doesn't
    -- satisfy IsDir as the file specifically was sent to the client. Because of this,
    -- if its a client we take a weird approach to validation.
    if SERVER then
        return file.IsDir(GNIL.GamemodeBasePath .. "/modules/" .. name, "LUA")
    else
        local _, directories = file.Find(GNIL.GamemodeBasePath .. "/modules/*", "LUA")
        for _, v in ipairs(directories) do
            if v == name then return true end
        end
        return false
    end
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
