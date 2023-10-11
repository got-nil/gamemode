
-- Class promises are literally just signals, therefore
-- it requires the event mixin (or at least an event interface).
local function installEvents(self)
    if self.EmitSignal and self.AddSignalListener then return end
    self:IncludeMixin(GNIL.ClassMixins.Events)
end

return {

    Success = function(self, ...) installEvents(self) return self:EmitSignal("resolve", ...) end,
    Error = function(self, ...) installEvents(self) return self:EmitSignal("reject", ...) end,

    OnSuccess = function(self, callback) installEvents(self) self:AddSignalListener("resolve", callback) return self end,
    OnError = function(self, callback) installEvents(self) self:AddSignalListener("reject", callback) return self end,

    OnCallback = function(self, callback)
        installEvents(self)
        self:AddSignalListener("resolve", function(...) callback(true, ...) end)
        self:AddSignalListener("reject", function(...) callback(false, ...) end)
        return self
    end

}