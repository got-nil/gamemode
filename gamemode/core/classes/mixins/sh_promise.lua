
-- Promise states.
GNIL_PROMISE_STATE_UNRESOLVED = 1
GNIL_PROMISE_STATE_RESOLVED = 2
GNIL_PROMISE_STATE_COUNT = 2

-- Class promises are literally just signals, therefore
-- it requires the event mixin (or at least an event interface).
local function installEvents(self, isResolution)
    if isResolution then self.__IsPromiseResolved = true end
    if self.EmitSignal and self.AddSignalListener then return end
    self:IncludeMixin(GNIL.ClassMixins.Events)
end

---@class PromiseMixin: middleclass
local PromiseMixin = {

    Success = function(self, ...) installEvents(self, true) return self:EmitSignal("resolve", ...) end,
    Error = function(self, ...) installEvents(self, true) return self:EmitSignal("reject", ...) end,

    OnSuccess = function(self, callback) installEvents(self) self:AddSignalListener("resolve", callback) return self end,
    OnError = function(self, callback) installEvents(self) self:AddSignalListener("reject", callback) return self end,

    OnCallback = function(self, callback)
        installEvents(self)
        self:AddSignalListener("resolve", function(...) callback(true, ...) end)
        self:AddSignalListener("reject", function(...) callback(false, ...) end)
        return self
    end,

    GetPromiseState = function(self)
        return self.__IsPromiseResolved == true && GNIL_PROMISE_STATE_RESOLVED || GNIL_PROMISE_STATE_UNRESOLVED
    end

}
return PromiseMixin