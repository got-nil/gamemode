-- Headers are used by Message as a standard header provider.
-- It allows for headers to be searched case-insensitive, while also
-- preserving the original defined casing for output.

local Headers = GNIL.Thirdparty.middleclass("Headers")
function Headers._From(headers)
    if istable(headers) && not table.IsSequential(headers) then
        return Headers:New(headers)
    end
end

function Headers:Initialize(headers)

    -- If a Headers instance is being passed into
    -- the constructor, just copy the headers across.
    if headers != nil && headers.class && headers.class.name == "Headers" then
        self._headers = headers._headers
        return
    end

    -- Each header has a lowercase key for searching,
    -- but contains the original key and value table.
    self._headers = {}

    -- If there is a headers array provided we should
    -- format it into the class headers array.
    if istable(headers) and not table.IsSequential(headers) then
        for k, v in pairs(headers) do
            self._headers[k:lower()] = {k, v}
        end
    end
end

-- Does the provided header name exist (is it nil).
function Headers:Exists(name)
    return self:Get(name) != nil
end

-- Get a header case insensitive.
function Headers:Get(name)
    local v = self._headers[name:lower()]
    if v != nil then return v[2] end
    return nil
end

-- When setting a header, the original name is stored
-- to preserve its original case (when setting).
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

-- Convert the headers to output headerlines (preserving original casing).
function Headers:ToLines()
    local lines = {}
    for _, v in pairs(self._headers) do
        table.insert(lines, v[1] .. ": " .. v[2]) -- Use original set case
    end
    return lines
end

-- If the query class is cast to a string, then we should build the
-- current query arguments into a URL safe string.
function Headers:__tostring()
    return table.concat(self:ToLines(), "\r\n")
end

-- Read the headerline and seperate header name from value.
local function parseHeaderline(headerline)

    -- Ensure that header values with a colon are preserved. If there
    -- is only one part then the header is malformed (missing seperator).
    local parts = string.Explode(":", headerline)
    if #parts == 1 then
        return nil, nil
    end

    -- Preserve colon characters in header value.
    local v = {}
    for i = 1, #parts - 1 do
        table.insert(v, parts[i + 1])
    end

    v = string.TrimLeft(#v == 1 && v[1] || table.concat(v, ":"))
    return parts[1], v
end

-- Parse a list of headerlines (strings) into a Headers instance. 
function Headers.FromHeaderlines(headerlines)

    local headers = {}
    for i, line in ipairs(headerlines) do
        local k, v = parseHeaderline(line)

        -- Ingore invalid header lines
        if k != nil then
            headers[k] = v
        end
    end

    -- Return an instance of Headers initialised with the collected
    -- headers from the headerlines.
    return Headers:New(headers)
end

GNIL.API.Classes.Headers = Headers