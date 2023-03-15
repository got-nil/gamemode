GNIL.Http = {
    ["_driver"] = HTTP
}

-- Allow the table to be called as an alias to send request.
setmetatable(GNIL.Http, {
    __call = function(_, ...) return GNIL.Http.SendRequest(...) end,
})

-- If we're on the server we should always attempt to use the
-- chttp module instead of the builtin.
if SERVER and pcall(require, "chttp") and CHTTP != nil then
    GNIL.log("Using CHTTP http driver instead of default", "debug")
    GNIL.Http._driver = CHTTP
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
        ["body"] = TYPE_STRING, -- nil or a string
        ["headers"] = function(headers)
            if headers == nil then return true, {} end

            if header == nil or                     -- Allow no headers
               not istable(headers) or              -- If there are headers, it must be a table
               table.IsSequential(header) then      -- The table must be associative
                    return false, {}
            end

            -- Convert the header keys to lowerase for searching.
            local lower_header_keys = {}
            for k, v in pairs(headers) do lower_header_keys[k:lower()] = v end

            return true, lower_header_keys
        end,
        ["callback"] = function(callback) return isfunction(callback), callback end -- nil or a function
    }

    for k, v in pairs(parameterValidators) do
        local validatorFn = parameterValidators[k]
        if isfunction(validatorFn) then
            local success, v = validatorFn(arguments[k])
            if not success then
                GNIL.log("Parameter validator function for '" .. k .. "' marked the request as invalid.", "warning")
                return nil
            end
            
            -- Functions can change the parameter value.
            arguments[k] = v
        else

            -- If it defines a TYPE_ENUM instead of a function, then
            -- the parameter should also accept nil types.
            if arguments[k] == nil then continue end
            if TypeID(arguments[k]) != v then
                GNIL.log("Parameter '" .. k .. "' requires type '" .. v .. "' whereas the provided type for the parameter is '" .. TypeID(arguments[k]) .. "'", "warning")
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

    -- Create the actual request structure from the
    -- validated/structured table.
    local httpStruct = HTTP({
        ["failed"] = function(reason)
            GNIL.log("Failed to send request to " .. arguments["url"], "debug")
            arguments["callback"](false, reason)
        end,
        ["success"] = function(...)
            GNIL.log("Successfully sent request to " .. arguments["url"], "debug")
            arguments["callback"](true, GNIL.Http.Classes.Response:New(arguments, {...}))
        end,
        ["method"] = arguments["method"],
        ["url"] = arguments["url"],
        ["headers"] = arguments["headers"],
        ["body"] = arguments["body"],
        ["type"] = arguments["headers"]["content-type"] and arguments["headers"]["content-type"]
    })
    
    -- Create the actual request.
    GNIL.Http._driver(httpStruct)
end