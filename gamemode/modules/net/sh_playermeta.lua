-- This file was originally made as a working example for
-- network module chunking. Simply reads files, sends each
-- file content in chunks to the player, and once all have
-- been sent the client executes each file.

if SERVER then

    -- Server setup stuff.
    GNIL.Net.AddNetworkString("file_include")
    local PlayerMeta = FindMetaTable("Player")

    -- Send code data to player, codes should either be the luacode
    -- to execute, or a table of luastrings that should be sent.
    function PlayerMeta:Execute(codes)
        local nm = GNIL.Net.Create("file_include")
        for _, v in ipairs(istable(codes) and codes or {codes}) do
            nm:WriteData(v, #v)
        end
        nm:SendChunked(self, true, function(success, output)
            if not success then
                GNIL.log("Failed to include files on player '" .. self:Nick() .. "' with error: " .. output, "error")
            end
        end)
    end

    -- Include a file (given by absolute path) on a player. When
    -- including multiple files it is more efficient to call this
    -- function with a table of filepaths instead of re-running
    -- as it sends all the files as a single message.
    function PlayerMeta:Include(absolute_filepaths, allow_server_files)
        local codes = {}
        for _, filepath in ipairs(istable(absolute_filepaths) and absolute_filepaths or {absolute_filepaths}) do
            if not file.Exists(filepath, "LUA") then return false end
            if not allow_server_files then
                local realm_prefix = GNIL.Utils.GetFilepathRealmPrefix(filepath)
                if realm_prefix == "sv_" then
                    GNIL.log("Refusing to include file '" .. filepath .. "' on player '" .. self:Nick() .. "' as it is a server file.", "error")
                    return false
                end
            end

            local code = file.Read(filepath, "LUA")
            if code == nil then return false
            else GNIL.log("Read file '" .. filepath .. "' to send to player '" .. self:Nick() .. "'", "debug") end
            table.insert(codes, code)
        end

        -- Once all files have been read, include all the files together.
        self:Execute(codes)
    end
else

    -- Receive the files once the chunks finished being sent. Then just
    -- use the execute utility function to run each within a pcall.
    GNIL.Net.ReceiveChunked("file_include", function(data)
        if not istable(data) then data = {data} end
        for _, v in ipairs(data) do
            local success, out = GNIL.Utils.Execute(v, "gnil_include")
            if not success then
                GNIL.log("Net include error: " .. out, "error")
            end
        end
    end)
end