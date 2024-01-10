
-- Virtual File System.
-- Basically just a wrapper allowing for include and file operations to work
-- on a table filesytem. This is obviously less efficient than the real fs.

local function cleanFilePath(filePath, asTable)
    local out = {}
    if filePath then
        for _, v in ipairs(string.Explode("/", filePath)) do
            if v == "" then continue end
            table.insert(out, v)
        end
    end
    return Either(asTable, out, table.concat(out, "/"))
end

local function splitFilePath(filePath, alreadyClean)
    if alreadyClean then
        return string.Explode("/", filePath)
    end
    return cleanFilePath(filePath, true)
end

-- Thanks to Virtualraptor for the pattern.
local function wildcardFilenameToPattern(fileNameWildcard)
    local placeholder = "<WILDCARD_PLACEHOLDER>"
    local out = string.PatternSafe(
        string.Replace(fileNameWildcard, "*", placeholder)
    )
    return string.Replace(out, placeholder, "[%s%S]*")
end

---------------------------------------------------------------

local VFS = GNIL.Thirdparty.middleclass("VirtualFileSystem")
function VFS:Initialize(fileSystem)
    self.__vfs = fileSystem or {}
    self.__init_time = os.time()
    self.__times = {}
end

-- Navigate to a target and ensure we actually reached it.
function VFS:_NavigateToTarget(filePath)
    local fileParts, validLen, fsOut = splitFilePath(filePath), 0, nil

    for fs, _ in self:Iterator(fileParts) do
        validLen = validLen + 1
        fsOut = fs
    end

    if #fileParts != validLen then
        return
    end
    return fsOut
end

-- Get the parent of provided filePath, this can be
-- offset to traverse the filePath tree.
function VFS:_GetParentDirectory(filePath, offset)
    local offset, pathParts = offset or 1, filePath
    if not istable(filePath) then
        pathParts = splitFilePath(filePath)
    end

    local outFs, i = false, 0
    for fs, v in self:Iterator(table.Slice(pathParts, 1, #pathParts - offset)) do
        i = i + 1
        outFs = fs
    end

    -- Make sure we actually navigated all the way to the parent path.
    if i != #pathParts - offset then
        return
    end
    return outFs
end

-- Alias to self wrap.
function VFS:Wrap(callback, ...)
    return GNIL.Dev.VFS.Wrap(self, callback, ...)
end

-- Get the last write/create time of a file or directory.
function VFS:Time(filePath)
    filePath = cleanFilePath(filePath)

    local cached_time = self.__times[filePath]
    if cached_time then return cached_time end

    if self:Exists(filePath) then
        return self.__init_time
    end
    return
end

-- Iterate through the filesystem tree.
function VFS:Iterator(path)

    local splitPath = path
    if not istable(path) then
        splitPath = splitFilePath(path)
    end

    local fs = self.__vfs
    local index = 0

    return function()
        index = index + 1
        local v = splitPath[index]

        if fs[v] == nil then
            return
        end
        fs = fs[v]
        return fs, v
    end
end

-- Create an empty directory (can be nested)
function VFS:CreateDir(filePath)
    filePath = cleanFilePath(filePath)
    local fs, pathParts = self.__vfs, splitFilePath(filePath, true)
    for i, v in ipairs(pathParts) do
        if not fs[v] then

            -- TODO: TEST THIS.
            self.__time[table.concat(table.Slice(pathParts, 1, i), "/")] = os.time()

            fs[v] = {}
        end
        fs = fs[v]
    end
    return self
end

-- Delete a file / empty directory.
function VFS:Delete(filePath)
    filePath = cleanFilePath(filePath)
    if not self:Exists(filePath) then
        return false
    end
    if self:IsDir(filePath) and not self:IsDirEmpty(filePath) then
        return false
    end
    self.__times[filePath] = nil
    self:Write(filePath, nil)
    return true
end

-- Check if file or directory exists.
function VFS:Exists(filePath)
    return self:_NavigateToTarget(filePath) != nil
end

-- Find files and directories within the filePath directory.
-- This supports wildcard filenames like normal file.Find.
function VFS:Find(filePath)

    -- Traverse up to the parent directory of the filepath.
    local pathParts, baseFs = splitFilePath(filePath), {}

    -- If the path is nested, navigate to the parent base.
    if #pathParts > 1 then

        -- Find the parent directory of filepath.
        local parentDir = self:_GetParentDirectory(pathParts)
        if not parentDir then
            return nil, nil
        end
        baseFs = parentDir
    else
        baseFs = self.__vfs
    end

    -- The last part in the path is probably the filename, which could have
    -- a wildcard hence why it has to be handled seperately.
    local lastPart = pathParts[#pathParts]
    local isWildcard = false

    -- Find any asterix in the last part.
    for i = 1, #lastPart do
        if lastPart[i] == "*" then
            isWildcard = true
            break
        end
    end

    -- Find target directory.
    local targetDirectory = baseFs
    if not isWildcard then
        targetDirectory = baseFs[lastPart]
    else

        -- If the wildcard is just "*" then basically just pretend there isnt one,
        -- since it just means to accept anything so theres no point applying filter.
        if lastPart == "*" then
            isWildcard = false
        else

            -- Convert the wildcard filename into a pattern.
            lastPart = wildcardFilenameToPattern(lastPart)
        end
    end
    if not istable(targetDirectory) then
        return nil, nil
    end

    -- Actually find the shallow contents of the targetDirectory.
    local out = {{}, {}}
    for k, v in pairs(targetDirectory) do

        -- Apply wildcard filter to file names.
        local shouldAdd, is_table = true, TypeID(v) == TYPE_TABLE
        if isWildcard and not is_table then
            shouldAdd = string.match(k, lastPart) != nil
        end
        if shouldAdd then
            table.insert(out[Either(is_table, 2, 1)], k)
        end
    end
    return out[1], out[2]
end

function VFS:IsDirEmpty(filePath)
    local target = self:_NavigateToTarget(filePath)
    if not istable(target) then return false end
    return table.IsEmpty(target)
end

function VFS:IsDir(filePath)
    local target = self:_NavigateToTarget(filePath)
    if target == nil then return false end
    return istable(target)
end

function VFS:IsFile(filePath)
    local target = self:_NavigateToTarget(filepath)
    if target == nil then return false end
    return isstring(target)
end

function VFS:Read(filePath)
    local fs = self.__vfs
    for _, v in ipairs(splitFilePath(filePath)) do
        if fs[v] == nil then
            return
        end
        fs = fs[v]
    end

    -- Only return files, not directories.
    if istable(fs) then return end
    return fs
end

-- Get the size of filePath content.
function VFS:Size(filePath)
    local content = self:Read(filePath)
    if not content then return -1 end
    return string.len(content)
end

function VFS:Write(filePath, content)
    filePath = cleanFilePath(filePath)
    local fs, pathParts = self.__vfs, splitFilePath(filePath, true)

    -- If there is a filepath, navigate to its parent in the filesystem.
    if #pathParts > 1 then
        for _, v in ipairs(table.Slice(pathParts, 1, #pathParts - 1)) do
            fs = fs[v]
            if fs == nil then
                return false
            end
        end
        filename = pathParts[#pathParts]
    else
        filename = pathParts[1]
    end

    -- Write the file to the VFS.
    self.__times[filePath] = os.time()
    fs[filename] = content
    return self
end

GNIL.Dev.VFS.Class = VFS