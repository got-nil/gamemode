local MODULE = MODULE
GNIL.API.URL = GNIL.API.URL or {}

---URL encode a provided string, making it URL-Safe.
---@param str string
---@return string
function GNIL.API.URL.Encode(str)

    -- https://github.com/stuartpb/tvtropes-lua/blob/master/urlencode.lua
	str = string.gsub(str, "\r?\n", "\r\n")
	str = string.gsub(str, "([^%w%-%.%_%~ ])",
		function (c) return string.format ("%%%02X", string.byte(c)) end)
	str = string.gsub(str, " ", "+")
	return str
end

---Decode string into plaintext from URL-Safe.
---@param str string
---@return string
function GNIL.API.URL.Decode(str)
    str = string.gsub(str, "+", " ")
    str = string.gsub(str, "%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
    return str
end

---Remove the starting slash from a string.
---@param str any
---@return any
function GNIL.API.URL.RemoveStartingSlash(str)
    if str[1] == "/" then
        str = string.sub(str, 2)
    end
    return str
end

---Encode each key and value within a table.
---@param tbl table<string, any>
---@return string
function GNIL.API.URL.EncodeTable(tbl)

    -- URL encode each key and value individually.
    local args, i = {}, 1
    for k, v in pairs(tbl) do
        args[i] = GNIL.API.Parser.URLEncode(k) .. "=" .. GNIL.API.Parser.URLEncode(v)
        i = i + 1
    end
    return table.concat(args, "&")
end