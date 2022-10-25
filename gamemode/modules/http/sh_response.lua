local Response = GNIL.Thirdparty.middleclass("Response")
local ResponseBody = GNIL.Thirdparty.middleclass("ResponseBody")

-------- The ResponseBody is returned when using Response:GetBody --------
function ResponseBody:Initialize(body) self.body = body end
function ResponseBody:Read() return self.body end
function ResponseBody:FromJSON() return util.JSONToTable(self.body) end
function ResponseBody:Checksum() return util.CRC(self.body) end
function ResponseBody:__tostring() return self.body end
--------------------------------------------------------------------------

function Response:Initialize(request, data)
    self.request = request

    -- Put all the data in its class parameter.
    local responseProperties = {
        "code",
        "body",
        "headers"
    }
    for i, v in ipairs(responseProperties) do
        if data[i] == nil then continue
        else self[v] = data[i] end
    end
end

-- Basic attribute getting.
function Response:GetHeader(name) return self.headers[name] end
function Response:GetCode() return self.code == nil and 500 or self.code end
function Response:GetBody(raw)
    if raw then return self.body
    else return ResponseBody:New(self.body) end
end

-- Additional validation methods.
function Response:IsSuccessful() return self.code == 200 end
function Response:GetRequest() return GNIL.Http.GetRequest(self.request) end

-- Setup the class const.
GNIL.Http.Classes = GNIL.Http.Classes or {}
GNIL.Http.Classes.Response = Response