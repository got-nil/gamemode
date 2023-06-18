
local MODULE, Websocket = MODULE, GNIL.Thirdparty.middleclass("Websocket")

function Websocket:Initialize(server)
    self._server = server
    self._connected = false
    self._socket = false

    self._connect_callbacks = {}
    self._request_partials = {}
end

local operations = {
    ["request"] = function(ws, header, body)

        -- If there is a content length in the header and no body
        -- then we must wait until the second body message is recieved.
        -- If a body is provided in the call, ignore.
        if header["l"] > 0 and not body then
            ws._request_partials[header["i"]] = header
            return
        end
        if body == nil then body = "" end

        -- The body length should match what the header reported.
        if body and #body != header["l"] then
            MODULE:log("Request body size mismatch. Expected '" .. header["l"] .. "', got '" .. #body .. "'", "warning")
        end

        -- Construct the request.
        local request = GNIL.API.Request.FromTable({
            method      = header["m"],
            path        = header["p"],
            query       = header["q"],
            body        = body,
            headers     = header["h"],
            remote_addr = header["r"]
        })

        -- Call the request on the server router, writing
        -- the returned response back to the websocket connection.
        ws:_WriteResponse(
            header["i"],
            ws._server:Call(request)
        )
    end
}

-- Write provided operation to socket.
function Websocket:_WriteOperation(name, data)
    data["o"] = name
    self._socket:write("#" .. util.TableToJSON(data))
end

-- Write response operation header + body to socket.
function Websocket:_WriteResponse(request_id, response)    
    local data = response:ToTable()
    
    -- Send response operation (header).
    self:_WriteOperation("response", {
        s = data.status,
        l = #data.body,
        h = data.headers,
        i = request_id
    })

    -- If there is a response body, write it as a seperate
    -- message with the body message prefix '@'
    if #data.body > 0 then
        self._socket:write("@" .. request_id .. data.body)
    end
end

-- Connection state.
function Websocket:IsConnected() return self._connected end
function Websocket:_OnConnected() self:_Callback(true) self._connected = true end
function Websocket:_OnDisconnected() self:_Callback(false) self._connected = false end

function Websocket:_OnError(err)
    MODULE:log("Server '" .. self._server._name .. "' websocket error: " .. err, "error")
end
function Websocket:_OnMessage(msg)

    -- Get the message type (# operation, @ body).
    local message_type = string.sub(msg, 1, 1)
    if message_type != "#" and message_type != "@" then
        MODULE:log("Invalid message recieved from upstream server.", "warning")
        return
    end
    
    if message_type == "#" then

        -- Parse the operation data.
        local data = util.JSONToTable(string.sub(msg, 2))
        if not data then
            MODULE:log("Upstream sent an invalid/broken operation.", "warning")
            return
        end

        -- Call operation handler if there is one.
        if operations[data["o"]] then
            operations[data["o"]](self, data)
        end
    else
        
        -- Read message request_id and body.
        local request_id = string.sub(msg, 2, 9)
        local body = string.sub(msg, 10)
        MODULE:log("Recieved request body for '" .. request_id .. "', length: '" .. #body .. "'", "debug")
    
        -- Get the original request header from partials.
        local header = self._request_partials[request_id]
        if not header then
            MODULE:log("Recieved request body for unknown message ID '" .. request_id .. "'.", "warning")
            return
        end

        -- Call the request handler with header and body.
        self._request_partials[request_id] = nil
        operations["request"](self, header, body)
    end
end

-- Open the websocket connection, calling the provided callback
-- when connected or on error (connection status).
function Websocket:OpenCallback(callback)
    assert(isfunction(callback), "Provided callback must be a function.")

    -- If already connected, call as-if we've just connected.
    if self._connected then
        return callback(true)
    end

    table.insert(self._connect_callbacks, callback)
    self:Open()
end

-- Call all queued callbacks with state and then clear.
function Websocket:_Callback(state)
    MODULE:log("Websocket state '" .. self._server._name .. "': " .. (state && "Connected" || "Disconnected"), "debug")
    for _, v in ipairs(self._connect_callbacks) do
        v(state)
    end
    self._connect_callbacks = {}
end

-- Open websocket connection.
function Websocket:Open()

    -- Prevent double connection attempts.
    if self._connected then
        MODULE:log("Cannot open server '" .. self._server._name .. "' connection as it's already open!", "warning")
        return
    end

    local conf = MODULE:Config()
    local socket = GWSockets.createWebSocket(
        conf:Get("ws_host"),
        conf:Get("ws_verify_cert", true)
    )

    -- Set server identifier and authorization token.
    socket:setHeader("GNIL-S", self._server._name)
    socket:setHeader("GNIL-T", conf:Get("ws_token"))

    -- Set callbacks (drop socket self reference as its stored).
    socket.onError = function(_, ...) return self:_OnError(...) end
    socket.onMessage = function(_, ...) return self:_OnMessage(...) end
    socket.onConnected = function(_, ...) return self:_OnConnected(...) end
    socket.onDisconnected = function(_, ...) return self:_OnDisconnected(...) end

    -- Open the socket connection.
    MODULE:log("Opening websocket connection for server '" .. self._server._name .. "'.", "debug")
    self._socket = socket
    self._socket:open()
end

GNIL.API.Websocket = Websocket