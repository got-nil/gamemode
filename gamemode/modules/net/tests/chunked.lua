
-- Tests multiple strings sent with crc validation on client

if CLIENT then
    GNIL.Net.ReceiveChunked("test", function(out)
        GNIL.log("a: " .. #out[1] .. ", b: " .. #out[2], "success")
        GNIL.log({util.CRC(out[1]), util.CRC(out[2])})
    end)

else
    GNIL.Net.AddNetworkString("test")

    local data = {
        GNIL.Utils.Random(65533 * 2),
        GNIL.Utils.Random(65533 * 1)
    }
    GNIL.log({#data[1], #data[2]}, "success")
    GNIL.log({util.CRC(data[1]), util.CRC(data[2])})

    GNIL.Net.Chunks.Send(me, "test", data, true, function(success, out)
        GNIL.log({
            success,
            out
        })
    end)

end