-- All HTTP messages (request, response) inherit from Message.
-- It defines the standard set for setting/getting message attributes
-- and provides a direct shared functional interface for abstracted classes.

local MODULE, Message = MODULE, GNIL.Thirdparty.middleclass("Message")
Message._validMethods = {
    ["GET"] = true,
    ["POST"] = true,
    ["PUT"] = true,
    ["PATCH"] = true,
    ["DELETE"] = true,
    ["OPTIONS"] = true
}

-- Attribute validation
Message._attributes = {

    -- Request Specific
    ["path"]        = TYPE_STRING,
    ["remote_addr"] = TYPE_STRING,
    ["query"]       = function(v) return GNIL.API.Classes.Is(v, "Query") end,

    -- Response Specific
    ["status"]      = TYPE_NUMBER,

    -- Shared
    ["body"]        = function(v) return isstring(v) or GNIL.API.Classes.Is(v, "Body") end,
    ["method"]      = function(v) return isstring(v) and Message._validMethods[string.upper(v)] == true end,
    ["headers"]     = function(v) return GNIL.API.Classes.Is(v, "Headers") end
}

function Message:Get(attribute, default)
    local v = self[attribute]
    if v == nil then return default end
    return v
end

-- Attribute setter that respects attribute data types.
function Message:Set(attribute, value)
    local expected = Message._attributes[attribute]
    if isfunction(expected) then
        if not expected(value) then
            MODULE:log("Message attribute '" .. attribute .. "' was rejected by validator.", "warning")
            return false
        end
    else
        if expected == nil or TypeID(value) != expected then
            MODULE:log("Message attribute '" .. attribute .. "' was rejected due to invalid type.", "warning")
            return false
        end
    end
    self[attribute] = value
    return true
end

-- Convert the request to a table, calling class totable converters
-- if they exist. Ignore any attributes that are undefined (nil).
function Message:ToTable()
    local tbl = {}
    for k, _ in pairs(Message._attributes) do
        local v = self[k]
        if v != nil then
            tbl[k] = (v.class && v.ToTable) && v:ToTable() || v
        end
    end
    return tbl
end

-- Set multiple attributes on a message. All attributes will
-- continue being set even if the previous fails. The return
-- status is true if all succeeded, or false if any failed.
function Message:Sets(attributes)
    if table.IsSequential(attributes) then
        return false
    end
    local fail = false
    for k, v in pairs(attributes) do
        if not self:Set(k, v) then
            fail = true
        end
    end
    return not fail
end

-- Getters/Setters for shared parameters.
function Message:SetMethod(method) self.method = method return true end
function Message:GetMethod() return self.method end
function Message:SetBody(body) self.body = body return true end
function Message:GetBody() return self.body end

-- Headers interface.
function Message:GetHeaders(...) return self.headers:GetAll(...) end
function Message:GetHeader(...) return self.headers:Get(...) end
function Message:SetHeader(...) return self.headers:Set(...) end

GNIL.API.Message = Message