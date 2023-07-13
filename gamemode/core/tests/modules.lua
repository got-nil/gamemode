--[[

    - Module instance is preserved across reloads.
    - Extension instance is preserved across reloads.
    - Unload event is recieved.

--]]

return {
    groupName = "Modules",

    beforeEach = function(state)
        local a, b, c = GNIL.Modules._Initialize("test", {}, false, true)

        state.Initialized = a
        state.ModuleInstance = b
        state.CloseEnvironment = c
    end,

    afterEach = function(state)
        
        -- Ensure the MODULE environment is always restored.
        -- This can be called even if already called manually.
        state.CloseEnvironment()
    end,

    cases = {
        {
            name = "Module global is restored after load",
            func = function(state)
                
                local state, expect = state, expect
                local function isModuleName(name)
                    expect( MODULE ).to.exist()
                    expect( MODULE._module_name ).to.equal(name)
                end
                
                -- 1: Module 'test' should be loaded from beforeEach.
                isModuleName("test")

                -- 2: Initialize 'test-2' module.
                local initialized, moduleInstance, restoreModuleFn = GNIL.Modules._Initialize("test-2", {}, false, true)               
                state.CloseEnvironment2 = restoreModuleFn
                expect( initialized ).to.beTrue()
                
                -- 3: Module 'test-2' should currently set, then close.
                isModuleName("test-2")
                restoreModuleFn()
                
                -- 4: Module 'test' should now be loaded after 'test-2' is closed. Finally close.
                isModuleName("test")
                state.CloseEnvironment()
            end,
            cleanup = function(state)
                if state.CloseEnvironment2 then state.CloseEnvironment2() end
            end
        }
    }
}