
---Headers are used by Message as a standard header provider.
---It allows for headers to be searched case-insensitive, while also
---preserving the original defined casing for output.
---@class API.Headers: middleclass
---@field _headers table<string, table<number, any>>
local Headers = GNIL.Thirdparty.middleclass("Headers")
function Headers._From(headers)
    if istable(headers) and not table.IsSequential(headers) then
        return Headers:New(headers)
    end
end

---@param headers? API.Headers|table<string, string>
function Headers:Initialize(headers)

    -- If a Headers instance is being passed into
    -- the constructor, just copy the headers across.
    if headers != nil and headers.class and headers.class.name == "Headers" then ---@cast headers API.Headers
        self._headers = headers._headers
        return
    end

    -- Each header has a lowercase key for searching,
    -- but contains the original key and value table.
    self._headers = {}

    -- If there is a headers array provided we should
    -- format it into the class headers array.
    if istable(headers) then ---@cast headers table<string, string>
        if table.IsSequential(headers) then
            error("Invalid provided headers table, must be associative array.")
        end
        for k, v in pairs(headers) do
            self._headers[k:lower()] = {k, v}
        end
    end
end

---Does the provided header name exist (is it nil).
---@param name string
---@return boolean
function Headers:Exists(name)
    return self:Get(name) != nil
end

---Get a header case insensitive.
---@param name string
---@return any?
function Headers:Get(name)
    local v = self._headers[name:lower()]
    if v != nil then return v[2] end
    return nil
end

---When setting a header, the original name is stored
---to preserve its original case (when setting).
---@param name string
---@param value any
function Headers:Set(name, value)
    self._headers[name:lower()] = {name, value}
end

-- Get all headers, default to preserving the original
-- set case. If lowercase_names is true, keys are lowercase.
function Headers:ToTable() return self:GetAll() end
function Headers:GetAll(lowercase_names)
    if not isbool(lowercase_names) then
        lowercase_names = false
    end

    local out = {}
    for k, v in pairs(self._headers) do
        out[lowercase_names && k || v[1]] = v[2]
    end
    return out
end

---Convert the headers to output headerlines (preserving original casing).
---@return string[]
function Headers:ToLines()
    local lines = {}
    for _, v in pairs(self._headers) do
        table.insert(lines, v[1] .. ": " .. v[2]) -- Use original set case
    end
    return lines
end

---If the query class is cast to a string, then we should build the
---current query arguments into a URL safe string.
function Headers:__tostring()
    return table.concat(self:ToLines(), "\r\n")
end

GNIL.API.Classes.Headers = Headers