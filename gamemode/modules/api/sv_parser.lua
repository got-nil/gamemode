-- Used to parse various elements of the raw HTTP message.
local MODULE = MODULE
GNIL.API.Parser = GNIL.API.Parser or {}

-- Decode query value, replacing spaces with a '+' seperator.
local function decodeValue(str)
	return GNIL.API.URL.Decode(str:gsub("+", " "))
end

---Parse provided query string into a key value table. If there is
---no seperator provided, the default '&' is used.
---@param str string
---@param sep? string
---@return table QueryValues
function GNIL.API.Parser.Query(str, sep)
	if not sep then sep = "&" end
	local values = {}
	for key,val in str:gmatch(string.format("([^%q=]+)(=*[^%q=]*)", sep, sep)) do
		local key = decodeValue(key)
		local keys = {}
		key = key:gsub("%[([^%]]*)%]", function(v)
				-- Extract keys between balanced brackets
				if string.find(v, "^-?%d+$") then
					v = tonumber(v)
				else
					v = decodeValue(v)
				end
				table.insert(keys, v)
				return "="
		end)
		key = key:gsub("=+.*$", "")
		key = key:gsub("%s", "_") -- Remove spaces in parameter name
		val = val:gsub("^=+", "")

		if not values[key] then
			values[key] = {}
		end
		if #keys > 0 and type(values[key]) != "table" then
			values[key] = {}
		elseif #keys == 0 and type(values[key]) == "table" then
			values[key] = decodeValue(val)
		elseif type(values[key]) == "string" then
			values[key] = { values[key] }
			table.insert(values[key], decodeValue(val))
		end

		local t = values[key]
		for i,k in ipairs(keys) do
			if type(t) != "table" then
				t = {}
			end
			if k == "" then
				k = #t+1
			end
			if not t[k] then
				t[k] = {}
			end
			if i == #keys then
				t[k] = val
			end
			t = t[k]
		end
	end
	return values
end

---Parse raw path, returning the path and query table.
---@param raw_url string
---@return string URLPath
---@return table URLQueryArguments
function GNIL.API.Parser.ParseRawPath(raw_url)
	local data = {}
	raw_url = raw_url:gsub("%?(.*)", function(v)
		data.query = GNIL.API.Parser.Query(v)
		return ""
	end)
	data.path = raw_url:gsub("([^/]+)", function (s) return GNIL.API.URL.Encode(GNIL.API.URL.Decode(s)) end)
	return data.path, data.query
end

---Parse a raw route, returning a sequential table of
---subtables tables each representing a fragment of
---the route. Should only really be used by the Router.
---@param raw_route string
---@return table? RouteFragments
function GNIL.API.Parser.Route(raw_route)

	-- If the first character in the route is a slash, we
	-- should remove it (since its representing the base).
	raw_route = GNIL.API.URL.RemoveStartingSlash(raw_route)

	local fragments = {}
	for i, v in ipairs(string.Explode("/", raw_route)) do

		-- Ignore empty parts, this could be a trailing slash or
		-- incorrect formatting (double slashes etc).
		if v == "" then
			continue
		end

		local frag_type, arg_type = GNIL_API_ARGUMENT_STR, nil
		if (v[1] == "{" and v[#v] == "}") then
			frag_type = GNIL_API_ARGUMENT_ARG
			v = string.sub(v, 2, #v - 1)

			-- If there is a colon within the argument then it is
			-- seperating the actual argument name from the type.
			if string.find(v, ":") then
				local arg_parts = string.Explode(":", v)
				if #arg_parts != 2 then
					MODULE:log("Invalid provided route '" .. raw_route ..  "', '" .. v .. "' contains invalid argument type specifier structure.", "error")
					return nil
				end

				-- Unpack argument parts.
				v = arg_parts[1]
				arg_type = string.lower(arg_parts[2])

				-- Ensure the requested argument validator actually exists.
				if not GNIL.API.Validators.Exists(arg_type) then
					MODULE:log("Route '" .. raw_route .. "', argument '" .. v .. "' uses invalid/unknown type '" .. arg_type .. "'. Defaulting to string.", "warning")
					arg_type = "str"
				end
			else

				-- If there is no type specifier, use default string type.
				arg_type = "str"
			end
		end

		fragments[i] = {
			frag_type,
			v,
			arg_type
		}
	end
	return fragments
end