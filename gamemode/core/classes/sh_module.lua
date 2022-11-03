-- Handle the loading and management of modules.

local Module = GNIL.Thirdparty.middleclass("Module")
function Module:Initialize(name)
    self._module_name = name

    self.name = name
    self.description = "No Description Defined"
    self.author = "No Author Defined"

    self.dependencies = nil
    self._loaded_dependencies = {}

    self._hooks = {
        {}, --seq
        {}  --unique
    }

    self._added_delayed = false
    self._delayed_autoload = {
        {}, -- files
        {}  -- directories
    }

    self._included_files = {}
end

-- Simply call the modules utility with the current module name
-- as the ID argument. This could've just been functional but we're
-- sticking to OOP layout here.
function Module:IsLoaded() return GNIL.Modules.IsLoaded(self._module_name) end
function Module:Load() return GNIL.Modules.Load(self._module_name) end
function Module:Unload() return GNIL.Modules.Unload(self._module_name) end

-- "Resolve" a required module. Basically load it and prevent loops.
function Module:_ResolveRequirement(requirement)
    if self._loaded_dependencies[requirement] then return end
    if requirement == self._module_name then return end
    self:log("Resolving dependency '" .. requirement .. "'", "debug")

    -- Ensure that the module has not yet been loaded.
    if GNIL.Modules.IsLoaded(requirement) then
        self:log("Dependency '" .. requirement .. "' is already loaded.", "debug")
        return
    end

    -- Ensure that we're not attempting to load a dependency that is already
    -- apart of the created dependency chain (prevent dependency loops).
    if self._dependency_chain and self._dependency_chain[requirement] then
        self._loaded_dependencies[requirement] = true
        self:log("Detected dependency recursion while attempting to load '" .. requirement .. "'", "warning")
        return
    else
        if not self._dependency_chain then self._dependency_chain = {} end
        self._dependency_chain[requirement] = true
    end

    -- Load the dependency module, passing through the current dependency chain.
    GNIL.Modules.Load(requirement, self._dependency_chain)
    self._loaded_dependencies[requirement] = true
end

-- Return a table of all other modules this module needs to operate.
function Module:GetDependencies() return self.dependencies and table.GetKeys(self.dependencies) or {} end

-- Require a module. If the delayed argument is true the required
-- module is only loaded at the end of the init file execution. If
-- ommitted or false, the required module is immidiately loaded,
-- and fully executed before continuing with the current module. 
function Module:Require(requirement, delayed)

    -- Retard dectection (raptor is a dumbass) just incase someone
    -- tries to use this as Requires and they give a table despite
    -- me making it very clear that theres a seperate function for it.
    if istable(requirement) then self:Requires(requirement) return end

    if not GNIL.Modules.Exists(requirement) then self:log("Required module '" .. requirement .. "' is Missing/Invalid.", "error") end
    if self.dependencies == nil then self.dependencies = {} end
    self.dependencies[requirement] = true

    -- If we're not delayed, then we should attempt to
    -- "resolve" the requirement immidiately instead of
    -- doing it at the end of the init file load.
    if not delayed then self:_ResolveRequirement(requirement) end
end

-- Allow for multiple dependencies to be given at once.
function Module:Requires(requirements, delayed)
    assert(not table.IsSequential(requirements), "Requirements should be given as a sequential array of module names.")
    for _, v in ipairs(requirements) do
        if not self:Require(v, delayed) then return false end
    end
    return true
end

-- Add a module-based hook
-- Either pass event name and callback for a non-unique name hook
-- or pass event name, unique id, and callback for a removeable hook
function Module:AddHook(eventName, idOrCallback, callback)
    assert((callback == nil or isfunction(idOrCallback)) or (callback != nil and isstring(idOrCallback) and isfunction(callback)). "Arugments must be string, function or string, string, function")

    local hookId = self._module_name .. "." .. eventName
    local hookCallback = callback or idOrCallback

    if callback == nil then
        seq_hooks = self._hooks[1][eventName]

        if seq_hooks == nil then
            seq_hooks = 1
        else
            seq_hooks = seq_hooks + 1
        end

        self._hooks[1][eventName] = seq_hooks

        hookId = hookId .. "." .. tostring(seq_hooks)
    else
        hookId = hookId .. "." .. idOrCallback
    end

    if self._hooks[2][eventName] == nil then
        self._hooks[2][eventName] = {[hookId] = hookCallback}
    else
        self._hooks[2][eventName][hookId] = hookCallback
    end

    hook.Add(eventName, hookId, hookCallback)
end

-- Removes hook(s) that were made through the module
-- Second argument is optional.
-- Without it, all events attached to the module for specified hook are removed
-- With it, that specific event is remove only
function Module:RemoveHook(eventName, hookIdentifier)
    local hooks = self._hooks[2][eventName]
    if hooks == nil then return end

    if hookIdentifier == nil then
        for ident, _ in pairs(hooks) do
            hook.Remove(eventName, ident)
        end

        self._hooks[2][eventName] = nil
        self._hooks[1][eventName] = nil
    else
        for ident, _ in pairs(hooks) do
            local s, e, match = string.find(ident, "%." .. hookIdentifier .. "$")

            if s then
                hook.Remove(eventName, ident)
                self._hooks[2][eventName][ident] = nil
                break
            end
        end

        if self._hooks[2][eventName] == {} then self._hooks[2][eventName] = nil end
    end
end

-- Clears all hooks attached to module
function Module:ClearHooks()
    for eventName, _ in pairs(self._hooks[2]) do
        for ident, _ in pairs(self._hooks[2][eventName]) do
            hook.Remove(eventName, ident)
        end
    end

    self._hooks = { {}, {} }
end

-- Returns table of hooks associated with module
-- First argument is optional
-- Without it, all hooks are in the table, with a table per event
-- With it, all hooks for that event are listed, or an empty table if the hook doesn't have any callbacks
function Module:GetHooks(eventName)
    if eventName == nil then return self._hooks[2] end

    return self._hooks[2][eventName] or {}
end

-- Allow a module to include files or directories
-- relative to its base. If the delayed argument
-- is true then the include is processed with the
-- rest of the files.
function Module:Include(path, delayed)
    path = GNIL.Utils.ResolveGamemodePath("modules/" .. self._module_name .. "/" .. path)
    if not delayed then self._included_files[path] = true return GNIL.Utils.Include(path)
    else self._added_delayed = true self._delayed_autoload[1][path] = true end
end

function Module:IncludeDirectory(directory, ignoredFiles, delayed)
    local path = GNIL.Utils.ResolveGamemodePath("modules/" .. self._module_name .. "/" .. directory)
    if not delayed then return GNIL.Utils.IncludeDirectory(path, ignoredFiles)    
    else self._added_delayed = true self._delayed_autoload[2][path] = true end
end
-------------------------

-- Logging passthrough with module name as prefix.
function Module:log(log, logtype) GNIL.log(log, logtype, self._module_name) end

-- Class hook functions
function Module:OnUnload() end        -- Called when the module is being unloaded.
function Module:OnLoad() end          -- Called while the module is being loaded.
function Module:OnLoadFinished() end  -- Called once the module has finished loading everything.

-- Middleclass allows us to directly overwrite the default tostring handler,
-- allowing us to insert the module name and author if one is defined.
function Module:__tostring()
    return "Module " .. self._module_name .. " by " .. self.author
end

return Module
