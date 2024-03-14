
-- Completely forgot that middleclass has Mixin support.
-- This aims to provide a standardised interface, some
-- inspiration taken from the EventEmitter in javascript.

local function ensureEventsExists(class, index, eventName)
    if class.__event_callbacks == nil then class.__event_callbacks = {{}, {}, {{}, {}}} end
    if eventName and class.__event_callbacks[index][eventName:lower()] == nil then class.__event_callbacks[index][eventName:lower()] = {} end
end

local function doCallbacksExist(class, index, eventName)
    if class.__event_callbacks == nil then return false end
    if eventName then return class.__event_callbacks[index][eventName:lower()] != nil end
end

local function addCallback(class, index, key, callback)
    ensureEventsExists(class, index, key)

    -- If the key is nil, the index should be the 'all' table
    -- and the key should be the original index 'event/signal'.
    if key == nil then index, key = 3, tostring(index) end
    table.insert(class.__event_callbacks[index][key:lower()], callback)
end

local function clearCallbacks(class, index, key)

    -- If there is no index provided, reset the events table.
    if not index then
        class.__event_callbacks = nil
        ensureEventsExists(class)
    else

        -- If no key is provided, clear the entire indexed table.
        -- Also clear (All) listeners for the index.
        -- Otherwise, remove just the key provided.
        if key == nil then
            class.__event_callbacks[index] = {}
            class.__event_callbacks[3][index] = {}
        else
            class.__event_callbacks[index][key:lower()] = {}
        end
    end
end

local function getCallbacks(class, index, key)
    if not doCallbacksExist(class, index, key) then return {} end

    -- Kinda ugly lol.
    if not index then return class.__event_callbacks end
    if not key then return class.__event_callbacks[index] end
    return class.__event_callbacks[index][key:lower()]
end

local function callEventFunctions(class, key, ...)
    if not class then return nil end
    local function_name = "on" .. key:lower()

    -- Get class instance functions.
    local out
    if class.class == nil then
        out = class
    else
        out = class.class.__instanceDict
    end

    -- Find event functions.
    for k, v in pairs(out) do
        if k:lower() == function_name then

            -- Call event function.
            if not isfunction(v) then continue end
            local fn_out = class[k](class, ...)
            if fn_out != nil then return fn_out end
        end
    end
    return nil
end

local function callSignalListeners(class, signalName, ...)

    -- Call generic listeners.
    if not doCallbacksExist(class, 2, signalName) then return end
    for _, v in ipairs(class.__event_callbacks[2][signalName:lower()]) do
        v(...)
    end
    for _, v in ipairs(class.__event_callbacks[3][2]) do
        v(...)
    end
    return
end

---@alias EventsMixin.Callback fun(...: any): nil
---@class EventsMixin: middleclass
local EventsMixin = {

    ---Add a blocking event listener.
    ---@param self self
    ---@param eventName string
    ---@param callback EventsMixin.Callback
    AddEventListener = function(self, eventName, callback) return addCallback(self, 1, eventName, callback) end,

    ---Add a signal (passive) listener.
    ---@param self self
    ---@param signalName string
    ---@param callback EventsMixin.Callback
    AddSignalListener = function(self, signalName, callback) return addCallback(self, 2, signalName, callback) end,

    ---Clear all existing event listeners.
    ---@param self self
    ---@param eventName string
    ClearEventListeners = function(self, eventName) return clearCallbacks(self, 1, eventName) end,

    ---Clear all existing signal listeners.
    ---@param self self
    ---@param signalName string
    ClearSignalListeners = function(self, signalName) return clearCallbacks(self, 2, signalName) end,

    ---Clear all existing listeners.
    ---@param self self
    ClearAllListeners = function(self) return clearCallbacks(self) end,

    ---Get all existing event listeners.
    ---@param self self
    ---@param eventName? string
    ---@return table EventListeners
    GetEventListeners = function(self, eventName) return getCallbacks(self, 1, eventName) end,

    ---Get all existing signal listeners.
    ---@param self self
    ---@param signalName? string
    ---@return table SignalListeners
    GetSignalListeners = function(self, signalName) return getCallbacks(self, 2, signalName) end,

    ---Get all existing listeners (event + signal).
    ---@param self self
    ---@return table AllListeners
    GetAllListeners = function(self) return getCallbacks(self) end,

    ---Emit an event (recieved for every event listener until one returns a value, and all signal listeners).
    ---@param self self
    ---@param eventName string
    ---@param ... any
    ---@return any? EventResult
    EmitEvent = function(self, eventName, ...)
        assert(isstring(eventName), "Provided eventName must be a string")
        eventName = eventName:lower()

        -- Call the event function if there is one ("OnEventname")
        -- Also call signal for all event names.
        local fn_out = callEventFunctions(self, eventName, ...)
        callSignalListeners(self, eventName, ...)
        if fn_out != nil then return fn_out end

        -- Call generic listeners.
        if doCallbacksExist(self, 1, eventName) then
            for _, v in ipairs(self.__event_callbacks[1][eventName]) do
                local out = v(...)
                if out != nil then return out end
            end
        end

        -- Call the 'all' event callbacks. These are always second priority to listeners
        -- added directly to the class (TODO: may make a way to change this eventually).
        if doCallbacksExist(self) then
            for _, v in ipairs(self.__event_callbacks[3][1]) do
                local out = v(eventName, ...)
                if out != nil then return out end
            end
        end
        return nil
    end,

    ---Emit a signal (recieved by all signal listeners).
    ---@param self self
    ---@param signalName string
    ---@param ... any
    EmitSignal = function(self, signalName, ...)
        assert(isstring(signalName), "Provided signalName must be a string")

        -- Call signal function if there is one ("OnSignalName")
        callEventFunctions(self, signalName, ...)
        callSignalListeners(self, signalName, ...)
    end
}
return EventsMixin