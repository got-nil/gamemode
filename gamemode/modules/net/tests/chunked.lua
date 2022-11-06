
-- Tests multiple strings sent with crc validation on client

local function crc(tbl)
    for i, v in ipairs(tbl) do
        GNIL.log("#" .. i .. ": " .. util.CRC(v), "debug", "CRC Verification")
    end
end

if CLIENT then
    GNIL.Net.ReceiveChunked("test", function(out)
        crc(out)

        for i, y in ipairs(out) do    
            GNIL.log("#" .. i .. ":", "success")
            for _, v in ipairs(string.Explode("\n", y)) do
                Msg(v .. "\n")
            end
        end
    end)

else
    GNIL.Net.AddNetworkString("test")

    local data = {
        file.Read(GNIL.Utils.ResolveGamemodePath("core/sh_utils.lua"), "LUA"),
        file.Read(GNIL.Utils.ResolveGamemodePath("core/sh_modules.lua"), "LUA"),
        file.Read(GNIL.Utils.ResolveGamemodePath("modules/commands/sv_commands.lua"), "LUA"),
        GNIL.Utils.Random(65533 * 24)
    }
    crc(data)

    GNIL.Net.Chunks.Send(me, "test", data, true, function(success, out)
        GNIL.log({
            success,
            out
        })
    end)

end