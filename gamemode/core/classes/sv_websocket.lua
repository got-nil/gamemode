
---@class Websocket: EventsMixin
local Websocket = GNIL.Thirdparty.middleclass("Websocket"):IncludeMixin(GNIL.ClassMixins.Events)
ClassAccessorFunc(Websocket, {
    URL = {"url", FORCE_STRING}, ---@accessor string
    VerifyCert = {"verify_cert", FORCE_BOOL}, ---@accessor boolean
    RetryDelay = { ---@accessor number?
        var = "retry_delay",
        force = FORCE_NUMBER,
        nillable = true,
        validate = function(_, v)
            return v == nil or (isnumber(v) and v > 0)
        end
    }
})

-- TODO: Change to using a socket state (CONNECTED, CLOSED, OPENING, RECONNECTING)
-- That way we can just update/track a single variable instead of the
-- current __reconnecting, __opening etc.

--[[

    This is basically just a class wrapper around GWSockets.
    With these additional features:
        - Uses class event system so there can be multiple listeners.
        - Seperates connection failures from normal errors.
        - Automatically attempts connection retries.
        - Automatically loads gwsockets dll if not already loaded.
        - Prevent Disconnect event from being sent on initial connection failure.
        - Prevent Open from being ran when a connection is already being opened.
        - Provides a callback interface for Open to directly recieve connection state.
        - More efficient IsConnected implementation.

    Events:
        open (url: string) - Websocket about to be opened. (return false to block)
        write (message: string, original: Any) - Message about to be written. (return false to block)

    Signals:
        message (message: string) - Message recieved.
        error (errMessage: string) - Websocket error. (excluding connection failures)
        connectionfailure - Websocket failed to connect.
        connected - Websocket connection established.
        disconnected - Websocket connection closed.

--]]

local function ResolveOpenCallbacks(self, ...)
    for _, v in ipairs(self.__open_callbacks) do
        v(...)
    end
    self.__opening = false
    self.__open_callbacks = {}
end

local function GWSocketsExists(self)

    -- Attempt to require the sockets DLL.
    local success, errorMessage = GNIL.Utils.RequireDLL("gwsockets", "GWSockets")
    if not success then
        GNIL.log("Could not include required websocket module with error: " .. errorMessage, "error")
        self:EmitSignal("error", errorMessage) -- Emit error event.
        return false
    end
    return true
end

local function WebsocketReconnect(self, ws_state)

    local timerName = "gnil_ws_" .. self.__identifier
    local stopReconnecting = function()
        self.__reconnecting = false
        if timer.Exists(timerName) then
            timer.Remove(timerName)
        end
    end

    if ws_state then

        -- If theres no retry_delay, or we're already reconnecting ignore.
        if self.retry_delay == nil or self.__reconnecting then return end
        self.__reconnecting = true

        -- The websocket connection has terminated. Start a timer that
        -- runs every retry_delay to attempt a websocket connection.
        timer.Create(timerName, self.retry_delay, 0, function()

            -- Check that we're still reconnecting.
            if not (self and self.__reconnecting) then
                stopReconnecting()
                return
            end

            self:Open(function(open_state)

                -- Log the state from re-connection if successful.
                if open_state then
                    GNIL.log("Successfully re-connected to websocket '" .. self.url .. "'.", "debug")
                    stopReconnecting()
                end
            end)
        end)
    else

        -- The websocket connection has resumed. Remove the connection
        -- retry timer to prevent it from continuing to run.
        stopReconnecting()
    end
end

---@param url string
---@param verify_cert boolean
---@param retry_delay? number
function Websocket:Initialize(url, verify_cert, retry_delay)
    self.url = url
    self.verify_cert = verify_cert
    self.retry_delay = retry_delay or 15

    self.__opening = false
    self.__open_callbacks = {}
    self.__identifier = util.SHA256(GNIL.Utils.Random(12) .. (self.url or ""))
    self.__reconnecting = false
    self.__closed = false
    self.__connected = false

    self.__headers = {}
    self.__cookies = {}
end

function Websocket:StopRetrying() WebsocketReconnect(self, false) return self end
function Websocket:SetHeader(k, v) self.__headers[k] = v return self end
function Websocket:SetCookie(k, v) self.__cookies[k] = v return self end

---Open a websocket connection, running the callback with open result state.
---@param callback? fun(success: boolean, error_message?: string)
---@return self
function Websocket:Open(callback)

    -- Prevent function being called when a connection
    -- is already being opened (between Open and Connect/Disconnect)
    if self.__opening then
        if callback then table.insert(self.__open_callbacks, callback) end
        return self
    end

    -- Allow the websocket connection to be blocked by listeners.
    if self:EmitEvent("open", self.url) == false then
        if callback then callback(false, "Connection opening blocked by event.") end
        return self
    end

    -- Initialize the GWSocket connection.
    assert(callback == nil or isfunction(callback), "Provided callback argument must either be nil or a function")
    if not GWSocketsExists(self) then
        if callback != nil then ---@cast callback function
            callback(false, "Failed to load GWSockets module")
        end
        return self
    end

    ---@diagnostic disable-next-line Ignore GWSockets global warning.
    local socket = GWSockets.createWebSocket(self.url, Either(isbool(self.verify_cert), self.verify_cert, false))

    -- Add headers/cookies to the socket.
    for k, v in pairs(self.__headers) do socket:setHeader(k, v) end
    for k, v in pairs(self.__cookies) do socket:setCookie(k, v) end

    -- Forward socket callbacks to class events.
    socket.onError = function(_, errorMessage)

        -- Seperate connection failure errors from actual errors.
        if string.sub(string.lower(errorMessage), 1, 17) == "connection failed" then
            WebsocketReconnect(self, true)
            return self:EmitSignal("connectionfailure", errorMessage)
        end
        return self:EmitSignal("error", errorMessage)
    end
    socket.onDisconnected = function(_, ... )
        ResolveOpenCallbacks(self, false)

        -- Ignore disconnect events when the connection isn't already open. When
        -- the websocket fails to connect initially, it will send an error event
        -- followed by a disconnect, despite not actually disconnecting from anything.
        if not self.__connected then return end

        -- Set connection state and start reconnection timer if applicable.
        self.__connected = false
        if not self.__closed then
            WebsocketReconnect(self, true)
        end
        return self:EmitSignal("disconnected", ...)
    end
    socket.onConnected = function(_, ...)
        ResolveOpenCallbacks(self, true)

        -- Reset reconnection state and call connected event.
        self.__connected = true
        WebsocketReconnect(self, false)
        return self:EmitSignal("connected", ...)
    end
    socket.onMessage = function(_, ...) return self:EmitSignal("message", ...) end

    -- If there is already a socket, ensure the connection
    -- is closed before overwriting it (losing the reference).
    if self.__socket and self.__socket:isConnected() then
        self.__socket:closeNow()
    end

    -- Add open callback if one exists to be called on state change.
    if callback then table.insert(self.__open_callbacks, callback) end

    -- Open the socket connection.
    self.__closed = false
    self.__opening = true
    self.__socket = socket
    self.__socket:open()
    return self
end

---Write/Queue message to opened websocket connection.
---@param data string|table
---@return boolean
function Websocket:Write(data)

    -- If a table is provided, convert it to a string.
    local message = data
    if istable(message) then ---@cast message table
        message = util.TableToJSON(message)
    end ---@cast message string
    assert(isstring(message), "Provided message must be a string.")

    -- Emit an event when we're writing something to allow the message
    -- to be blocked by a listener directly on the websocket connection.
    if self:EmitEvent("write", message, data) == false then
        return false
    end

    self.__socket:write(message)
    return true
end

---@return self
local function safeClose(self, name)
    self.__closed = true
    self.__reconnecting = false

    local socket = self.__socket
    if socket then
        socket[name](socket)
    end
    return self
end

---Close websocket connection, sending any queued messages first.
---@return self
function Websocket:Close() return safeClose(self, "close") end

---Close websocket connnection immidiately, discarding any unsent queued messages.
---@return self
function Websocket:CloseNow() return safeClose(self, "closeNow") end

---Clear unsent messages queue.
---@return self
function Websocket:ClearQueue() if self.__socket then self.__socket:clearQueue() end return self end

---Check if the websocket is connected.
---@return boolean
function Websocket:IsConnected() return self.__connected and not self.__closed end

return Websocket