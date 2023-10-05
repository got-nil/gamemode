local Timeout = GNIL.Thirdparty.middleclass("Timeout"):IncludeMixin(GNIL.ClassMixins.Events)
ClassAccessorFunc(Timeout, {
    Timeout = FuncAccessors.NumberMinMax("_timeout", 0)
})

function Timeout:Initialize(timeout)
    self._id = GNIL.Utils.Random(18)
    self._timeout = Either(isnumber(timeout), timeout, 3) 
    self._callback = callback
end

function Timeout:OnTimeout(callback) self:AddSignalListener("_timeout", callback) return self end
function Timeout:OnResolve(callback) self:AddSignalListener("_resolve", callback) return self end

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