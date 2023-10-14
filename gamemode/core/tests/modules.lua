--[[

    - Module instance is preserved across reloads.
    - Extension instance is preserved across reloads.
    - Unload event is recieved.

--]]

return {
    groupName = "Modules",

    afterAll = function()
        GNIL.TestUtils.CleanupModules()
    end,

    cases = {
        {
            name = "Module can be loaded, unloaded and loaded again",
            func = function()

                local testModule = GNIL.TestUtils.CreateModule("modules-loadcycle-1")
                local A, B, C, D = 0, 0, 0, 0
                testModule.OnInit = function() A = A + 1 end
                testModule.OnLoad = function() B = B + 1 end
                testModule.OnUnload = function() C = C + 1 end
                testModule.OnLoadFinished = function() D = D + 1 end

                for i = 1, 4 do
                    expect( testModule:Load() ).to.beTrue()
                    expect( A ).to.equal(i) expect( B ).to.equal(i)

                    expect( testModule:Unload() ).to.beTrue()
                    expect( C ).to.equal(i) expect( D ).to.equal(i)
                end
            end
        },
        {
            name = "Module global is restored after load",
            func = function(state)

                -- Initialize base test module.
                local a, b, c = GNIL.Modules._InitializeModule(GNIL.TestUtils.CreateModule("modules-scope-1"), false, true)
                state.Initialized = a
                state.ModuleInstance = b
                state.CloseEnvironment = c

                local state, expect = state, expect
                local function isModuleName(name)
                    expect( MODULE ).to.exist()
                    expect( MODULE._module_name ).to.equal(name)
                end

                -- 1: Module 'gluatest-modules-scope-1' should be loaded from beforeEach.
                isModuleName("gluatest-modules-scope-1")

                -- 2: Initialize 'gluatest-modules-test-scope-2' module.
                local initialized, moduleInstance, restoreModuleFn = GNIL.Modules._InitializeModule(GNIL.TestUtils.CreateModule("modules-scope-2"), false, true)
                expect( initialized ).to.beTrue()
                state.CloseEnvironment2 = restoreModuleFn

                -- 3: Module 'test-2' should currently set, then close.
                isModuleName("gluatest-modules-scope-2")
                restoreModuleFn()

                -- 4: Module 'test' should now be loaded after 'test-2' is closed. Finally close.
                isModuleName("gluatest-modules-scope-1")
                state.CloseEnvironment()
            end,
            cleanup = function(state)
                if state.CloseEnvironment2 then state.CloseEnvironment2() end
                if state.CloseEnvironment then state.CloseEnvironment() end
            end
        },
        {
            name = "Module dependency loop is stopped",
            func = function(state)

                local A, B = 0, 0

                -- Initialize other module.
                local moduleOne = GNIL.TestUtils.CreateModule("modules-dependencyloop-1")
                moduleOne.OnLoad = function() A = A + 1 end

                local moduleTwo = GNIL.TestUtils.CreateModule("modules-dependencyloop-2")
                moduleTwo.OnLoad = function() B = B + 1 end

                for _, v in ipairs({moduleOne, moduleTwo}) do
                    GNIL.Modules["_cached_modules"][v:GetModuleName()] = v
                end

                moduleTwo:RequireModule("gluatest-modules-dependencyloop-1")
                moduleOne:RequireModule("gluatest-modules-dependencyloop-2")

                expect( moduleOne:IsLoaded() or moduleTwo:IsLoaded() ).to.beFalse()
                expect( moduleOne:Load() ).to.beTrue()
                expect( moduleOne:IsLoaded() and moduleTwo:IsLoaded() ).to.beTrue()
                expect( moduleTwo:Load() ).to.beTrue()
                expect( moduleOne:IsLoaded() and moduleTwo:IsLoaded() ).to.beTrue()

                expect( A ).to.equal( 1 )
                expect( B ).to.equal( 1 )
            end
        }
    }
}