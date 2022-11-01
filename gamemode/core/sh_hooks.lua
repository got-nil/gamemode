GNIL.Hooks = GNIL.Hooks or {
    ["_hooks"] = {
        ["test"] = {
            ["test_func"] = function(test)
                return a[1]
            end
        }
    }
}

local function _runHookFunction(eventName, ...)
    local callbacks = GNIL.Hooks["_hooks"][eventName]
    if callbacks == nil then return end

    for ident, callback in pairs(callbacks) do
        success, msg = pcall(callback, ...)
        if !success then print("Hook for \"" .. eventName .. "\" with identifier \"" .. ident .. "\" caused the following error:"); print(msg) end

        -- TODO:
        -- Call function, handle returned values (as base hooks do, return first value)
    end
end

function GNIL.Hooks.Add(moduleName, eventName, hookIdentifier, callback)
    -- TODO:
    -- Actually make this and the remove function
end