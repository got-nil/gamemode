if GNIL._ENVIRONMENT == "dev" then GNIL.Loader = false end
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

-- Wrap a function to be called in between a const
-- being set. After completion, the previous value
-- is restored.
function GNIL.Loader.ConstWrap(const, fn)
    local previous = _G[const]
    _G[const] = const_default or {}
    local fn_out, out = fn(), _G[const]
    _G[const] = previous

    -- Always prefer inner output over global.
    if fn_out != nil then return fn_out end
    return out
end

-- Load directory files wrapped as a const. The
-- return value is the modified const_default or nil.
function GNIL.Loader.DirectoryConst(const, directory_path, const_default)
    return GNIL.Loader.ConstWrap(const, function()

        -- Load all files within the directory, ignoring files unsuitable
        -- for the current realm.
        local any_loaded = false
        local _, files = file.Find(directory_path .. "/*.lua", "LUA")
        for _, v in ipairs(files) do
            if not GNIL.Utils.IsFilenameForCurrentRealm(filepath) then
                continue
            end
            
            any_loaded = true
            GNIL.Utils.Include(v)
        end

        -- If nothing was loaded, then theres no modification to default.
        if not any_loaded then
            return false
        end
    end)
end

-- Get the loader table from name.
function GNIL.Loader.GetLoaders() return GNIL.Loader["_loaders"] end
function GNIL.Loader.GetLoader(name)
    return GNIL.Loader["_loaders"][name]
end

-- Load a directory of files into a table. Each key will be the 
-- filename without extension (uppercase first if argument set).
-- The value is the return value of the file. (could be nil!)
function GNIL.Loader.DirectoryMap(directory_path, key_uppercase_first, extension, force_realm, files_override)

    -- Map file return values to cleaned filename.
    local out = {}

    -- Allow files to be overridden.
    local files = files_override
    if not files then files, _ = file.Find(directory_path .. "/*." .. (extension or "lua"), "LUA") end
    for _, f in ipairs(files) do
        if not force_realm and not GNIL.Utils.IsFilenameForCurrentRealm(f) then
            continue
        end

        local name = GNIL.Utils.GetCleanFilename(f, extension or "lua")
        local rtrn = GNIL.Utils.Include(directory_path .. "/" .. f, force_realm)
        if rtrn != nil then
            out[key_uppercase_first && ucfirst(name) || name] = rtrn
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

-- Prevent reloading on luarefresh (although for dev
-- environment everything is always reloaded).
if not GNIL.Loader["_init"] then
    GNIL.log("Starting to load Thirdparty, Classes and other loaders.", "debug")

    -- Load the other loaders (entity, material).
    GNIL.Loader["_loaders"] = loadLoaders()
    for k, _ in pairs(GNIL.Loader["_loaders"]) do GNIL.log("Registered loader handler '" .. k .. "'.", "debug") end

    -- Load thirdparty and classes directories.
    GNIL.Thirdparty = GNIL.Loader.DirectoryMap(GNIL.Utils.ResolveGamemodePath("core/thirdparty"))
    GNIL.Classes    = GNIL.Loader.DirectoryMap(GNIL.Utils.ResolveGamemodePath("core/classes"), true)
end
GNIL.Loader["_init"] = true