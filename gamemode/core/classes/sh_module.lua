-- Handle the loading and management of modules. All modules should be
-- designed with reloading in mind, using OnLoad, OnUnload or OnReinitialize.

local Module = GNIL.Thirdparty.middleclass("Module"):IncludeMixin(GNIL.ClassMixins.Events)
ClassAccessorFunc(Module, {
    Name = FuncAccessors.ReadOnly("name"),
    ModuleName = FuncAccessors.ReadOnly("_module_name"),
    Disabled = FuncAccessors.Boolean("_disabled")
})

function Module:Initialize(name, _emit_signal)
    if _emit_signal != false then
        self:EmitSignal(self._initialized && "Reinitialize" || "Initialize", self)
    end

    self._initialized = true
    self._module_name = name

    self.name = name
    self.description = "No Description Defined"
    self.author = "No Author Defined"

    -- Should the rest of the root directory files within the module
    -- be loaded once the init file has been ran. SetAutoload(...)
    self.autoload = true
    self.dependencies = false
    self._loaded_dependencies = {}
    self._delayed_extensions = {}
    self._disabled = false

    -- Static values that should not change between reinitializations.
    self._static = self._static or {}
    self._extensions = self._extensions or {}
    self._extension_classes = self._extension_classes or {}

    -- If config is set, config_required determines if the module should
    -- be automatically disabled if the config is not found.
    self.config = false
    self.config_required = true

    self._hooks = {
        {}, --seq
        {}  --unique
    }

    self._added_delayed = false
    self._delayed_autoload = {
        {}, -- files
        {}  -- directories
    }

    self._added_ignored_file = false
    self._ignored_files = {}
end

-- Cleanup the module after being unloaded. This is very important as
-- it ensures that reloads don't pool a bunch of old callbacks etc.
-- This can be overriden, but it REALLY shouldn't unless theres a VERY
-- good reason. The "Unload" signal should be used instead.
function Module:_Cleanup()

    self:ClearAllListeners()
    self:ClearHooks()

    -- Reinitialize the module without sending Reinitialization signal.
    self:Initialize(self._module_name, false)

    -- Add all the events back to the extension after cleanup.
    -- (Since the extension listeners would be removed above).
    for _, v in pairs(self._extensions) do
        GNIL.ModuleExtensions._Initialize(self, v)
    end
end

-- Simply call the modules utility with the current module name
-- as the ID argument. This could've just been functional but we're
-- sticking to OOP layout here.
function Module:IsLoaded() return GNIL.Modules.IsLoaded(self._module_name) end
function Module:Load() return GNIL.Modules.Load(self._module_name) end
function Module:Unload() return GNIL.Modules.Unload(self._module_name) end

-- Get module config, set from config attribute. Either use the local
-- module config name or a public/global one. (A little confusing I know).
function Module:Config() return GNIL.Config.Get(Either(self.config == true, "M_" .. self._module_name, self.config)) end

-- A functional way to set the autoload if you want to be fancy.
-- (Although you could just change the class var directly)
function Module:SetAutoload(boolean) assert(isbool(boolean), "The argument must be boolean") self.autoload = boolean end
function Module:SetDisabled(boolean) assert(isbool(boolean), "The argument must be boolean") self._disabled = boolean end

-- "Resolve" a required module. Basically load it and prevent loops.
function Module:_ResolveRequirement(requirement)
    if self._loaded_dependencies[requirement] then return end
    if requirement == self._module_name then return end
    self:log("Resolving dependency '" .. requirement .. "'", "debug")

    -- Ensure that the module has not yet been loaded.
    if GNIL.Modules.IsLoaded(requirement) then
        self._loaded_dependencies[requirement] = true
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

-- Require a module(s). These modules are loaded before OnLoad.
-- Accepts multiple module names as varargs.
function Module:RequireModule(...)
    for _, requirement in ipairs({...}) do
        if not GNIL.Modules.Exists(requirement) then self:log("Required module '" .. requirement .. "' is Missing/Invalid.", "error") end
        if self.dependencies == false then self.dependencies = {} end
        self.dependencies[requirement] = true
    end
end

-- Add a module-based hook
-- Either pass event name and callback for a non-unique name hook
-- or pass event name, unique id, and callback for a removeable hook
function Module:AddHook(eventName, idOrCallback, callback)
    assert((callback == nil or isfunction(idOrCallback)) or (callback != nil and isstring(idOrCallback) and isfunction(callback)), "Arguments must be string, function or string, string, function")

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

-- Add an absolute path to be ignored directly.
local function _addIgnoredFile(self, absolute_path)
    self._added_ignored_file = true
    self._ignored_files[absolute_path] = true
end

-- Allow for relative file paths to be "ignored" when
-- loading directories. This persists across directory
-- includes that are called directly on the module (such
-- as the initial loading of the module etc.)
function Module:Ignore(path)
    self:log("Ignorning file '" .. path .. "'", "debug")
    _addIgnoredFile(self, GNIL.Utils.ResolveGamemodePath("modules/" .. self._module_name .. "/" .. path))
end

-- Allow a module to include files or directories
-- relative to its base. If the delayed argument
-- is true then the include is processed with the
-- rest of the files.
function Module:Include(path, delayed)
    path = GNIL.Utils.ResolveGamemodePath("modules/" .. self._module_name .. "/" .. path)
    if not delayed then
        if self._ignored_files[path] == true then
            return self:log("Refusing to include '" .. path .."' as it is ignored", "debug")
        end

        _addIgnoredFile(self, path)
        return GNIL.Utils.Include(path)

    else self._added_delayed = true self._delayed_autoload[1][path] = true end
end

-- Loading directories directly on the module allows
-- for the module specific ignored files set to be applied
-- (which is important for actually ignoring files). So use
-- this as much as possible when dealing with a module directly.
function Module:IncludeDirectory(directory, ignoredFiles, delayed)
    local path = GNIL.Utils.ResolveGamemodePath("modules/" .. self._module_name .. "/" .. directory)
    if not delayed then

        local ignored_files = nil
        if ignoredFiles or self._added_ignored_file then
            ignored_files = self._ignored_files

            -- If there are provided ignored paths, then we should ensure the
            -- provided ignoredFiles table is associative and attempt to merge
            -- it with the current ignored files set. Any provided paths are
            -- also made absolute here.
            if ignoredFiles then
                local seq = table.IsSequential(ignoredFiles)
                local iterator = seq and ipairs or pairs
                for k, v in iterator(ignoredFiles) do
                    ignored_files[seq and v or k] = true
                end
            end
        end
        return GNIL.Utils.IncludeDirectory(path, ignored_files, true)

    else self._added_delayed = true self._delayed_autoload[2][path] = true end
end

-- Resolve a module path to a full gamemode path.
function Module:ResolvePath(path)
    return GNIL.Utils.ResolveGamemodePath("modules/" .. self._module_name) .. "/" .. path
end

-- Alias of file.Find with the resolved gamemode module path.
function Module:Find(path, sorting)
    return file.Find(self:ResolvePath(path), "LUA", sorting)
end

---------------------------------------------------------------------------

-- Directory MUST be a directory supported by a load handler.
-- Eg: 'entities'. If the directory has a weird name, use LoadDirectory.
function Module:LoadDirectories(directory, handler)
    if not handler then
        for k, v in pairs(GNIL.Loader.GetLoaders()) do
            if v.Directory == directory then
                handler = k
            end
        end
        if not handler then
            return false
        end
    end

    local path = self:ResolvePath(directory)
    local files, directories = file.Find(path .. "/*", "LUA")

    for _, v in ipairs(directories) do
        self:log("Found '" .. handler .. "' '" .. v .. "' at '" .. path .. "'", "debug")
        self:LoadDirectory(path, v, handler)
    end
end

-- base: The base filepath of the directory.
-- directory: The directory name / classname.
-- handler: The load handler to use, eg: 'entity'.
function Module:LoadDirectory(base, directory, handler)
    local loader, path = GNIL.Loader.GetLoader(handler), base .. "/" .. directory
    if loader == nil then
        self:log("Unknown provided load handler '" .. handler .. "' when loading '" .. path .. "'", "error")
        return false
    end

    -- Use the load handler to actually load the directory.
    local success = loader.LoadDirectory(directory, path)
    self:log((success && "Successfully loaded" || "Failed to load") .. " '" .. handler .. "' directory '" .. path .. "'!", success && "debug" || "warning")
    return success
end

---------------------------------------------------------------------------

-- Add an extension with a name and extensionClass. This should be
-- used for modules that require a non-global extension (also for testing).
function Module:AddExtensionByClass(name, extensionClass)
    assert(isstring(name), "Provided extension name must be a string")
    assert(extensionClass:IsSubclassOf(GNIL.Classes.Extension), "Extension class must inherit from BaseModuleExtension")

    -- Do not allow existing extensions to be overwritten.
    if self._extensions[name] then return false end
    if self._extension_classes[name] then return false end

    -- Cache the extension class.
    self._extension_classes[name] = extensionClass
    return true
end

-- Require an extension(s) (is loaded after dependencies in load).
function Module:RequireExtension(...)
    for _, name in ipairs({...}) do
        assert(isstring(name), "Provided extension name must be a string")
        self._delayed_extensions[name:lower()] = true
    end
end

-- Add an extension by name to the Module.
-- ** THIS ACTUALLY LOADS THE EXTENSION, IT DOESNT RETURN IT **
function Module:UseExtension(name)
    assert(isstring(name), "Provided extension name must be a string")
    if self:HasExtension(name) then return false end

    -- Prioritise a modules local reference of extension classes
    -- over the global registry (for testing mainly).
    local extensionInstance = false
    if self._extension_classes[name] then

        -- Initialize the extension and add the passthrough events.
        extensionInstance = GNIL.ModuleExtensions._Initialize(self, self._extension_classes[name]:New(self))
    else

        -- Get the extension normally through global registration.
        extensionInstance = GNIL.ModuleExtensions._Get(self, name)
        if not extensionInstance then
            self:log("Could not find module extension '" .. name .. "'", "error")
            return false
        end
    end

    -- Sanity check just incase.
    if not extensionInstance then
        self:log("Failed to initialize extension '" .. name .. "' for some reason.", "error")
        return false
    end

    -- Cache the extension.
    self._extensions[name] = extensionInstance
    return true
end
function Module:GetExtension(name) return self._extensions[name] end
function Module:HasExtension(name) return self._extensions[name] != nil end

---------------------------------------------------------------------------

-- Logging passthrough with module name as prefix.
function Module:log(log, logtype) GNIL.log(log, logtype, self._module_name) end

-- These functions can be used, however the EventEmitter can also be used.
-- Load hooks (in order of call).
function Module:OnInit() end          -- 1. Called when a module has been initialized, before dependencies. [false=(Module load halted before dependencies)]
function Module:OnLoad() end          -- 2. Called while the module is being loaded, after dependencies.    [false=(Module load halted before main autoload)]
function Module:OnLoadFinished() end  -- 3. Called once the module has finished loading everything.
function Module:OnUnload() end        -- 4. Called when the module is being unloaded.

-- Additional module hooks.
function Module:IsConfigRequired() end -- If a config is set, is it required? Default: true.                [true=(Module is disabled if config missing)]
function Module:__tostring() return self._module_name end

return Module
