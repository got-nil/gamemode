if GNIL.ENV.LOADER_RESET then GNIL.Loader = false end
GNIL.Loader = GNIL.Loader or {
    ["_init"] = false,
    ["_loaders"] = {}
}

-- Additional used loaders. (core/loaders/...)
local additionalLoaders = {
    "entity"
}

-- PHP function, but in LUA. Mad world we live in.
local function ucfirst(str)
    return str:sub(1,1):upper()..str:sub(2)
end

---Wrap a function to be called in between a const
---being set. After completion, the previous value
---is restored.
---@param const string
---@param const_default any
---@param fn function
---@return any
function GNIL.Loader.ConstWrap(const, const_default, fn)
    local previous = _G[const]
    _G[const] = const_default or {}
    local fn_out, out = fn(), _G[const]
    _G[const] = previous

    -- Always prefer inner output over global.
    if fn_out != nil then return fn_out end
    return out
end

---Loads directory files wrapped as a const. The
---return value is the modified const_default or nil.
---@param const string
---@param directory_path string
---@param const_default? any
---@return any
function GNIL.Loader.DirectoryConst(const, directory_path, const_default)
    return GNIL.Loader.ConstWrap(const, const_default or {}, function()

        -- Load all files within the directory, ignoring files unsuitable
        -- for the current realm.
        local any_loaded = false
        local _, files = file.Find(directory_path .. "/*.lua", "LUA")
        for _, v in ipairs(files) do

            GNIL.Utils.Include(v)
            if not GNIL.Utils.IsFilenameForCurrentRealm(filepath) then
                continue
            end
            any_loaded = true
        end

        -- If nothing was loaded, then theres no modification to default.
        if not any_loaded then
            return false
        end
    end)
end

---Get the loader table from name.
---@return table
function GNIL.Loader.GetLoaders()
    return GNIL.Loader["_loaders"]
end

---Get a loader by name.
---@param name string
---@return table?
function GNIL.Loader.GetLoader(name)
    return GNIL.Loader["_loaders"][name]
end

--[[

    Load a directory of files into a table. Each key will be the
    filename without extension (uppercase first if argument set).
    The value is the return value of the file. (could be nil!)

    sh_pet.lua -> A
    sh_dog.lua -> B

    ={
        pet = A,
        dog = B
    }

--]]
---@param directory_path string
---@param key_uppercase_first? boolean
---@param force_realm? string
---@return table?
function GNIL.Loader.DirectoryFilenameMap(directory_path, key_uppercase_first, force_realm)

    -- Map file return values to cleaned filename.
    local out = {}

    -- Allow files to be overridden.
    local files, _ = file.Find(directory_path .. "/*.lua", "LUA")
    if files == nil then return nil end
    for _, f in ipairs(files) do

        local name = GNIL.Utils.GetCleanFilename(f, extension or "lua")
        local rtrn = GNIL.Utils.Include(directory_path .. "/" .. f, force_realm)
        if not force_realm and not GNIL.Utils.IsFilenameForCurrentRealm(f) then
            continue
        end
        if rtrn != nil then
            out[key_uppercase_first && ucfirst(name) || name] = rtrn
        end
    end
    return out
end

--[[

    Load a directory of files, each returning a table of names to
    values (these can be classes or whatever). Instead of the name
    coming from the filename, it is instead from the table key value.

    ** EACH RETURN VALUE MUST BE NIL OR TABLE **

    sh_whatever1.lua -> { Pet = A }
    sh_whatever2.lua -> { Dog = B }

    ={
        Pet = A,
        Dog = B
    }

--]]
---@param directory_path string
---@param callback? function
---@param force_realm? string
---@return table?
function GNIL.Loader.DirectoryMap(directory_path, callback, force_realm)
    assert(callback == nil or isfunction(callback), "If a callback is provided, it must be a function.")

    local out = {}

    local files, _ = file.Find(directory_path .. "/*." .. (extension or "lua"), "LUA")
    if files == nil then return nil end
    for _, f in ipairs(files) do

        -- Include all files regardless of realm to make sure its being loaded on client too.
        local rtrn = GNIL.Utils.Include(directory_path .. "/" .. f, force_realm)
        if rtrn == nil then continue end
        if not force_realm and not GNIL.Utils.IsFilenameForCurrentRealm(f) then
            continue
        end
        assert(istable(rtrn), "File '" .. f .. "' must return nil or a table")

        for k, v in pairs(rtrn) do
            out[k] = v

            -- If there is a callback, run it. This allows for the class to
            -- be stored in a global table to be used in the next (where needed).
            -- Basically any case where you can't wait till the end to get the values.
            if callback then callback(k, v, f) end
        end
    end
    return out
end

-- Load the additional load handlers.
local function loadLoaders()
    local basePath, out = GNIL.Utils.ResolveGamemodePath("core/loaders"), {}
    for _, v in ipairs(additionalLoaders) do
        out[v] = GNIL.Utils.Include(basePath .. "/" .. v .. ".lua", "sh_")
    end
    return out
end

---Prevent reloading on luarefresh (although for dev
---environment everything is always reloaded).
function GNIL.Loader.LoadBase()
    if GNIL.Loader["_init"] then return end
    GNIL.log("Starting to load Thirdparty, Classes and other loaders.", "debug")

    -- Load the other loaders (entity, material).
    GNIL.Loader["_loaders"] = loadLoaders()
    for k, _ in pairs(GNIL.Loader["_loaders"]) do GNIL.log("Registered loader handler '" .. k .. "'.", "debug") end

    -- Load thirdparty and classes directories.
    GNIL.Integrations   = GNIL.Loader.DirectoryFilenameMap(GNIL.Utils.ResolveGamemodePath("core/integrations"))
    GNIL.Thirdparty     = GNIL.Loader.DirectoryFilenameMap(GNIL.Utils.ResolveGamemodePath("core/thirdparty"))
    GNIL.ClassMixins    = GNIL.Loader.DirectoryFilenameMap(GNIL.Utils.ResolveGamemodePath("core/classes/mixins"), true)
    GNIL.Classes        = GNIL.Loader.DirectoryFilenameMap(GNIL.Utils.ResolveGamemodePath("core/classes"), true)

    -- Prevent this function from being called again.
    GNIL.Utils.IncludeDirectory(GNIL.Utils.ResolveGamemodePath("core/module"))
    GNIL.Loader["_init"] = true
end