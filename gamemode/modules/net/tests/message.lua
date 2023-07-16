
return {
    groupName = "Message",

    cases = {
        {
            name = "Message can be sent and recieved",
            async = true,
            func = function()
                local expect, done = expect, done

                local writeBuffer, _ = GNIL.Net.Testing.WrapWriteable(function()
                    GNIL.Net.Classes.Message:New("test", true)
                        :WriteString("abc")
                        :WriteString("def")
                        :WriteUInt(10, 5)
                    :_WriteToStream()
                end)

                expect( writeBuffer ).toNot.beFalse()
                
                GNIL.Net.Testing.CallReciever(writeBuffer, function(_, __, reply)
            
                    expect( net.ReadString() ).to.equal("abc")
                    expect( net.ReadString() ).to.equal("def")
                    expect( net.ReadUInt(5) ).to.equal(10)

                    expect( reply ).to.beNil()
                    done()
                end)
            end
        },
        {
            name = "Message reply exists on receiver",
            async = true,
            func = function()
                local expect, done = expect, done

                local writeBuffer, _ = GNIL.Net.Testing.WrapWriteable(function()
                    GNIL.Net.Classes.Message:New("test", true)
                        :WriteString("abc")
                        :WriteInt(5, 4)
                        :OnReply(function() end)
                    :_WriteToStream()
                end)

                expect( writeBuffer ).toNot.beFalse()

                GNIL.Net.Testing.CallReciever(writeBuffer, function(_, __, reply)

                    expect( net.ReadString() ).to.equal("abc")
                    expect( net.ReadInt(4) ).to.equal(5)
                
                    expect( reply ).to.exist()
                    done()
                end)
            end
        }
    }
}