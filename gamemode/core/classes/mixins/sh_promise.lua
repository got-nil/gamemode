
-- Class promises are literally just events, therefore
-- it requires the event mixin (or at least an event interface).
local function installEvents(self)
    if self.EmitEvent and self.AddEventListener then return end
    self:IncludeMixin(GNIL.ClassMixins.Events)
end

return {

    Success = function(self, ...) installEvents(self) return self:EmitEvent("resolve", ...) end,
    Error = function(self, ...) installEvents(self) return self:EmitEvent("reject", ...) end,
    
    OnSuccess = function(self, callback) installEvents(self) self:AddEventListener("resolve", callback) return self end,
    OnError = function(self, callback) installEvents(self) self:AddEventListener("reject", callback) return self end,

    OnCallback = function(self, callback)
        installEvents(self)
        self:AddEventListener("resolve", function(...) callback(true, ...) end)
        self:AddEventListener("reject", function(...) callback(false, ...) end)
        return self
    end

}