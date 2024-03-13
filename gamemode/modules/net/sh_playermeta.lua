-- This file was originally made as a working example for
-- network module chunking. Simply reads files, sends each
-- file content in chunks to the player, and once all have
-- been sent the client executes each file.

local MODULE = MODULE
local ChatMessageTypes = {
    [1] = {isstring, "String"},
    [2] = {IsColor, "Color"},
    [3] = {IsPlayer, "Player"}
}

if SERVER then

    -- Server setup stuff.
    GNIL.Net.AddNetworkStrings("file_include", "chat_message")

    ---@class Player
    local PlayerMeta = FindMetaTable("Player")

    ---Send code data to player, codes should either be the luacode
    ---to execute, or a table of luastrings that should be sent.
    ---@param codes string|string[]
    function PlayerMeta:Execute(codes)
        local nm = GNIL.Net.Create("file_include")
        for _, v in ipairs(Either(istable(codes), codes, {codes})) do
            nm:WriteData(v, #v)
        end
        nm:SendChunked(self, true, function(success, output)
            if not success then
                MODULE:log("Failed to include files on player '" .. self:Nick() .. "' with error: " .. output, "error")
            end
        end)
    end

    ---Include a file (given by absolute path) on a player. When
    ---including multiple files it is more efficient to call this
    ---function with a table of filepaths instead of re-running
    ---as it sends all the files as a single message.
    ---@param absolute_filepaths string|string[]
    ---@param allow_server_files? boolean
    ---@return boolean
    function PlayerMeta:Include(absolute_filepaths, allow_server_files)
        local codes = {}
        for _, filepath in ipairs(Either(istable(absolute_filepaths), absolute_filepaths, {absolute_filepaths})) do
            if not file.Exists(filepath, "LUA") then return false end
            if not allow_server_files then
                local realm_prefix = GNIL.Utils.GetFilepathRealmPrefix(filepath)
                if realm_prefix == "sv_" then
                    MODULE:log("Refusing to include file '" .. filepath .. "' on player '" .. self:Nick() .. "' as it is a server file.", "error")
                    return false
                end
            end

            local code = file.Read(filepath, "LUA")
            if code == nil then return false
            else MODULE:log("Read file '" .. filepath .. "' to send to player '" .. self:Nick() .. "'", "debug") end
            table.insert(codes, code)
        end

        -- Once all files have been read, include all the files together.
        self:Execute(codes)
        return true
    end

    ---Send Colors and strings to send PrintMessage.
    ---@param ... string|Color|Player
    function PlayerMeta:ChatMessage(...)
        local chat_net, tbl = GNIL.Net.Create("chat_message"), {...}

        chat_net:WriteUInt(#tbl, 16)
        for _, v in ipairs(tbl) do

            -- Find the argument type from validator.
            local type_id, type_name = 0, "String"
            for i, data in ipairs(ChatMessageTypes) do
                if data[1](v) then
                    type_id, type_name = i, data[2]
                    break
                end
            end

            -- If its none of the other types, make it a string.
            if type_id == 0 then
                v = tostring(v)
                type_id, type_name = 1, "String"
            end

            -- Write the type ID and then directly add the value
            -- and typename to the buffer.
            -- Equiv: chat_net["Write" .. type_name](chat_net, ...)
            chat_net:WriteUInt(type_id, 2)
            chat_net:_WriteToBuffer({v}, type_name)
        end
        chat_net:Send(self)
    end
else

    -- Receive the files once the chunks finished being sent. Then just
    -- use the execute utility function to run each within a pcall.
    GNIL.Net.ReceiveChunked("file_include", function(data)
        if not istable(data) then data = {data} end
        for _, v in ipairs(data) do
            local success, out = GNIL.Utils.Execute(v, "gnil_include")
            if not success then
                MODULE:log("Net include error: " .. out, "error")
            end
        end
    end)

    -- Recieve chat message messages from server.
    GNIL.Net.Receive("chat_message", function()

        local out = {}
        for _ = 1, net.ReadUInt(16) do

            local type_id = net.ReadUInt(2)
            local type_data = ChatMessageTypes[type_id]

            if type_id != 0 and type_data != nil then

                -- Read the type directly, ignore it if
                -- the value is nil to prevent weird messages.
                local value = net["Read" .. type_data[2]]()
                if value then
                    table.insert(out, value)
                end
            end
        end

        chat.AddText(unpack(out))
    end)
end