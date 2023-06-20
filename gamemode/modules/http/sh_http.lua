MODULE, GNIL.Http = MODULE, GNIL.Http or {
    ["_driver"] = http,
    ["_loaded"] = false
}

-- Allow the table to be called as an alias to send request.
setmetatable(GNIL.Http, {
    __call = function(_, ...) return GNIL.Http.SendRequest(...) end,
})

-- Only trust the server!
if SERVER then 
        
    -- Support both reqwest and CHTTP. (Prefer reqwest).
    for possible_driver, const in pairs({["reqwest"] = "reqwest", ["chttp"] = "CHTTP"}) do
        if GNIL.Utils.IsInstalled(possible_driver) then
            require(possible_driver)
            
            -- Verify that the driver was loaded correctly.
            if not _G[const] then
                MODULE:log("Despite HTTP driver '" .. possible_driver .. "' existing, it failed to load.", "error")
            else
                GNIL.Http._driver = _G[const]
                MODULE:log("Successfully loaded HTTP driver '" .. possible_driver .. "'.", "debug")
                break
            end
        else
            MODULE:log("Missing optional HTTP driver '" .. possible_driver .. "'", "debug")
        end
    end
end

-- Validate and structure raw arguments into a table that can be
-- used to create HTTPRequest structures or a Request instance.
local function _getArgumentsAsTable(...)
    local args = {...}

    -- Get the arguments based on the parameter provided format.
    local arguments = {}
    if #args == 1 and istable(args[1]) and not table.IsSequential(args[1]) then
        -- Single table options.
        arguments = args[1]
    else
        -- Standard parameters.
        local parameters = {
            "method",
            "url",
            "body",
            "headers",
            "callback"
        }
        for i, v in ipairs(args) do
            arguments[parameters[i]] = v
        end
    end

    -- Validate each parameter against its validator before continuing
    -- with sending the request.
    local parameterValidators = {
        ["method"] = function(method)
            if method == nil then return false, method end
            method = string.upper(method)
            return table.HasValue({"GET", "POST", "DELETE", "PUT", "OPTIONS", "HEAD"}, method), method
        end,
        ["url"] = TYPE_STRING, -- trust them
        ["query"] = TYPE_TABLE, -- query table arguments
        ["body"] = TYPE_STRING, -- nil or a string
        ["headers"] = function(headers)
            if headers == nil then return true, {} end

            if not istable(headers) or              -- If there are headers, it must be a table
               table.IsSequential(headers) then      -- The table must be associative
                    return false, {}
            end

            -- Convert the header keys to lowerase for searching.
            local lower_header_keys = {}
            for k, v in pairs(headers) do lower_header_keys[k:lower()] = v end

            return true, lower_header_keys
        end,
        ["callback"] = function(callback) return isfunction(callback), callback end, -- nil or a function
        ["type"] = function(ctype) return ctype == nil or isstring(ctype), ctype end
    }

    for k, v in pairs(parameterValidators) do
        local validatorFn = parameterValidators[k]
        if isfunction(validatorFn) then
            local success, v = validatorFn(arguments[k])
            if not success then
                MODULE:log("Parameter validator function for '" .. k .. "' marked the request as invalid.", "warning")
                return nil
            end
            
            -- Functions can change the parameter value.
            arguments[k] = v
        else

            -- If it defines a TYPE_ENUM instead of a function, then
            -- the parameter should also accept nil types.
            if arguments[k] == nil then continue end
            if TypeID(arguments[k]) != v then
                MODULE:log("Parameter '" .. k .. "' requires type '" .. v .. "' whereas the provided type for the parameter is '" .. TypeID(arguments[k]) .. "'", "warning")
                return nil
            end
        end
    end
    return arguments
end

/*

    Request functions accept two different parameter layouts:
        1: Key value arguments. Arguments can be provided as single table
           such as {["url"] = "https://google.com", ["method"] = "GET"}
            
        2: Standard parameters in the following order:
            - method
            - url
            - body
            - headers
            - callback

*/

-- Create a new request instance with whatever arguments are provided.
function GNIL.Http.CreateRequest(...) return GNIL.Http.Classes.Request:New(...) end

-- Convert a request table structure into an initialised Request
-- since this casts the table to the request, it must be fully valid.
function GNIL.Http.ToRequest(...)
    local arguments = _getArgumentsAsTable(...)
    if arguments == nil then return end
    return GNIL.Http.Classes.Request:New(arguments)
end

-- Send the request, validating the request structure. Convert the arguments
-- into the HTTPRequest structure.
function GNIL.Http.SendRequest(...)
    local arguments = _getArgumentsAsTable(...)
    if arguments == nil then return end

    -- Add query arguments to the URL.
    if arguments["query"] then
        local query_string = "?"
        for k, v in pairs(arguments["query"]) do
            query_string = query_string .. (k .. "=" .. v) .. "&"
        end
        
        -- Remove trailing &
        query_string = string.sub(query_string, 0, -2)
        arguments["url"] = arguments["url"] .. query_string
    end

    -- If there is a content type provided and no type, use that.
    if arguments["type"] == nil and arguments["headers"]["content-type"] != nil then
        arguments["type"] = arguments["headers"]["content-type"]
    end

    -- Create the actual request structure from the
    -- validated/structured table.
    local httpStruct = HTTP({
        ["failed"] = function(...)
            
            -- Reqwests provides an additional/better error message
            -- as the second argument. Therefore we should always use
            -- the last provided argument as the reason (supports both
            -- driver methods).
            local args = {...}
            arguments["callback"](false, args[#args])
        end,
        ["success"] = function(...)
            arguments["callback"](true, GNIL.Http.Classes.Response:New(arguments, {...}))
        end,
        ["method"] = arguments["method"],
        ["url"] = arguments["url"],
        ["headers"] = arguments["headers"],
        ["body"] = arguments["body"],
        ["type"] = arguments["type"]
    })
    
    -- Create the actual request.
    GNIL.Http._driver(httpStruct)
end

-- Only run this once, not for lua refreshes.
if not GNIL.Http["_loaded"] then

    -- Since ISteamHTTP loads relatively late in the cycle, this hook should
    -- allow us to send requests as soon as its loaded (on the first think).
    hook.Add("Think", "GNIL.Http.HTTPLoaded", function()
        hook.Run("FirstThink") -- Alias for non HTTP things.
        hook.Run("HTTPLoaded")
        hook.Remove("Think", "GNIL.Http.HTTPLoaded")

        GNIL.Http["_loaded"] = true
    end)
end