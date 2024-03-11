
--[[

    To ensure that the filesystem is returned after running,
    the filesystem is only ran inside a fenv pcall.
    Used similar to 'with' in other languages, a single scope.

--]]

local cannotBeUsed = function() error("This function cannot be used on a Virtual Filesystem.") end
local function createEnvironment(vfs)

    local detours = {

        file = {

            -- Fake async, since obviously we can't
            -- async read from a string table sadly :(
            AsyncRead = function(fileName, gamePath, callback, ...)
                local status, data = FSASYNC_ERR_FAILURE, vfs:Read(fileName)
                if data != nil then
                    status = FSASYNC_OK
                end
                callback(fileName, gamePath, status, data)
            end,

            Time = function(filePath) return vfs:Time(filePath) end,
            CreateDir = function(filePath) return vfs:CreateDir(filePath) end,
            Delete = function(filePath, ...) return vfs:Delete(filePath) end,
            Exists = function(filePath, ...) return vfs:Exists(filePath) end,
            Find = function(filePath, ...) return vfs:Find(filePath) end,
            IsDir = function(filePath, ...) return vfs:IsDir(filePath) end,
            Read = function(filePath, ...) return vfs:Read(filePath) end,
            Size = function(filePath, ...) return vfs:Size(filePath) end,
            Write = function(filePath, ...) return vfs:Write(filePath) end,
            Rename = function(originalPath, targetPath) return vfs:Rename(originalPath, targetPath) end,

            -- TODO: Open
            Open = cannotBeUsed
        },

        AddCSLuaFile = function(...) end,
        include = function(filePath)

            local content = vfs:Read(filePath)
            if content == nil then
                error("Invalid Virtual Filesystem include '" .. filePath .. "'!")
            end
            local success, out = GNIL.Utils.Execute(content, "VFS: " .. filePath)
            if not success then
                error(filePath .. ": " .. out)
            end
            return out
        end

    }

    -- Copy global environment and add our detours ontop.
    local env = GNIL.Dev.CreateEnvironment(nil, true, true)
    for k, v in pairs(detours) do
        env[k] = v
    end
    env.GNIL = GNIL
    return env
end

-- Create a wrapper environment for the file system detours.
function GNIL.Dev.VFS.Wrap(vfs, fn, ...)
    setfenv(fn, createEnvironment(vfs))
    local success, out = pcall(fn, ...)
    return success, Either(success, nil, out)
end
