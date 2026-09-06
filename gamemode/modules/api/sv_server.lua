
---@class API.Server: middleclass
---@field _name string
---@field _router API.Router
---@field _ws API.Websocket
local Server = GNIL.Thirdparty.middleclass("Server")

-- Actual server instance.
function Server:Initialize(name, options)
    self._name = name
    self._router = GNIL.API.Router:New()
    self._ws = GNIL.API.Websocket:New(self)
end

function Server:IsConnected() return self._ws:IsConnected() end
function Server:Close() return self._ws:Close() end
function Server:CloseNow() return self._ws:CloseNow() end
function Server:__tostring() return self._name end

---Connect to the server websocket.
---@param callback fun(success: boolean, error_message?: string)
---@return boolean
function Server:Connect(callback)
    if self._ws:IsConnected() then return false end
    self._ws:Open(callback)
    return true
end

---Alias to router call, returns response.
function Server:Call(...) return self._router:Call(...) end

GNIL.API.Server = Server