-- Used to parse and provide an interface to a raw body
-- plaintext (as it comes in a HTTP request).

local MODULE, Body = MODULE, GNIL.Thirdparty.middleclass("Body")
function Body._From(body)
    if isstring(body) then
        return Body:New(body)
    end
end

function Body:Initialize(body_raw)
    self._body = body_raw
    self._plaintext = true

    -- Empty defaults.
    self._post = {}
    self._files = {}
end

function Body:Raw() return self._body end
function Body:ToTable() return self.plaintext && self._body || self:GetAll() end
function Body:GetAll() return self._post end
function Body:__tostring() return self._body end

-- Parse the raw body into post arguments and files.
function Body:Parse(content_type)

    -- Parse/convert for specific content types.
    -- Returns: {post_data}, {files_data}
    local content_type_parsers = {
        ["multipart/form-data"] = function(body, content_type)
            local parsed, out = GNIL.Thirdparty.formdata(body, content_type), {{}, {}}
            for k, v in pairs(parsed) do
                out[isstring(v) && 1 || 2][k] = v
            end
            return out[1], out[2]
        end,
        ["application/json"] = function(body)
            return util.JSONToTable(body), nil
        end,
        ["application/x-www-form-urlencoded"] = function(body)
            local out = {}
            for _, v in ipairs(string.Explode("&", body)) do
                local parts = string.Explode("=", v)
                if #parts != 2 then return nil end
                out[GNIL.API.URL.Decode(parts[1])] = GNIL.API.URL.Decode(parts[2])
            end
            return out, nil
        end
    }

    -- Find the content type key in the provided content type header.
    -- We can't check for exact matches as form data headers also
    -- contain boundary data (boundary markers).
    for k, v in pairs(content_type_parsers) do
        if string.sub(content_type, 1, #k) == k then

            local post, files = v(self._body, content_type)

            -- The files can be nil (in case of anything other than formdata)
            -- however if the post is nil then the conversion has failed.
            if post == nil then
                MODULE:log("Failed to parse provided body for content type '" .. k .. "'", "debug")
                return
            end

            -- Set the class variables once parsed.
            self._post = post
            self._files = files
            self._plaintext = false
            return
        end
    end
end

-- Get a post key by string, fallback to default if
-- it doesn't exist. (The same getter as all other classes).
function Body:Get(key, default)
    local v = self._post[key]
    if v == nil then return default end
    return v
end

-- Get a provided file interface from key.
function Body:File(key)
    return nil
end

GNIL.API.Classes.Body = Body