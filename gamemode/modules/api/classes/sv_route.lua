-- Route is used by the server router to define a 
-- specific route entity. It contains the route callback
-- and provides an interface for route matching.
-- Usually, routes should not be constructed manually, instead
-- they should be constructed by the router and provided back
-- to allow for additional route settings.

local MODULE, Route = MODULE, GNIL.Thirdparty.middleclass("Route")

function Route:Initialize(path, callback)
    self._id = GNIL.Utils.Random(8)

    -- Routes must be constructed with a valid path. The callback
    -- is not necessarily required as it can be supplied afterwards.
    if not isstring(path) then error("A Route must be constructed with a valid string path") end
    if not isfunction(callback) then error("A Route must be constructed with a valid callback function") end

    -- Parse the provided route and store since the path shouldnt change.
    self._path_parsed = GNIL.API.Parser.Route(path)
    if self._path_parsed == nil then
        error("Failed to parse Route path.")
    end

    self._parents = {}
    self._path = path
    self._callback = callback
    self._methods = nil -- Default to allowing all methods
end

-- Remove the route from all of its router parents.
function Route:Remove()
    for _, v in pairs(self._parents) do
        v:RemoveRoute(self)
    end
    self._parents = {}
end

function Route:ToTable() return {["path"] = self._path} end
function Route:GetPath() return self.path end

-- Set the callback that should be used when the route is called.
function Route:SetCallback(callback)
    if isfunction(callback) then
        self._callback = callback
    end
end

-- Set the accepted route methods. Each method is validated before
-- its stored (and is stored in UPPERCASE).
function Route:SetMethods(methods)
    local _methods = {}
    if isstring(methods) then _methods = {methods} end
    for _, v in ipairs(methods) do
        local method = string.upper(v)
        if GNIL.API.Message._validMethods[method] then
            _methods[method] = true
        end
    end
    self._methods = _methods
end

-- Used to match a set of route "fragments" (exploded route) against
-- the stored parsed route. Returns success: bool, arguments: table
function Route:_Match(fragments)

    -- Ensure there are the correct amount of required arguments.
    if #self._path_parsed != #fragments then
        return false, nil
    end

    -- Iterate over each argument, handling each arg type seperately.
    local arguments = {}
    for i, v in ipairs(self._path_parsed) do
        if v[1] == GNIL_API_ARGUMENT_STR then
            if fragments[i] != v[2] then
                return false, nil
            end
        elseif v[1] == GNIL_API_ARGUMENT_ARG then
            arguments[v[2]] = fragments[i]
        end
    end
    return true, arguments
end

local RouteCallbackTypeConverters = {
    [TYPE_FUNCTION] = function(v) return v end, -- for promises.
    [TYPE_NUMBER] = function(v) return GNIL.API.Responses.Empty(v) end,
    [TYPE_STRING] = function(v) return GNIL.API.Responses.Text(v) end,
    [TYPE_BOOL] = function(v) return GNIL.API.Responses.Empty(v && 200 || 500) end
}

-- Call the route callback with given arguments.
-- Returns either a Response instance or promise function.
function Route:_Call(request, arguments)

    -- Convert the provided arguments to their types.
    local converted_arguments = {}
    for _, v in ipairs(self._path_parsed) do
        if v[1] == GNIL_API_ARGUMENT_ARG then
            local converted_value = GNIL.API.Validators.Argument(v[3], arguments[v[2]])

            -- If the converted argument is nil, return a 400 response by default
            -- as the route argument could not be validated/converted.
            if converted_value == nil then
                return GNIL.API.Responses.Empty(400)
            end
            converted_arguments[v[2]] = converted_value
        end
    end
    arguments = converted_arguments

    -- Run the route in a protected call. Usually I'm against
    -- these, but in this case if there is an error in then no
    -- response is sent back until the proxy server times-out
    -- the request, which is slow obviously.
    local success, out = pcall(function()

        -- Set the args parameter on the request to the
        -- arguments, incase the route wants to access it
        -- that way instead.
        request.args = arguments
        return self._callback(request, arguments)
    end)

    if success then

        local type_converter = RouteCallbackTypeConverters[TypeID(out)]
        if type_converter then

            -- Run the type converter.
            out = type_converter(out)
        else

            -- If we're not handling type conversion ourselves, then make
            -- sure that the callback actually returns a Response instance.
            if not (out.IsInstanceOf and out:IsInstanceOf(GNIL.API.Response)) then
                MODULE:log("Route '" .. self:__tostring() .. "' did not return a Response value. Returning an empty 500 status.", "error")
                out = GNIL.API.Responses.Empty(500)
            end
        end
    else

        -- If the route callback errors, return an empty 500 response
        -- and print the error. TODO: Maybe make a better exception log?
        MODULE:log("Route '" .. self:__tostring() .. "' encountered an error in callback!", "error")
        ErrorNoHaltWithStack(out)
        out = GNIL.API.Responses.Empty(500)
    end
    return out
end

function Route:__tostring()
    return self._path
end

GNIL.API.Classes.Route = Route