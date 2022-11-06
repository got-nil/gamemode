
if CLIENT then
    GNIL.Net.ReceiveChunked("test", function(data)
        GNIL.log("Len: " .. #data, "success")
    end)

else
    GNIL.Net.AddNetworkString("test")

    local data = GNIL.Utils.Random(65533 * 16)
    GNIL.log(#data, "success")

    GNIL.Net.Chunks.Send(me, "test", data, true, function(success, out)
        GNIL.log({
            success,
            out
        })
    end)

end