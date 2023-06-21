local MODULE = MODULE

MODULE.name = "Development Tools"
MODULE.description  = "A misc set of development tools/utilities."
MODULE.author = "morgverd"

-- This module requires the network module to send chunked file data.
MODULE:Require("net")
MODULE:SetAutoload(false) -- Handle loading ourselves.

--[[

    Since this is a development module, client and shared files within it
    should only be sent to developers. (With all server files ran as usual).
    To do this, we can use the fancy new Net include functions!

    (This file was also made as a working example/test of using advanced net
    features in an actual module, relying heavily on cached netmessages and chunking).

    Environment specific behaviour:
        - prod: Files are read once, cached and resent to connecting developers.
        - dev: Files are re-read and re-sent every lua-refresh.
    
--]]

-- If in the dev environment, always reset the Dev const
-- when re-running to ensure that all cache is flushed.
if GNIL.ENV.DEV then GNIL.Dev = nil end

GNIL.Dev = GNIL.Dev or {
    ["_files"] = {},
    ["_setup_nm"] = false,
    ["_devfiles_nm"] = false,
    ["_setup"] = false,
}

-- I wouldn't usually suggest designing a module like this, but I wanted
-- to make sure wouldn't accidentally delete the core as a dev script.
MODULE.OnLoad = function()

    -- These are the first files loaded by the developer before
    -- any other developer scripts. If any fail to load, the devscripts
    -- are not sent. This is for loading required handlers etc.
    GNIL.Net.AddNetworkString("dev_files")
    local setupFiles = {
        ["cl_recvfiles.lua"] = true
    }

    -- Add a filepath to be sent to developers only.
    -- filepath: Absolute LUA path.
    function GNIL.Dev.AddDeveloperOnlyFile(filepath)
        if GNIL.Dev["_files"][filepath] then return end
        if not file.Exists(filepath, "LUA") then
            MODULE:log("Supplied developer only file does not exist '" .. filepath .. "'", "warning")
            return false
        end

        -- Read the file contents to cache.
        local content = file.Read(filepath, "LUA")
        if content == nil then
            MODULE:log("Failed to read supplied developer only file '" .. filepath .. "'", "error")
            return false
        end

        -- Cache the filepath and its file content to be sent to devs.
        GNIL.Dev["_files"][filepath] = content

        -- If there is already a cached netmessage, then we can simply
        -- write the file data directly to it (which is pretty cool).
        if GNIL.Dev["_devfiles_nm"] then
            GNIL.Dev["_devfiles_nm"]:WriteData(filepath, #filepath)
            GNIL.Dev["_devfiles_nm"]:WriteData(content, #content)
        end
        
        -- "blacklist" the file to ensure that it isn't included
        -- using the Include utility (avoid directory includes).
        GNIL.Utils["blacklisted_files"][filepath] = true 
    end

    local function sendDeveloperFilesToPlayer(ply, is_first_join)
        
        -- If the netmessage has not yet been cached then we should create it.
        if not GNIL.Dev["_devfiles_nm"] then

            -- If there are no developer files then immidiately return.
            if table.Count(GNIL.Dev["_files"]) == 0 then
                return
            end

            -- Although using our own messages, we're able to make use of
            -- the 'file_include' chunked reciever from the net PlayerMeta.
            -- We can just write the current file set, as any files written
            -- after initial creation will simply write to the cached message.

            -- Send the message to be recieved and stored by the client (dev)
            -- allowing the file contents to be 
            local nm = GNIL.Net.Create("dev_files")
            for k, v in pairs(GNIL.Dev["_files"]) do
                nm:WriteData(k, #k)
                nm:WriteData(v, #v)
            end
            GNIL.Dev["_devfiles_nm"] = nm        
        end

        -- Can be called immidiately, or once the setup netmessage has been responded to.
        local sendDeveloperFiles = function(ply)

            -- Send the cached netmessage chunks to the connecting developer. Since
            -- we (could) be sending quite a few files we should checksum verify the
            -- result to ensure no corruption etc.    
            ply:log("Receiving developer files.", "debug")
            GNIL.Dev["_devfiles_nm"]:SendChunked(ply, true, function(success, out)
                if not success then
                    MODULE:log("Failed to send all development files to developer '" .. ply:Nick() "' with error: " .. out .. ".", "error")
                end
            end)
        end

        if is_first_join then
            
            -- First, send the cached recvfiles netmessage to the connecting developer.
            -- This file adds support for actually 
            ply:log("Receiving developer setup files, required for loading other devfiles.", "debug")
            GNIL.Dev["_setup_nm"]:SendChunked(ply, true, function(success, out)
                if not success then
                    ply:log("Failed to load developer setup files with error: " .. out, "error")
                else

                    -- Finally, send the developer files once we're all setup!
                    ply:log("Successfully loaded developer setup files, proceeding with actual developer files.", "debug")
                    sendDeveloperFiles(ply)
                end
            end)
        else

            -- If its not the first time the player has joined, we can just
            -- immidiately send the developer files! No waiting for setup netmessage!
            sendDeveloperFiles(ply)
        end

    end

    -- Create/cache the setup netmessage. This is sent first to developers once they connect
    -- as is used to actually send the handlers required to load the other developer scripts.
    if not GNIL.Dev["_setup_nm"] then
        
        -- Use the existing 'file_include' net handler to recieve and execute the setup file
        -- content. The handler is provided in net module and already exists for all players.
        local setup_nm = GNIL.Net.Create("file_include")
        for k, _ in pairs(setupFiles) do
            local content = file.Read(GNIL.Utils.ResolveGamemodePath("modules/dev") .. "/" .. k, "LUA")
            if content == nil then
                MODULE:log("Setup file '" .. k .. "' does not exist within dev module, or is invalid. Skipping.", "warning")
                continue
            end
            
            -- Write the setup script data directly.
            setup_nm:WriteData(content, #content)
        end

        GNIL.Dev["_setup_nm"] = setup_nm
        MODULE:log("Generated setup netmessage.", "debug")
    end 

    -- Only run this code once (to protect against lua refreshes somehow on a prod server).
    if not GNIL.Dev["_setup"] then

        -- Load all temporary developer files from the modules loader. These are from modules
        -- that were loaded before this one (stored as a temp cache). 
        for _, v in ipairs(GNIL.Modules["_tmp_dev_files"]) do
            GNIL.Dev.AddDeveloperOnlyFile(v)
        end
        GNIL.Modules["_tmp_dev_files"] = {}
        
        -- Load files within the dev module as dev files.
        local module_base = GNIL.Utils.ResolveGamemodePath("modules/dev")
        local files, _ = file.Find(module_base .. "/*.lua", "LUA")

        for _, v in ipairs(files) do
            if setupFiles[v] or v == "sv_init.lua" then continue end
            local absolute = module_base .. "/" .. v

            -- Ensure the file isn't a server file or unprefixed.
            local prefix = GNIL.Utils.GetFilepathRealmPrefix(v)
            if prefix == nil then continue end

            -- If the file is shared or serverside, it should still be included
            -- by the server on intial load (like standard autoload).
            if prefix == "sh_" or prefix == "sv_" then
                include(absolute)
            end

            -- If the prefix isnt serverside then we should add it as a file that
            -- should be sent to all developers on load (shared and client files).
            if prefix != "sv_" then

                -- Finally, add it as a developer only file that should be
                -- sent to connecting developers.
                GNIL.Dev.AddDeveloperOnlyFile(absolute)
            end
        end

        -- If there are currently connected developers send the files out.
        for _, v in ipairs(player.GetAll()) do
            if v:IsDeveloper() then
                sendDeveloperFilesToPlayer(v, true)
            end
        end

        GNIL.Dev["_setup"] = true
    end

    -- When a developer has finished connecting, send them all developer files.
    hook.Add("PlayerNetLoad", "gnil_dev_include", function(ply)
        if ply:IsDeveloper() then
            MODULE:log("Developer '" .. ply:Nick() .. "' has connected. Sending developer files...", "debug")
            sendDeveloperFilesToPlayer(ply, true)
        end
    end)
end