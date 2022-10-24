GNIL.Modules = {
    ["_loaded"] = {}
}

local cachedModules = {}

function GNIL.Modules.GetAll(associative)
    local modules = {}
    
    local _, directories = file.Find(GNIL.Utils.ResolveGamemodePath("modules/*"), "LUA")
    for i, name in ipairs(directories) do
        modules[associative and name or i] = GNIL.Modules.Get(name)
    end
    return modules
end

function GNIL.Modules.IsLoaded(name) return GNIL.Modules._loaded[name] == true end

function GNIL.Modules.Load(name, _dependency_chain)
    if GNIL.Modules.IsLoaded(name) then GNIL.log("Refusing to load module '" .. name .. "' as it is already loaded.", "debug") return false end
    if not GNIL.Modules.Exists(name) then GNIL.log("Refusing to load module '" .. name .. "' as it does not exist.", "warning") return false end

    -- Find the module init file to allow it to setup other things.
    local initFilesOrder, initFile = {
        "init.lua",
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
    if not initFile then GNIL.log("Couldn't find suitable init file for module '" .. name .. "'", "error") return false
    else GNIL.log("Found suitable init file '" .. initFile .. "' for module '" .. name .. "'", "debug") end

    -- Once the init file has been found, we should load it individually.
    -- To do so, we must setup the basic module const for the init file to use.
    local moduleInstance = GNIL.Modules.Get(name)
    _G["MODULE"] = moduleInstance
    GNIL.Utils.Include(GNIL.Utils.ResolveGamemodePath("modules/" .. name .. "/" .. initFile), initFile == "init.lua" and "sv_" or nil)

    -- Once the init file has been loaded, if there are dependencies defined we
    -- should attempt to resolve them before loading the rest of the module.
    if moduleInstance.dependencies != nil then
        local chain = _dependency_chain != nil and _dependency_chain or {}
        for _, dependency in ipairs(moduleInstance.dependencies) do

            -- If the dependency is already in the _dependency_chain table then
            -- we know theres dependency recursion going on here.
            if chain[dependency] then
                GNIL.log("Experienced dependency recursion while loading module '" .. name .. "' (dependency '" .. dependency .. "')", "warning")
                continue
            end

            GNIL.log("Loading dependency '" .. dependency .. "' from module '" .. name .. "'", "debug")
            chain[dependency] = true
            GNIL.Modules.Load(dependency, chain)
        end
    else
        GNIL.log("Module '" .. name .. "' did not specify any dependencies.", "debug")
    end

    -- Include the rest of the module directory without any of the init files.
    moduleInstance:OnLoad() -- Call the load function/hook.
    GNIL.Utils.IncludeDirectory(GNIL.Utils.ResolveGamemodePath("modules/" .. name), {"init.lua", "sv_init.lua", "sh_init.lua", "cl_init.lua"})
    GNIL.Modules._loaded[name] = true

    return true
end

-- TODO
function GNIL.Modules.Unload(name)
    if not GNIL.Modules.IsLoaded(name) then return false end

    GNIL.Modules._loaded[name] = true
end

function GNIL.Modules.Exists(name)
    return file.IsDir(GNIL.GamemodeBasePath .. "/modules/" .. name, "LUA")
end

function GNIL.Modules.Get(name, additional) -- ?Module
    if not cachedModules[name] then 
        if not GNIL.Modules.Exists(name) then return nil end

        -- Create/Cache the module 
        cachedModules[name] = GNIL.Classes.Module:New(name)
    end

    -- Apply additional data directly to the module instance.
    if additional != nil then
        for k, v in pairs(additional) do
            createdModules[name][k] = v
        end
    end

    return cachedModules[name]
end
