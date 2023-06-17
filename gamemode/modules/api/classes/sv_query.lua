-- Query is used as a provider for the parsed query string data.
-- Allows for query arguments to be modified and rebuilt for URL safe
-- outputs.

local Query = GNIL.Thirdparty.middleclass("Query")
function Query._From(query)
    if (isstring(query) || (istable(query) && not table.IsSequential(query))) then
		return Query:New(query)
	end
end

function Query:Initialize(query)
	if query == nil then query = {} end

	-- If a string is provided in the constructor, parse
	-- it and convert it to a query table.
	if isstring(query) then
		query = GNIL.API.Parser.Query(query)
	end
	
	self._args = query
end

function Query:ToTable() return self:GetAll() end
function Query:GetAll() return self._args end
function Query:Exists(name) return self:Get(name) != nil end

-- Get a query value by key.
function Query:Get(name, default)
	local v = self._args[name]
	if v == nil then return default end
	return v
end

-- Set a query key value.
function Query:Set(name, value)
	self._args[name] = value
end

local function isQueryValueInTbl(name, accepted)
	name = string.lower(name)
	for _, v in ipairs(accepted) do
		if name == v then
			return true
		end
	end
	return false
end

-- Is an argument true or false (in certain strings).
function Query:IsTrue(name) return isQueryValueInTbl(name, {"true", "1", "yes"}) end
function Query:IsFalse(name) return isQueryValueInTbl(name, {"false", "0", "no"}) end

-- Build query string from current arguments.
function Query.BuildQuery(tab, sep, key)
	local query = {}
	if not sep then sep = "&" end
	local keys = {}
	for k in pairs(tab) do
		keys[#keys+1] = k
	end
	table.sort(keys, function (a, b)
  		local function padnum(n, rest) return ("%03d"..rest):format(tonumber(n)) end
  		return tostring(a):gsub("(%d+)(%.)",padnum) < tostring(b):gsub("(%d+)(%.)",padnum)
	end)
	for _,name in ipairs(keys) do
		local value = tab[name]
		name = GNIL.API.URL.Encode(tostring(name), {["-"] = true, ["_"] = true, ["."] = true})
		if key then
			if string.find(name, "^%d+$") then
				name = tostring(key)
			else
				name = string.format("%s[%s]", tostring(key), tostring(name))
			end
		end
		if type(value) == "table" then
			query[#query+1] = GNIL.API.Classes.Query.BuildQuery(value, sep, name)
		else
			local value = GNIL.API.URL.Encode(tostring(value), GNIL.API.Parser.QueryOptions.legal_in_query)
			if value != "" then
				query[#query+1] = string.format("%s=%s", name, value)
			else
				query[#query+1] = name
			end
		end
	end
	return table.concat(query, sep)
end

-- Build current query arguments into URL safe query string.
function Query:Build()
	return GNIL.API.Classes.Query.BuildQuery(self._args)
end

-- If the query class is cast to a string, then we should build the
-- current query arguments into a URL safe string.
function Query:__tostring()
	return self:Build()
end

GNIL.API.Classes.Query = Query