-- Table modifications/extensions

table.Slice = function(tbl, first, last, step)
    local sliced = {}

    for i = first or 1, last or #tbl, step or 1 do
      sliced[#sliced+1] = tbl[i]
    end

    return sliced
end

table.Lookup = function(tbl, value)
    local out, value = {}, Either(value != nil, value, true)
    for _, v in pairs(tbl) do
        out[v] = value
    end
    return out
end