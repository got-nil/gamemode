-- Router

local MODULE, Router = MODULE, GNIL.Thirdparty.middleclass("Router")

function Router:Initialize()
    self._id = GNIL.Utils.Random(8)
    self._routes = {}
end

-- Add a route to the router, must be type of Route.
function Router:AddRoute(route)
    if not GNIL.API.Classes.Is(route, "Route") then
        return false
    end

    -- Add the router as a parent to the route. This allows
    -- it to be automatically removed from the routers when
    -- the route is removed/disabled.
    if not route._parents[self._id] then
        route._parents[self._id] = self
    end

    table.insert(self._routes, route)
    return true
end

-- Remove the provided route instance from the router.
function Router:RemoveRoute(route)
    local out, removed = {}, false
    for _, v in ipairs(self._routes) do
        if v._id == route._id then
            MODULE:log("Router '" .. self._id .. "' removed route '" .. route._path .. "'.", "debug")
            removed = true
        else
            table.insert(out, v)
        end
    end
    self._routes = out
    return removed
end

-- Create a route and add it to the router (by default).
function Router:Create(route, callback, auto_add)
    if auto_add == nil then auto_add = true end

    local route = GNIL.API.Classes.Route:New(route, callback)
    if auto_add then
        self:AddRoute(route)
    end
    return route
end

-- Create a method with given specific methods.
function Router:_CreateWithMethods(route, callback, methods)
    local route = self:Create(route, callback)
    route:SetMethods(methods)
    return route
end

-- Alias methods to create a route with specific methods set.
function Router:Post(route, callback) return self:_CreateWithMethods(route, callback, {"POST"}) end
function Router:Get(route, callback) return self:_CreateWithMethods(route, callback, {"GET"}) end
function Router:Put(route, callback) return self:_CreateWithMethods(route, callback, {"PUT"}) end
function Router:Patch(route, callback) return self:_CreateWithMethods(route, callback, {"PATCH"}) end
function Router:Delete(route, callback) return self:_CreateWithMethods(route, callback, {"DELETE"}) end

-- Get matching routes that should be used for the given raw route string.
function Router:GetRoutes(raw_route)
    raw_route = GNIL.API.URL.RemoveStartingSlash(raw_route)
    local routes, fragments = {}, {}

    -- FIX: Ignore empty fragments. This is usually the result of incorrect
    -- URL formatting such as a trailing slash. This should really be upstream.
    for _, v in ipairs(string.Explode("/", raw_route)) do
        if v != "" then table.insert(fragments, v) end
    end

    for _, v in ipairs(self._routes) do
        local matched, arguments = v:_Match(fragments)
        if matched then
            table.insert(routes, {
                v,
                arguments
            })
        end
    end

    -- If there was no match found, return nil.
    if #routes == 0 then
        return nil
    end
    return routes
end

-- Call the router with a given request. This will find the most suitable
-- route and then call it with the request and argument data to return a response.
function Router:Call(request, callback)

    -- Return the respond wrapper to ensure that responses
    -- are sent if there is a callback set or not.
    local respond = function(response)
        if callback then callback(response) else return response end
    end

    -- Parse provided path to find valid request routes.
    local routes = self:GetRoutes(request.path)
    if routes == nil then
        return respond(GNIL.API.Responses.Empty(404))
    end

    -- Get all routes with a matching from the request.
    local validMethodRoutes = {}
    for _, v in ipairs(routes) do
        if v[1]._methods == nil or v[1]._methods[request.method] then
            table.insert(validMethodRoutes, v)
        end
    end

    -- If there are no valid method routes we should return a 405
    -- method not allowed error instead, since the route does exist.
    if #validMethodRoutes == 0 then
        return respond(GNIL.API.Responses.Empty(405))
    end

    -- Call the first (most suitable) found route to get response/promise.
    local route = validMethodRoutes[1][1]
    local out = route:_Call(request, validMethodRoutes[1][2])

    -- Is route callback/promise?
    if isfunction(out) then

        -- If the route returns a function (delayed response) there must be
        -- a callback provided otherwise there's no way to get the response.
        if not callback then
            MODULE:log("The requested route '" .. route:GetPath() .. "' returned a function, but the router was not called with a callback.", "error")
            return respond(GNIL.API.Responses.Empty(500))
        end

        -- Provide the request promise with the callback.
        local already_responded = false
        out(function(...)

            -- Prevent something from calling with response more than once.
            if already_responded then return end
            already_responded = true

            return callback(...)
        end)
        return
    end

    -- If a callback is set, provide it with the request instead of returning
    -- to ensure that the interface remains the same irregardless of request out.
    return respond(out)
end

-- Routes is a reference to the global server router.
GNIL.API.Routes = {

    -- HTTP Method Verbs
    Post    = function(...) return GNIL.API._GLOBAL_SERVER._router:Post(...) end,
    Get     = function(...) return GNIL.API._GLOBAL_SERVER._router:Get(...) end,
    Put     = function(...) return GNIL.API._GLOBAL_SERVER._router:Put(...) end,
    Patch   = function(...) return GNIL.API._GLOBAL_SERVER._router:Patch(...) end,
    Delete  = function(...) return GNIL.API._GLOBAL_SERVER._router:Delete(...) end,

    -- Non method specific route alias
    Add     = function(...) return GNIL.API._GLOBAL_SERVER._router:Create(...) end,
    Create  = function(...) return GNIL.API._GLOBAL_SERVER._router:Create(...) end,
}
GNIL.API.Router = Router