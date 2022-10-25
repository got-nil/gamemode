GNIL.Utils = GNIL.Utils or {}

-- Include relative to caller.
function GNIL.Utils.Include(filepath, realm)

    -- If a realm argument is not provided, we should infer one
    -- from its realm prefix.
    if realm == nil then
        realm = GNIL.Utils.GetFilepathRealmPrefix(filepath)
        if realm == nil then return nil end
    end

    GNIL.log("Including file '" .. filepath .. "' (" .. realm .. ")", "debug")
    local currentRealm, rtrn = SERVER and "sv_" or "cl_", nil
    if realm == "sh_" then
        if SERVER then AddCSLuaFile(filepath) end
        rtrn = include(filepath)
    else
        if realm == "cl_" and SERVER then AddCSLuaFile(filepath)
        elseif realm == currentRealm then rtrn = include(filepath)
        else GNIL.log("Realm include error state. File realm: " .. realm .. ", current: " .. currentRealm, "error") end
    end
    
    -- Return the include return value, useful for allowing files to
    -- return instances for directory setup etc.
    return rtrn
end

local realms = {"sh_", "cl_", "sv_"}
function GNIL.Utils.GetFilepathRealmPrefix(filepath) -- ?str
    if 3 > #filepath then return nil end

    -- If there is a slash in the filepath we can assume its not just
    -- a filename. We should explode the filepath and get the last index
    -- as the filename instead.
    if string.find(filepath, "/") then
        local parts = string.Explode("/", filepath)
        filepath = parts[#parts]
    end

    local realm = string.lower(string.Left(filepath, 3))
    return table.HasValue(realms, realm) and realm or nil
end

-- Check if the current file should be loaded in the current realm.
function GNIL.Utils.IsFilenameForCurrentRealm(filepath)
    local prefix = GNIL.Utils.GetFilepathRealmPrefix(filepath)
    if prefix == nil then return false end
    if prefix == "sh_" then return true end
    return (SERVER and "sv_" or "cl_") == prefix
end

-- "Sanitize" a filename by removing any file extension and file
-- realm prefix (optional, default: true) Makes using filenames as ids
-- relatively simple. 
function GNIL.Utils.GetCleanFilename(filename, extension, includeRealmPrefix)
    if not string.StartWith(extension, ".") then extension = "." .. extension end
    local filename = string.Left(filename, #filename - #extension)
    if not includeRealmPrefix and GNIL.Utils.GetFilepathRealmPrefix(filename) != nil then
        filename = string.Right(filename, #filename - 3)
    end
    return filename
end

-- Convert a gamemode path to an absolute LUA path.
function GNIL.Utils.ResolveGamemodePath(path)
    return GNIL.GamemodeFolderName .. "/gamemode/" .. path
end

-- Load all realm prefixed files within a directory, non-recursive
-- Absolute LUA paths are required, when working in gamemode ensure
-- the path is locally resolved (see above)
function GNIL.Utils.IncludeDirectory(path, ignoredFiles)
    GNIL.log("Including directory '" .. path .. "'", "debug")

    for _, f in ipairs(file.Find(path .. "/*.lua", "LUA")) do
        if (ignoredFiles != nil and istable(ignoredFiles)) and table.HasValue(ignoredFiles, f) then continue end

        local realm = GNIL.Utils.GetFilepathRealmPrefix(f)
        if realm == nil then continue end

        GNIL.Utils.Include(path  .. "/" .. f, realm)
    end
end