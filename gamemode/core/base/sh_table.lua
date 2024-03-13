---@class tablelib
local table = table

---Slice a table.
---@param tbl table
---@param first? integer
---@param last? integer
---@param step? integer
---@return table
table.Slice = function(tbl, first, last, step)
    local sliced = {}

    for i = first or 1, last or #tbl, step or 1 do
      sliced[#sliced+1] = tbl[i]
    end

    return sliced
end

---Convert a sequential table to lookup.
---@param tbl table<integer, any>
---@param value? any
---@return table
table.Lookup = function(tbl, value)
    local out, value = {}, Either(value != nil, value, true)
    for _, v in pairs(tbl) do
        out[v] = value
    end
    return out
end