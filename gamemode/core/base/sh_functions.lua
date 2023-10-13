-- Global functions are bad, but if you're gonna add them
-- they should be added here.

-- SafeTableAccess(tbl, "a", "b") -> safe access without errors, or nil
SafeTableAccess = function(tbl, ...)
    if not istable(tbl) then
        return nil
    end

    local last = tbl
    for i, v in ipairs({...}) do
        last = last[v]
        if last == nil then
            return nil
        end
    end
    return last
end

IsPlayer = function(ply)
    return IsEntity(ply) and IsValid(ply) and ply:IsPlayer()
end

IsClass = function(obj, name)
    if not obj or not obj.class or not obj.class.name then return false end
    return obj.class.name == name
end

IsInstanceOf = function(obj, class)
    return istable(obj) and obj.IsInstanceOf and obj:IsInstanceOf(class)
end

IsSubclassOf = function(obj, class)
    return istable(obj) and obj.IsSubclassOf and obj:IsSubclassOf(class)
end
