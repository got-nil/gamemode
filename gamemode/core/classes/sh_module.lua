-- Handle the loading and management of modules. All modules should be
-- designed with reloading in mind, using OnLoad, OnUnload or OnReinitialize.

---@alias MODULE Module Current loaded Module.

---@class Module: EventsMixin
---@field name string Module name.
---@field description string Module description.
---@field author string|string[] Module author, or authors.
---@field autoload boolean Should the module be autoloaded?
---@field dependencies boolean|table Set of all Module dependencies.
---@field config string|boolean Module config filename.
---@field config_required boolean Is config required for this Module to load?
---@field config_structure? table The structure the related config file should follow.
---@field _module_name string The internal module name/id.
---@field _initialized boolean Has the Module been initialized.
---@field _base_path? string The Module base filepath.
---@field private _extensions? table<string, BaseExtension>
local Module = GNIL.Thirdparty.middleclass("Module"):IncludeMixin(GNIL.ClassMixins.Events)
ClassAccessorFunc(Module, {
    Name = FuncAccessors.ReadOnly("name"), ---@accessor string readonly
    BasePath = FuncAccessors.ReadOnly("_base_path"), ---@accessor string? readonly
    ModuleName = FuncAccessors.ReadOnly("_module_name"), ---@accessor string readonly
    Disabled = FuncAccessors.Boolean("_disabled"), ---@accessor boolean is
    Autoload = FuncAccessors.Boolean("autoload"), ---@accessor boolean is
    Quiet = FuncAccessors.Boolean("_quiet") ---@accessor boolean is
})

---@param name string
---@param base_path? string
---@param _emit_signal? boolean
function Module:Initialize(name, base_path, _emit_signal)

    -- Just incase.
    assert(isstring(name), "The module name argument must be a string")
    assert(base_path == nil or isstring(base_path), "The module base_path argument must be nil or a string")

    if _emit_signal != false then
        self:EmitSignal(self._initialized && "Reinitialize" || "Initialize", self)
    end

    self._initialized = true
    self._module_name = name
    self._base_path = base_path

    self.name = name
    self.description = "No Description Defined"
    self.author = "No Author Defined"

    -- Should the rest of the root directory files within the module
    -- be loaded once the init file has been ran. SetAutoload(...)
    self.autoload = true
    self.tests = false
    self.dependencies = false
    self._loaded_dependencies = {}
    self._delayed_extensions = {}
    self._disabled = false

    -- Static values that should not change between reinitializations.
    self._static = self._static or {}
    self._extensions = self._extensions or {}
    self._extension_classes = self._extension_classes or {}
    self._quiet = Either(self._quiet != nil, self._quiet, false)

    -- If config is set, config_required determines if the module should
    -- be automatically disabled if the config is not found.
    self.config = false
    self.config_required = true
    self.config_structure = nil

    self._hooks = {
        {}, -- seq
        {}  -- unique
    }

    self._added_delayed = false
    self._delayed_autoload = {
        {}, -- files
        {}  -- directories
    }

    self._added_ignored_file = false
    self._ignored_files = {}
end

---Cleanup the module after being unloaded. This is very important as
---it ensures that reloads don't pool a bunch of old callbacks etc.
---This can be overriden, but it REALLY shouldn't unless theres a VERY
---good reason. The "Unload" signal should be used instead.
function Module:_Cleanup()

    self:ClearAllListeners()
    self:ClearHooks()

    -- Reinitialize the module without sending Reinitialization signal.
    self:Initialize(self._module_name, self._base_path, false)

    -- Add all the events back to the extension after cleanup.
    -- (Since the extension listeners would be removed above).
    for _, v in pairs(self._extensions) do
        GNIL.Modules.Extensions._Initialize(self, v)
    end
end

---Check if the current module is loaded by name.
---@return boolean
function Module:IsLoaded() return GNIL.Modules.IsLoaded(self._module_name) end

---Load the module by name.
---@return boolean
function Module:Load() return GNIL.Modules.Load(self) end

---Unload the module by name.
---@return boolean
function Module:Unload() return GNIL.Modules.Unload(self) end

---Get module config, set from config attribute. Either use the local
---module config name or a public/global one. (A little confusing I know).
---@return Config?
function Module:Config() return GNIL.Config.Get(Either(self.config == true, "M_" .. self._module_name, self.config)) end

---"Resolve"'s a required module. Basically load it and prevent loops.
---@param requirement string
function Module:_ResolveRequirement(requirement)
    if self._loaded_dependencies[requirement] then return end
    if requirement == self._module_name then return end
    self:log("Resolving dependency '" .. requirement .. "'", "debug")

    -- Ensures that the module has not yet been loaded.
    if GNIL.Modules.IsLoaded(requirement) then
        self._loaded_dependencies[requirement] = true
        self:log("Dependency '" .. requirement .. "' is already loaded.", "debug")
        return
    end

    -- Ensure the module name exists.
    if not GNIL.Modules.Exists(requirement) then
        self:log("Dependency '" .. requirement .. "' does not exist.", "warning")
        return
    end

    -- Ensure that we're not attempting to load a dependency that is already
    -- apart of the created dependency chain (prevent dependency loops).
    if self._dependency_chain and self._dependency_chain[requirement] then
        self._loaded_dependencies[requirement] = true
        self:log("Detected dependency recursion while attempting to load '" .. requirement .. "'", "warning")
        return
    else
        if not self._dependency_chain then
            self._dependency_chain = {[self._module_name] = true}
        end
        self._dependency_chain[requirement] = true
    end

    -- Load the requirement.
    GNIL.Modules.Load(requirement, nil, self._dependency_chain)
    self._loaded_dependencies[requirement] = true
end

---Returns a table of all other modules that this module needs to operate.
---@return string[]
function Module:GetDependencies()
    local dependencies = self.dependencies
    if not dependencies then
        return {}
    end ---@cast dependencies table
    return table.GetKeys(dependencies)
end

--Require a module(s). These modules are loaded before OnLoad.
--Accepts multiple module names as varargs.
---@param ... string
function Module:RequireModule(...)
    for _, requirement in ipairs({...}) do
        if not GNIL.Modules.Exists(requirement) then self:log("Required module '" .. requirement .. "' is Missing/Invalid.", "error") continue end
        if self.dependencies == false then self.dependencies = {} end
        self.dependencies[requirement] = true
    end
end

---Adds a module-based hook.
---Either pass event name and callback for a non-unique name hook,
---or pass event name, unique id, and callback for a removeable hook.
---@param eventName string
---@param idOrCallback string|function
---@param callback? function
function Module:AddHook(eventName, idOrCallback, callback)
    assert((callback == nil or isfunction(idOrCallback)) or (callback != nil and isstring(idOrCallback) and isfunction(callback)), "Arguments must be string, function or string, string, function")

    local hookId = self._module_name .. "." .. eventName
    local hookCallback = callback or idOrCallback ---@cast hookCallback function

    if callback == nil then
        local seq_hooks = self._hooks[1][eventName]

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

---Removes hook(s) that were made through the module.
---Second argument is optional.
---Without it, all events attached to the module for specified hook are removed.
---With it, that specific event is remove only.
---@param eventName string
---@param hookIdentifier string
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

---Clears all hooks attached to module
function Module:ClearHooks()
    for eventName, _ in pairs(self._hooks[2]) do
        for ident, _ in pairs(self._hooks[2][eventName]) do
            hook.Remove(eventName, ident)
        end
    end

    self._hooks = { {}, {} }
end

---Returns table of hooks associated with module
---First argument is optional
---Without it, all hooks are in the table, with a table per event
---With it, all hooks for that event are listed, or an empty table if the hook doesn't have any callbacks
---@param eventName string
---@return table
function Module:GetHooks(eventName)
    if eventName == nil then return self._hooks[2] end

    return self._hooks[2][eventName] or {}
end

-- Add an absolute path to be ignored directly.
local function _addIgnoredFile(self, absolute_path)
    self._added_ignored_file = true
    self._ignored_files[absolute_path] = true
end

---Allow for relative file paths to be "ignored" when
---loading directories. This persists across directory
---includes that are called directly on the module (such
---as the initial loading of the module etc.)
---@param path string
function Module:Ignore(path)
    self:log("Ignorning file '" .. path .. "'", "debug")

    local resolved_path = self:ResolvePath(path)
    if resolved_path then
        _addIgnoredFile(self, resolved_path)
    else
        self:log("There is no base_path set! Cannot ignore files.", "debug")
    end
end

---Allow a module to include files or directories
---relative to its base. If the delayed argument
---is true then the include is processed with the
---rest of the files.
---@param path string
---@param delayed? boolean
---@return any
function Module:Include(path, delayed)

    -- Resolve the filepath locally.
    local resolvedPath = self:ResolvePath(path)
    if not resolvedPath then
        self:log("Cannot include relative '" .. path .. "' as there is no base_path set!", "debug")
        return false
    end
    ---@cast resolvedPath string
    path = resolvedPath

    if not delayed then
        if self._ignored_files[path] == true then
            self:log("Refusing to include '" .. path .."' as it is ignored.", "debug")
            return false
        end

        _addIgnoredFile(self, path)
        return GNIL.Utils.Include(path)

    else self._added_delayed = true self._delayed_autoload[1][path] = true end
end

---Loading directories directly on the module allows
---for the module specific ignored files set to be applied
---(which is important for actually ignoring files). So use
---this as much as possible when dealing with a module directly.
---@param directory string
---@param ignoredFiles? table
---@param delayed? boolean
---@return boolean
function Module:IncludeDirectory(directory, ignoredFiles, delayed)
    local path = self:ResolvePath(directory)
    if not path then
        self:log("Cannot include relative '" .. directory .. "/' as there is no base_path set!", "debug")
        return false
    end ---@cast path string
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

        -- Actually include the directory.
        GNIL.Utils.IncludeDirectory(path, ignored_files)
        return true

    else
        self._added_delayed = true
        self._delayed_autoload[2][path] = true
    end
    return true
end

---Resolve a module path to a full gamemode path.
---Returns false if there is no base_path set.
---@param path string
---@return string|boolean
function Module:ResolvePath(path)
    if not self._base_path then return false end
    return self._base_path .. "/" .. path
end

---Alias of file.Find with the resolved gamemode module path.
---@param path string
---@param sorting string
---@return table?
---@return table?
function Module:Find(path, sorting)
    local resolvedPath = self:ResolvePath(path)
    if not resolvedPath then return nil, nil end ---@cast resolvedPath string
    return file.Find(resolvedPath, "LUA", sorting)
end

---------------------------------------------------------------------------

---Directory MUST be a directory supported by a load handler.
---Eg: 'entities'. If the directory has a weird name, use LoadDirectory.
---@param directory string
---@param handler string
---@return boolean
function Module:LoadDirectories(directory, handler)
    if not handler then
        for k, v in pairs(GNIL.Loader.GetLoaders()) do
            if v.Directory == directory then
                handler = k
            end
        end
        if not handler then
            self:log("Could not find any valid handler for LoadDirectories '" .. directory .. "'", "debug")
            return false
        end
    end

    local path = self:ResolvePath(directory)
    if not path then
        self:log("Cannot load relative directory '" .. directory .. "' (" .. handler .. ") as there is no base_path set!", "debug")
        return false
    end ---@cast path string
    local files, directories = file.Find(path .. "/*", "LUA")

    for _, v in ipairs(directories) do
        self:log("Found '" .. handler .. "' '" .. v .. "' at '" .. path .. "'", "debug")
        self:LoadDirectory(path, v, handler)
    end
    return true
end

---Load a directory with some special handler.
---@param base string The base filepath of the directory.
---@param directory string The directory name / classname.
---@param handler string The load handler to use, eg: 'entity'.
---@return boolean
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

---Add an extension with a name and extensionClass. This should be
---used for modules that require a non-global extension (also for testing).
---@param name string
---@param extensionClass BaseExtension
---@return boolean
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

---Require an extension(s) (is loaded after dependencies in load).
---@param ... string
function Module:RequireExtension(...)
    for _, name in ipairs({...}) do
        assert(isstring(name), "Provided extension name must be a string")
        self._delayed_extensions[name:lower()] = true
    end
end

---Load an extension by name on the Module.
---** THIS ACTUALLY LOADS THE EXTENSION, IT DOESNT RETURN IT **
---@param name string
---@return boolean
function Module:LoadExtension(name)
    assert(isstring(name), "Provided extension name must be a string")
    if self:HasExtension(name) then return false end

    -- Prioritise a modules local reference of extension classes
    -- over the global registry (for testing mainly).
    local extensionInstance
    if self._extension_classes[name] then

        -- Initialize the extension and add the passthrough events.
        extensionInstance = GNIL.Modules.Extensions._Initialize(self, self._extension_classes[name]:New(self))
    else

        -- Get the extension normally through global registration.
        local extensionReturn = GNIL.Modules.Extensions._Get(self, name)
        if not extensionReturn then
            self:log("Could not find module extension '" .. name .. "'", "error")
            return false
        end
        extensionInstance = extensionReturn
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

---@param name string
---@return boolean
function Module:HasExtension(name)
    return self._extensions[name] != nil
end

---Get an extension by name.
---@param name string Get an extension by name.
---@return BaseExtension
function Module:GetExtension(name)
    local name, ext = tostring(name), self._extensions[name]
    if ext == nil then
        self:log("Attempted to get unloaded/uninitialized extension '" .. name .. "'", "error")
    end ---@cast ext BaseExtension
    return ext
end

---------------------------------------------------------------------------

---Logging passthrough with module name as prefix.
---@param log string Log message.
---@param logtype? string Log type.
function Module:log(log, logtype)
    if self._quiet then return end
    GNIL.log(log, logtype, self._module_name)
end

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
