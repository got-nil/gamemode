GNIL.Hooks = GNIL.Hooks or {
    ["_hooks"] = {}
}

local function _runHookFunction(eventName)
    local callbacks = GNIL.Hooks["_hooks"][eventName]
    if callbacks == nil then return end

    for ident, callback in pairs(callbacks) do
        
    end
end

function GNIL.Hooks.Add(moduleName, eventName, hookIdentifier, callback)

end