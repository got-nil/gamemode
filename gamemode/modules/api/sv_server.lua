local MODULE, Server = MODULE, GNIL.Thirdparty.middleclass("Server")

-- Actual server instance.
function Server:Initialize(name, options)
    self._name = name
    self._router = GNIL.API.Router:New()
    self._ws = GNIL.API.Websocket:New(self)
end

function Server:IsConnected() return self._ws:IsConnected() end
function Server:__tostring() return self._name end

function Server:Connect(callback)
    if self._ws:IsConnected() then return false end
    self._ws[callback == nil && "Open" || "OpenCallback"](self._ws, callback)
end

-- Alias to router call, returns response.
function Server:Call(...) return self._router:Call(...) end

GNIL.API.Server = Server