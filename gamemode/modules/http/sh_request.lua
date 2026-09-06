local MODULE = MODULE

---@alias Http.Request.Arguments table<string, any>|any[]

---@class Http.Request: middleclass
local Request = GNIL.Thirdparty.middleclass("Request")

-- method, url, body, headers, callback
function Request:Initialize(...)
    local args = {...}
    self.requestProperties = {
        ["method"] = true,
        ["url"] = true,
        ["callback"] = true,
        ["body"] = false,
        ["headers"] = false,
    }

    -- If an associative table is provided as the first argument
    -- then we should take that as the input and directly set it
    -- into the class parameters.
    if #args >= 1 and istable(args[1]) and not table.IsSequential(args[1]) then
        for k, v in pairs(args[1]) do
            self[k] = v
        end
    else
        for i, v in ipairs(table.GetKeys(self.requestProperties)) do
            if i > #args then return end
            self[v] = args[i]
        end
    end
end

-- Parameter set functions.
function Request:SetMethod(method) self.method = method end
function Request:SetURL(url) self.url = url end
function Request:SetBody(body) self.body = body end
function Request:SetHeaders(headers) self.headers = headers end
function Request:SetCallback(callback) self.callback = callback end

-- Additional helper functions.
function Request:SetHeader(header, value)
    if self.headers == nil then self.headers = {} end
    self.headers[header] = value
end

-- Validate that the request properties have been defined.
-- The actual validation (type/functional) is done in sh_http once
-- the request is actually sent.
function Request:IsValid()
    for k, v in pairs(self.requestProperties) do
        if self[k] == nil && v then
            MODULE:log("Required request key '" .. k .. "' cannot be unset.", "warning")
            return false
        end
    end
    return true
end

-- Calling the request directly should alias sending it.
function Request:__call() return self:Send() end

---Validate and then send the request.
function Request:Send()
    if not self:IsValid() then return end

    -- Get all class properties as a single table for
    -- the request function arguments.
    local args = {}
    for k, _ in pairs(self.requestProperties) do args[k] = self[k] end

    return GNIL.Http.SendRequest(args)
end

-- Setup the class const.
GNIL.Http.Classes = GNIL.Http.Classes or {}
GNIL.Http.Classes.Request = Request