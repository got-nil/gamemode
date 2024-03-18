
---@class API.Request: API.Message
---@field method string Request HTTP method.
---@field path string Request URL path.
---@field args table<string, any> Request arguments.
---@field query? API.Query Request URL query string.
---@field body? API.Body Request body.
---@field headers? API.Headers Request headers.
---@field remote_addr string Request remote address.
local Request = GNIL.Thirdparty.middleclass("Request", GNIL.API.Message)

function Request:Initialize(method, path, query, body, headers, remote_addr)
    GNIL.API.Message.Initialize(self)
    self:Sets({
        ["method"] = method,
        ["path"] = path,
        ["query"] = GNIL.API.Classes.To(query, "Query"),
        ["body"] = GNIL.API.Classes.To(body, "Body"),
        ["headers"] = GNIL.API.Classes.To(headers, "Headers"),
        ["remote_addr"] = remote_addr
    })

    -- Parse the request body if there is one (although there should be).
    if self.body and self.headers:Exists("Content-Type") then
        self.body:Parse(self.headers:Get("Content-Type"))
    end
end

---Get request remote address (only for real requests).
function Request:GetRemoteAddr() return self:Get("remote_addr") end
Request.GetIP = Request.GetRemoteAddr -- Alias

-- Path is request specific, therefore the getter/setter cannot
-- be implemented by Message (and instead must be here).
function Request:SetPath(path) self.path = path return true end
function Request:GetPath() return self.path end

-- Query args interface.
function Request:GetArgs() return self.query:GetAll() end
function Request:SetArg(arg) return self.query:Set(arg) end
function Request:GetArg(arg) return self.query:Get(arg) end
function Request:BuildArgs() return self.query:Build() end
function Request:ArgExists(arg) return self.query:Exists(arg) end
function Request:IsArgTrue(arg) return self.query:IsTrue(arg) end
function Request:IsArgFalse(arg) return self.query:IsFalse(arg) end

---From parsed table structure.
---@param data table<string, any>
---@return self? Request
function Request.FromTable(data)

    -- Ensure all required arguments are present.
    -- BODY IS NOT REQUIRED, AS IT COULD BE NIL.
    for _, v in ipairs({"method", "path", "headers"}) do
        if data[v] == nil then return nil end
    end

    -- Construct simply in argument order.
    return Request:New(
        data["method"],
        data["path"],
        data["query"],
        data["body"],
        data["headers"],
        data["remote_addr"]
    )
end

---Convert the request to a table for class exporting?
---@return table<string, any> RequestTable
function Request:ToTable()
    return {
        method = self:Get("method", false),
        path = self:Get("path", false),
        remote_addr = self:Get("remote_addr", false),
        query = self.query:ToTable(),
        headers = self.headers:ToTable(),
        body_len = #self.body:Raw()
    }
end

GNIL.API.Request = Request