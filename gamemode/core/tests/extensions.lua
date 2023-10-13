return {
    groupName = "Extensions",

    beforeEach = function(state)
        state.Class = GNIL.Thirdparty.middleclass("TestClass", GNIL.Classes.Extension)
    end,

    afterAll = function()
        GNIL.TestUtils.CleanupModules()
        GNIL.TestUtils.CleanupExtensions()
    end,

    cases = {
        {
            name = "Module extension instance is persistent",
            func = function(state)

                local Extension = state.Class
                function Extension:Initialize(...)
                    GNIL.Classes.Extension(self, ...)
                    self.value = GNIL.Utils.Random(12)
                end

                local testModule = GNIL.TestUtils.CreateModule("extensions-module-persistent-1")
                testModule:AddExtensionByClass("gluatest-extensions-persistent-1", Extension)

                expect( testModule:LoadExtension("gluatest-extensions-persistent-1") ).to.beTrue()
                expect( testModule:LoadExtension("gluatest-extensions-persistent-1") ).to.beFalse()

                local extA, extB = false, false
                extA = testModule:GetExtension("gluatest-extensions-persistent-1")
                extB = testModule:GetExtension("gluatest-extensions-persistent-1")

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

                local testModule = GNIL.TestUtils.CreateModule("extensions-events-1")
                testModule:AddExtensionByClass("gluatest-modules-extension-2", Extension)
                expect( testModule:LoadExtension("gluatest-modules-extension-2") ).to.beTrue()

                -- Send each event twice, this is to make sure that
                -- the extension continues to recieve events even
                -- after an "unload" event.
                for i = 1, 4 do
                    testModule:EmitSignal("load", testModule)
                    testModule:EmitSignal("unload", testModule)

                    expect( A ).to.equal( i )
                    expect( B ).to.equal( i )
                end
            end
        },
        {
            name = "Module RequireExtension loads extensions on load",
            func = function(state)

                local Extension, A = state.Class, 0
                function Extension:Initialize(...)
                    GNIL.Classes.Extension(self, ...)
                    self.value = GNIL.Utils.Random(12)
                end
                function Extension:OnLoad() A = A + 1 end
                GNIL.ModuleExtensions.Add("gluatest-modules-extension-3", Extension)

                local testModule = GNIL.TestUtils.CreateModule("extension-loads-1")
                expect( testModule:HasExtension("gluatest-modules-extension-3") ).to.beFalse()
                testModule:RequireExtension("gluatest-modules-extension-3")
                expect( testModule:HasExtension("gluatest-modules-extension-3") ).to.beFalse()

                expect( testModule:Load() ).to.beTrue()
                expect( testModule:HasExtension("gluatest-modules-extension-3") ).to.beTrue()
                expect( A ).to.equal( 1 )

                local ext_a = testModule:GetExtension("gluatest-modules-extension-3")
                expect( ext_a ).to.exist()

                for i = 1, 4 do
                    expect( testModule:Unload() ).to.beTrue()
                    expect( testModule:Load() ).to.beTrue()
                    expect( A ).to.equal( i + 1 )

                    local ext_b = testModule:GetExtension("gluatest-modules-extension-3")
                    expect( ext_b ).to.exist()
                    expect( ext_a.value ).to.equal( ext_b.value )
                end

                expect( A ).to.equal( 5 )
            end
        }
    }
}