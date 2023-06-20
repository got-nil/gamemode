local Response = GNIL.Thirdparty.middleclass("Response", GNIL.API.Message)

function Response:Initialize(status, body, headers)
    GNIL.API.Message.Initialize(self)
    self:Sets({
        ["status"] = status,
        ["body"] = body,
        ["headers"] = GNIL.API.Classes.To(headers, "Headers")
    })
end

-- The status is the only response specific attribute,
-- therefore there has to be its own getter/setter directly
-- on the request instead of the Message.
function Response:SetStatus(status) return self:Set("status", status) end
function Response:GetStatus() return self:Get("status", 200) end

-- Convert the response to a table.
function Response:ToTable()
    return {
        status = self:Get("status", 500),
        body = tostring(self.body or ""),
        headers = self.headers:ToTable()
    }
end

GNIL.API.Response = Response