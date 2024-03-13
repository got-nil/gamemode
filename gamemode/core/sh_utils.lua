GNIL.Utils = GNIL.Utils or {
    ["blacklisted_files"] = {},
    ["_loaded_dlls"] = {}
}

-- Filename realm aliaes, these are used by default
-- garrysmod structures (such as entities, weapons etc).
local filenameRealmAliases = {
    ["shared.lua"] = "sh_",
    ["init.lua"] = "sv_",
    ["cl_init.lua"] = "cl_"
}

-- IsDir doesn't work for client sometimes.
function GNIL.Utils.DirectoryExists(filePath, gamePath)

    -- https://github.com/Facepunch/garrysmod-issues/issues/1038
    if SERVER then
        return file.IsDir(filePath, gamePath)
    end

    local baseFilepath, directoryName = GNIL.Utils.SplitPath(filePath)
    local _, directories = file.Find(baseFilepath .. "/*", gamePath)
    if directories == nil then return false end
    for _, v in ipairs(directories) do
        if v == directoryName then
            return true
        end
    end
end

-- Split a provided path into: base(str), filename(str).
function GNIL.Utils.SplitPath(filepath)
    local parts = string.Explode("/", filepath)
    local base, last = "", parts[#parts]
    for i = 1, #parts - 1 do
        base = base .. "/" .. parts[i]
    end
    return base, last
end

-- Include relative to caller.
function GNIL.Utils.Include(filepath, realm)

    -- Ensures that the filepath isn't blacklisted.
    if GNIL.Utils["blacklisted_files"][filepath] then
        GNIL.log("Cannot include file '" .. filepath .. "' as it is blacklisted.", "warning")
        return
    end

    -- If a realm argument is not provided, we should infer one
    -- from its realm prefix.
    if realm == nil then
        realm = GNIL.Utils.GetFilepathRealmPrefix(filepath)
        if realm == nil then return nil end
    else
        -- Ensure realms end with an underscore.
        if realm[#realm] != "_" then
            realm = realm .. "_"
        end
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

    -- If the filename is a realm alias, return that instead of prefix.
    local realmAlias = filenameRealmAliases[filepath]
    if realmAlias then return realmAlias end

    -- First three characters should be the prefix.
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
    if not extension then extension = "lua" end
    if not string.StartWith(extension, ".") then extension = "." .. extension end ---@diagnostic disable-line
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

---Load all realm prefixed files within a directory, non-recursive
---Absolute LUA paths are required, when working in gamemode ensure
---the path is locally resolved (see above)
---** (last argument is deprecated, but is used in old code) **
---@param path string
---@param ignoredFiles? table|boolean
---@param _? any deprecated
function GNIL.Utils.IncludeDirectory(path, ignoredFiles, _)
    GNIL.log("Including directory '" .. path .. "'", "debug")

    -- If a table is provided, ensure its a lookup table.
    if istable(ignoredFiles) then ---@cast ignoredFiles table
        if table.IsSequential(ignoredFiles) then
            ignoredFiles = table.Lookup(ignoredFiles)
        end
    else
        ignoredFiles = false
    end

    for _, f in ipairs(file.Find(path .. "/*.lua", "LUA")) do

        -- Allow some files in the directory to be ignored.
        if ignoredFiles then
            local absolute = path .. "/" .. f
            if ignoredFiles[path] == true or ignoredFiles[absolute] == true then
                GNIL.log("Not loading filepath '" .. absolute .. "' as it is ignored.", "debug")
                continue
            end
        end

        -- Make sure the file has a valid realm prefix/filename.
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

-- Precache character set, skipping certain punctuation.
local charset = {}  do
    for c = 65, 90  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

math.randomseed(os.clock()^5)
function GNIL.Utils.Random(len)
    if not len or len <= 0 then len = 28 end -- default to 28 length

    local s = {}
    for i = 1, len do
        s[i] = charset[math.random(1, #charset)]
    end
    return table.concat(s)
end

-- Replace multiple instances of a needle with different values.
function GNIL.Utils.RecursiveReplace(haystack, needle, callback)

    -- Find all occurances and store its positions.
    local p, r = 0, {}
    while true do
        local startPos, endPos = string.find(haystack, needle, p, true)
        if startPos == nil then break end
        table.insert(r, startPos)
        p = endPos + 1
    end
    if #r == 0 then
        return haystack
    end

    -- Reverse the table of positions, since if we started modifying
    -- the string from the start all the other positions would change too.
    for i, v in ipairs(table.Reverse(r)) do
        local before = string.sub(haystack, 1, v - 1)
        local after = string.sub(haystack, v + #needle)

        haystack = before .. callback(#r - i + 1) .. after
    end
    return haystack
end

-- Check if a lua bin module is installed.
local suffix = ({"osx64", "osx", "linux64", "linux", "win64", "win32"})[(system.IsWindows() and 4 or 0) + (system.IsLinux() and 2 or 0) + (jit.arch == "x86" and 1 or 0) + 1]
local fmt = "lua/bin/gm" .. (CLIENT and "cl" or "sv") .. "_%s_%s.dll"
function GNIL.Utils.GetDLLFilepath(name)
    name = string.lower(name)
    if jit.versionnum != 20004 and jit.arch == "x86" and system.IsLinux() and file.Exists(string.format(fmt, name, "linux32"), "GAME") then
        return string.format(fmt, name, "linux32")
    end
    return string.format(fmt, name, suffix)
end

-- Check if a DLL is installed or already included.
function GNIL.Utils.IsDLLInstalled(name) return file.Exists(GNIL.Utils.GetDLLFilepath(name), "GAME") end
function GNIL.Utils.IsDLLIncluded(name) return GNIL.Utils["_loaded_dlls"][string.lower(name)] == true end

-- Require a DLL. This ensures that the module actually exists,
-- and will not allow modules that have already been included to
-- be loaded twice. Can also verify that global const exists.
function GNIL.Utils.RequireDLL(name, const)

    -- If the DLL is already included, return early.
    if GNIL.Utils.IsDLLIncluded(name) then
        if const then return _G[const] != nil, "Global '" .. const .. "' does not exist, despite the module already being included." end
        return true, nil
    end

    -- Get the target module filepath. If it doesn't exist,
    -- return a failure state + error message.
    local filepath = GNIL.Utils.GetDLLFilepath(name)
    if not file.Exists(filepath, "GAME") then
        local _, filename = GNIL.Utils.SplitPath(filepath)
        return false, "Module '" .. name .. "' (" .. filename .. ") does not exist."
    end

    -- Actually require/load the DLL. This is done in a pcall
    -- just incase (prevent ugly errors for broken modules).
    local success, _ = pcall(require, name)
    if not success then return false, "Could not require module " .. name end

    GNIL.Utils["_loaded_dlls"][string.lower(name)] = true
    if const then return _G[const] != nil, "Global '" .. const .. "' does not exist after requiring module." end
    return true, nil
end
