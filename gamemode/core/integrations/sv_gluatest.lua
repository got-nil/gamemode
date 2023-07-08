-- https://github.com/CFC-Servers/GLuaTest

hook.Add("GLuaTest_RunTestFiles", "GNIL.GLuaTest.AddTests", function(testFiles)

    -- Add tests from modules.
    for _, v in ipairs(GNIL.Modules.GetAll()) do
        if not v.tests then continue end

        -- Make sure the module test directory actually exists.
        local test_dir = v:ResolvePath(v.test_dir or "tests")
        if not file.IsDir(test_dir, "LUA") then
            v:log("Could not find GLuaTests in directory '" .. test_dir .. "'.", "warning")
            continue
        end
        
        -- Set the project to the module name and add the tests.
        for _, t in ipairs(GLuaTest.loader(test_dir)) do
            t.project = v._module_name
            t.gnil_module = v._module_name
            table.insert(testFiles, t)
        end
    end
    
    -- Add core gamemode tests.
    for _, t in ipairs(GLuaTest.loader(GNIL.Utils.ResolveGamemodePath("core/tests"))) do
        t.project = "core"
        table.insert(testFiles, t)
    end
end)

hook.Add("GLuaTest_Finished", "GNIL.GLuaTest.FinishedTests", function(_, allResults)

    local errorModules = {}
    for _, v in ipairs(allResults) do

        -- Get moduleName from result testGroup.
        local moduleName = v.gnil_module
        if not moduleName then continue end

        -- Get the moduleInstance from moduleName.
        local moduleInstance = GNIL.Modules.Get(moduleName)
        if not moduleInstance then continue end

        -- Count the amount of errors for the module.
        if not errorModules[moduleName] then errorModules[moduleName] = {moduleInstance, 0} end
        errorModules[moduleName][2] = errorModules[moduleName][2] + 1
    end

    -- Log error count to module.
    for _, v in pairs(errorModules) do
        v[1]:log(tostring(v[2]) .. " tests failed!", "error")
    end
end)