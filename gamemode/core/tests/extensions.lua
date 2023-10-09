return {
    groupName = "Extensions",

    beforeEach = function(state)
        state.Module = GNIL.Classes.Module:New("test")
        state.Class = GNIL.Thirdparty.middleclass("TestClass", GNIL.Classes.Extension)
    end,

    cases = {
        {
            name = "Module extension instance is persistent",
            func = function(state)

                local Extension = state.Class
                function Extension:Initialize(...)
                    GNIL.Classes.Extension(self, ...)
                    self.value = GNIL.Utils.Random(6)
                end

                state.Module:AddExtensionByClass("test", Extension)

                expect( state.Module:UseExtension("test") ).to.beTrue()
                expect( state.Module:UseExtension("test") ).to.beFalse()

                local extA, extB = false, false
                extA = state.Module:GetExtension("test")
                extB = state.Module:GetExtension("test")

                expect( extA ).to.exist()
                expect( extB ).to.exist()
                expect( extA.value ).to.equal( extB.value )
            end
        },
        {
            name = "Events passthrough from module",
            func = function(state)

                local Extension = state.Class
                local A, B = 0, 0

                function Extension:OnLoad() A = A + 1 end
                function Extension:OnUnload() B = B + 1 end

                state.Module:AddExtensionByClass("test", Extension)
                expect( state.Module:UseExtension("test") ).to.beTrue()

                -- Send each event twice, this is to make sure that
                -- the extension continues to recieve events even
                -- after an "unload" event.
                for i = 1, 2 do
                    state.Module:EmitSignal("load", state.Module)
                    state.Module:EmitSignal("unload", state.Module)

                    expect( A ).to.equal( i )
                    expect( B ).to.equal( i )
                end
            end
        }
    }
}