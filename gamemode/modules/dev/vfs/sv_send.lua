local MODULE = MODULE
GNIL.Net.AddNetworkString("dev_module_reload")

-- Only allow client files.
local function isClientFile(filepath)
    local realm = GNIL.Utils.GetFilepathRealmPrefix(filepath)
    if not realm then return false end
    return realm != "sv_"
end

-- Find all files in a module directory.
local function findAllClientFiles(moduleInstance, path)

    -- Resolve the start paths.
    local find_path = (path or "") .. "*"
    local all_files, directories = moduleInstance:Find(find_path)
    local files = {}

    -- Filter all found files in module base directory.
    for _, v in ipairs(all_files) do
        if not isClientFile(v) then continue end
        table.insert(files, v)
    end

    for _, v in ipairs(directories) do

        local directory_path = (path or "") .. v .. "/"
        local directory_files = findAllClientFiles(moduleInstance, directory_path)

        for _, v in ipairs(directory_files) do
            if not isClientFile(v) then continue end
            table.insert(files, directory_path .. v)
        end
    end
    return files
end

-- Create a message with all files written to it.
local function createModuleNetworkMessage(moduleInstance, files)

    local content = {}
    for _, v in ipairs(files) do

        -- Read each file.
        local abs_path = moduleInstance:ResolvePath(v)
        local out = file.Read(abs_path, "LUA")
        if not out then
            GNIL.log("Failed to read path '" .. v .. "' when creating VFS.", "debug")
            continue
        end
        content[abs_path] = out
    end

    local message = GNIL.Net.Create("dev_module_reload")
        :WriteData(moduleInstance:GetModuleName())
        :WriteData(tostring(table.Count(content)))

    for filename, content in pairs(content) do
        message:WriteData(filename)
        message:WriteData(content)
    end
    return message
end

local function sendVFSMessage(moduleInstance, players, files)

    local message = createModuleNetworkMessage(moduleInstance, files)
    for _, v in ipairs(players) do
        message:SendChunked(v, true, function(success, output)
            if not success then
                MODULE:log("Failed to send VFS reload to " .. v:ToString() .. " for module '" .. moduleInstance:GetModuleName() .. "'", "warning")
            end
        end)
    end
    return true
end

function GNIL.Dev.VFS.SendReload(moduleInstance, players)

    -- Find all client files within the reloading module.
    local files = findAllClientFiles(moduleInstance)
    if #files == 0 then
        moduleInstance:log("There were no client/shared files to send in developer VFS reload.", "debug")
        return false
    end

    -- Send the VFS reload message.
    return sendVFSMessage(
        moduleInstance,
        players,
        files
    )
end