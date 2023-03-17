GNIL.Utils = GNIL.Utils or {
    ["blacklisted_files"] = {}
}

-- Include relative to caller.
function GNIL.Utils.Include(filepath, realm)

    -- Ensure that the filepath isn't blacklisted.
    if GNIL.Utils["blacklisted_files"][filepath] then
        GNIL.log("Cannot include file '" .. filepath .. "' as it is blacklisted.", "warning")
        return
    end

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
function GNIL.Utils.IncludeDirectory(path, ignoredFiles, absoluteIgnoredFiles)
    GNIL.log("Including directory '" .. path .. "'", "debug")

    for _, f in ipairs(file.Find(path .. "/*.lua", "LUA")) do
        if istable(ignoredFiles) then

            -- If there is a set of ignored files, we should check to
            -- make sure that the file path isn't in the table. Both
            -- relative and absolute paths are checked.
            local seq = table.IsSequential(ignoredFiles)
            
            -- Allow for all ignored to be already declared as absolute,
            -- this means we dont even have to bother checking the relative
            -- path (which for large ignore sets would be more efficient). 
            local ignored, absolute = false, path .. "/" .. f
            for _, v in ipairs(absoluteIgnoredFiles == true and {absolute} or {f, absolute}) do
                if seq then ignored = table.HasValue(ignoredFiles, v)
                else ignored = ignoredFiles[v] == true end
                if ignored then break end
            end

            -- If the file is ignored, then continue to the next one.
            if ignored then GNIL.log("Not loading filepath '" .. absolute .. "' as it is ignored.", "debug") continue end           
        end 

        local realm = GNIL.Utils.GetFilepathRealmPrefix(f)
        if realm == nil then continue end

        GNIL.Utils.Include(path  .. "/" .. f, realm)
    end
end

-- Execute given LUA code, returning any execution return values, or error
-- message if compilation/execution failed. Returns:
--  bool: success
--  output: string error when unsuccessful, or Any output when successful
function GNIL.Utils.Execute(code, name)
    local compiled = CompileString(code, name == nil and "gnil_exec" or name, false)

    -- If the compiled result is a string then the compilation failed.
    if isstring(compiled) then
        return false, "Failed to compile with error: " .. compiled
    end

    -- If the compilation did not fail, we should run the code within a pcall
    -- to catch any runtime errors and catch any return values.
    local success, response = pcall(compiled)
    if success then
        return true, response
    end
    return false, "Execution failed with error: " .. response
end

-- Ensure a DATA directories path will exist, creates directories if required.
function GNIL.Utils.CreateDataPath(path)
    local parts = string.Explode("/", path)
    for i, v in ipairs(parts) do
        local p = table.concat(table.slice(parts, 1, i), "/")
        if not file.IsDir(p, "DATA") then
            file.CreateDir(p)
        end
    end
end

-- Precache character set, skipping certain punctuation.
local charset = {}  do
    for c = 48, 57  do table.insert(charset, string.char(c)) end
    for c = 65, 90  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end
function GNIL.Utils.Random(len)
    if not len or len <= 0 then len = 28 end -- default to 28 length
    math.randomseed(os.clock()^5)
    
    local s = {}
    for i = 1, len do
        table.insert(s, charset[math.random(1, #charset)])
    end
    return table.concat(s)
end