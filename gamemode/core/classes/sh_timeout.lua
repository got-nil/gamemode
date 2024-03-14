
---@class Timeout: EventsMixin
local Timeout = GNIL.Thirdparty.middleclass("Timeout"):IncludeMixin(GNIL.ClassMixins.Events)
ClassAccessorFunc(Timeout, {
    Timeout = FuncAccessors.NumberMinMax("_timeout", 0)
})

--[[

local seconds_timeout = 10
local time = GNIL.Classes.Timeout:New(seconds_timeout)

time:OnTimeout(function()

        -- The 10 second timeout has been reached.
        -- (The resolve() was not called).

    end)
    :OnResolve(function(...)

        -- The resolve function was called, we can
        -- recieve whatever varargs here from the
        -- Run callback.

    end)
    :Run(function(resolve)

        -- Do whatever, but eventually (within 10 seconds)
        -- call the resolve() function.

    end)

--]]

function Timeout:Initialize(timeout)
    self._id = GNIL.Utils.Random(18)
    self._timeout = Either(isnumber(timeout), timeout, 3)
end

---Add a signal listener for timeouts.
---@param callback fun(): nil
---@return Timeout
function Timeout:OnTimeout(callback) self:AddSignalListener("_timeout", callback) return self end

---Add a signal listener for resolutions.
---@param callback fun(...: any): nil
---@return Timeout
function Timeout:OnResolve(callback) self:AddSignalListener("_resolve", callback) return self end

---Run a timeout class, providing the callback with a resolve closure.
---@param callback fun(resolve: fun(...: table)): nil
---@return unknown
function Timeout:Run(callback)

    local timerName = "gnil_timeout_" .. self._id
    local hasResolved = false

    local resolve = function(...)

        -- Remove timeout timer when resolved.
        if hasResolved then return end
        hasResolved = true
        GNIL.Thirdparty.detachedtimer.Remove(timerName)

        self:EmitEvent("_resolve", ...)
    end

     GNIL.Thirdparty.detachedtimer.Create(timerName, self._timeout, 1, function(arguments)

        -- Make sure we're not somehow being called even when the
        -- timeout has been resolved (maybe possible for async?)
        if hasResolved then return end
        hasResolved = true

        self:EmitEvent("_timeout")
    end)

    callback(resolve)
    return self
end

return Timeout