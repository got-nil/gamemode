local MODULE = MODULE

MODULE.name = "Development Tools"
MODULE.description  = "A misc set of development tools/utilities."
MODULE.author = "morgverd"

-- This module requires the network module to send chunked file data.
MODULE:Require("net")

--[[

    Since this is a development module, client and shared files within it
    should only be sent to deevelopers. (With all server files ran as usual).
    To do this, we can use the fancy new Net include functions!

    (This file was also made as a working example/test of using advanced net
    features in an actual module, relying heavily on cached netmessages and chunking).

    Environment specific behaviour:
        - prod: Files are read once, cached and resent to connecting developers.
        - dev: Files are re-read and re-sent every lua-refresh.
    
--]]

-- If in the dev environment, always reset the Dev const
-- when re-running to ensure that all cache is flushed.
if GNIL._ENVIRONMENT == "dev" then GNIL.Dev = nil end

GNIL.Dev = GNIL.Dev or {
    ["_files"] = {},
    ["_nm"] = false,
    ["_setup"] = false
}

-- Add a filepath to be sent to developers only.
-- filepath: Absolute LUA path.
function GNIL.Dev.AddDeveloperOnlyFile(filepath)
    if GNIL.Dev["_files"][filepath] then return end
    if not file.Exists(filepath, "LUA") then
        GNIL.log("Supplied developer only file does not exist '" .. filepath .. "'", "warning")
        return false
    end

    -- Read the file contents to cache.
    local content = file.Read(filepath, "LUA")
    if content == nil then
        GNIL.log("Failed to read supplied developer only file '" .. filepath .. "'", "error")
        return false
    end

    -- Cache the filepath and its file content to be sent to devs.
    GNIL.Dev["_files"][filepath] = content

    -- If there is already a cached netmessage, then we can simply
    -- write the file data directly to it (which is pretty cool).
    if GNIL.Dev["_nm"] then
        GNIL.Dev["_nm"]:WriteData(content, #content)
    end
    
    -- "blacklist" the file to ensure that it isn't included
    -- using the Include utility (avoid directory includes).
    GNIL.Utils["blacklisted_files"][filepath] = true 
end

local function sendDeveloperFilesToPlayer(ply)
    
    -- If the netmessage has not yet been cached then we should create it.
    if not GNIL.Dev["_nm"] then

        -- If there are no developer files then immidiately return.
        if table.Count(GNIL.Dev["_files"]) == 0 then
            return
        end

        -- Although using our own messages, we're able to make use of
        -- the 'file_include' chunked reciever from the net PlayerMeta.
        -- We can just write the current file set, as any files written
        -- after initial creation will simply write to the cached message.
        local nm = GNIL.Net.Create("file_include")
        for _, v in pairs(GNIL.Dev["_files"]) do
            nm:WriteData(v, #v)
        end
        GNIL.Dev["_nm"] = nm        
    end 

    -- Send the cached netmessage chunks to the connecting developer. Since
    -- we (could) be sending quite a few files we should checksum verify the
    -- result to ensure no corruption etc.
    GNIL.Dev["_nm"]:SendChunked(ply, true, function(success, out)
        if not success then
            GNIL.log("Failed to send all development files to developer '" .. ply:Nick() "' with error: " .. out .. ".", "error")
        end
    end)
end

-- Only run this code once (to protect against lua refreshes somehow on a prod server).
if not GNIL.Dev["_setup"] then
    
    local module_base = GNIL.Utils.ResolveGamemodePath("modules/dev")
    local files, _ = file.Find(module_base .. "/*.lua", "LUA")
    for _, v in ipairs(files) do
        local absolute = module_base .. "/" .. v

        -- Ensure the file isn't a server file or unprefixed.
        local prefix = GNIL.Utils.GetFilepathRealmPrefix(v)
        if prefix == nil or prefix == "sv_" then continue end

        -- If the file is shared then it should still be executed
        -- by the server.
        if prefix == "sh_" then
            include(absolute)
        end

        -- Finally, add it as a developer only file that should be
        -- sent to connecting developers.
        GNIL.Dev.AddDeveloperOnlyFile(absolute)
    end

    -- If there are currently connected developers send the files out.
    for _, v in ipairs(player.GetAll()) do
        if v:IsDeveloper() then
            sendDeveloperFilesToPlayer(v)
        end
    end

    GNIL.Dev["_setup"] = true
end

-- When a developer has finished connecting, send them all developer files.
hook.Add("PlayerNetLoad", "gnil_dev_include", function(ply)
    if ply:IsDeveloper() then
        GNIL.log("Developer '" .. ply:Nick() .. "' has connected. Sending developer files...", "debug")
        sendDeveloperFilesToPlayer(ply)
    end
end)