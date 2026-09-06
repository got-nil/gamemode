
---@class ModuleExtensions.api: BaseExtension
local APIExtension = GNIL.Thirdparty.middleclass("APIExtension", GNIL.Classes.Extension)

--[[

    Using the APIExtension on a Module allows for routes
    to be directly associated with the active module itself.

    This means that when the module is unloaded (or refreshed)
    all routes can be removed. Using the API interface directly
    means that each individual Module would have to handle its
    own API unloading etc.

--]]

------------------------------------------------------------------------------
-- These are events called by the parent module.
-- When loaded, setup the routes table (if not already).
-- When unloaded, remove all routes associated with module.

function APIExtension:Initialize(moduleInstance)
    GNIL.Classes.Extension:Initialize(self, moduleInstance)

    if self._routes == nil then self._routes = {} else self:RemoveAllRoutes() end
    self._prefix = "/modules/" .. moduleInstance._module_name
end

-- When being loaded or unloaded, clear all routes.
function APIExtension:OnUnload() self:RemoveAllRoutes() end

------------------------------------------------------------------------------
-- Route prefixes setter/getter.

---Set the route prefix for the module. By default this is `modules/<module_name>`.
---@param prefix any
function APIExtension:SetRoutePrefix(prefix)
    assert(isstring(prefix), "Provided route prefix must be a string.")

    -- Remove terminating slashes (since we concat our own slash anyway).
    if string.sub(prefix, #prefix) == "/" then
        prefix = string.sub(prefix, 1, #prefix - 1)
    end
    self._prefix = prefix
end

function APIExtension:GetRoutePrefix()
    return self._prefix
end

------------------------------------------------------------------------------

---Add a created API route to the Module and the router.
---@param route API.Route
---@return API.Route
function APIExtension:AddRoute(route)
    table.insert(self._routes, route)
    return route
end

function APIExtension:RemoveAllRoutes()
    if self._routes == nil then return end
    for _, v in ipairs(self._routes) do
        v:Remove()
    end
    self._routes = {}
end

function APIExtension:GetRoutes()
    if self._routes == nil then return {} end
    return self._routes
end

-------------------------------------------------
-- Method aliases.

local function createRouteAlias(self, method, route, callback)
    return self:AddRoute(
        GNIL.API.Routes[method](self._prefix .. "/" .. GNIL.API.URL.RemoveStartingSlash(route), callback)
    )
end

---Create a route that accepts POST requests. Adds created route to the global router.
---@param route string
---@param callback API.Route.Callback
---@return API.Route
function APIExtension:Post(route, callback) return createRouteAlias(self, "Post", route, callback) end

---Create a route that accepts GET requests. Adds created route to the global router.
---@param route string
---@param callback API.Route.Callback
---@return API.Route
function APIExtension:Get(route, callback) return createRouteAlias(self, "Get", route, callback) end

---Create a route that accepts PUT requests. Adds created route to the global router.
---@param route string
---@param callback API.Route.Callback
---@return API.Route
function APIExtension:Put(route, callback) return createRouteAlias(self, "Put", route, callback) end

---Create a route that accepts PATCH requests. Adds created route to the global router.
---@param route string
---@param callback API.Route.Callback
---@return API.Route
function APIExtension:Patch(route, callback) return createRouteAlias(self, "Patch", route, callback) end

---Create a route that accepts DELETE requests. Adds created route to the global router.
---@param route string
---@param callback API.Route.Callback
---@return API.Route
function APIExtension:Delete(route, callback) return createRouteAlias(self, "Delete", route, callback) end

---Create a route that accepts any methods. Adds created route to the global router.
---@param route string
---@param callback API.Route.Callback
---@return API.Route
function APIExtension:Create(route, callback) return createRouteAlias(self, "Create", route, callback) end

---Add a route that accepts any methods. Adds created route to the global router.
---@param route string
---@param callback API.Route.Callback
---@return API.Route
function APIExtension:Add(route, callback) return createRouteAlias(self, "Add", route, callback) end

-------------------------------------------------

-- Add the extension class to Modules handler.
GNIL.Modules.Extensions.Add("api", APIExtension)