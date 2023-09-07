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

-- Basically just alias a bunch of functions from the global
-- router. Whenever a route is created, also add it locally.
for _, v in ipairs({"Post", "Get", "Put", "Patch", "Delete", "Create", "Add"}) do
    APIExtension[v] = function(self, route, callback)
        return self:AddRoute(
            GNIL.API.Routes[v](self._prefix .. "/" .. GNIL.API.URL.RemoveStartingSlash(route), callback)
        )
    end
end

-- Add the extension class to Modules handler.
GNIL.ModuleExtensions.Add("api", APIExtension)