
local GNCommand = GNIL.Thirdparty.middleclass("GNCommand")

function GNCommand:Initialize(name, callback)
    assert(GNIL.Commands.IsSuitableName(name), "The provided name must be suitable for a command")
    assert(isfunction(callback), "The callback must be a function")

    self._name = name
    self._callback = callback
    self._data = {}
end

function GNCommand:SetName(name) assert(GNIL.Commands.IsSuitableName(name), "The provided name must be suitable for a command") self._name = name return self end
function GNCommand:SetCallback(callback) assert(isfunction(callback), "The callback must be a function") self._callback = callback return self end

function GNCommand:SetArguments(arguments) assert(GNIL.Commands.Arguments.Validate(arguments), "The arguments provided must be valid") self._data["arguments"] = arguments return self end
function GNCommand:SetAccessCheck(callback_or_enum) assert(isnumber(callback_or_enum) or isfunction(callback_or_enum), "The provided access check must either be a function or GNIL_CMD_ACCESS_ enum") self._data["access_check"] = callback_or_enum return self end
function GNCommand:SetPublic(boolean) assert(isbool(boolean), "The argument provided must be true or false") self._data["public"] = boolean return self end

-- Another alias function (I used this originally so im going to technically
-- call this me taking steps to support legacy code.)
function GNCommand:SetAccess(...) return self:SetAccessCheck(...) end

-- Add an argument to existing arguments set
function GNCommand:AddArgument(enum)
    assert(isnumber(enum) and GNIL.Commands.Arguments.Types[tostring(enum)], "Arguments must be a GNIL_CMD_ARGUMENT_ enum")
    if not self._data["arguments"] then self._data["arguments"] = {} end
    table.insert(self._data["arguments"], enum)
    return self
end

function GNCommand:End()
    
    -- Directly pass constructed arguments to the commands add function
    -- this entire OOP setup is just an interface for this one method.
    return GNIL.Commands.Add(
        self._name,
        self._callback,
        self._data["arguments"],
        self._data["access_check"],
        self._data["public"]
    )
end

-- End alias functions incase someone wants to
-- be special for some reason.
function GNCommand:Create() return self:End() end
function GNCommand:Finish() return self:End() end

GNIL.Commands.OOP = GNCommand