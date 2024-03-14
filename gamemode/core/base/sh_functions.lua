-- Global functions are bad, but if you're gonna add them
-- they should be added here.

---SafeTableAccess(tbl, "a", "b") -> safe access without errors, or nil
---Safely access a nested table value.
---@param tbl any
---@param ... string|number
---@return any
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

---Check if a provided object is a Player.
---@param ply any
---@return boolean
IsPlayer = function(ply)
    return IsValid(ply) and ply.IsPlayer and ply:IsPlayer()
end

---Check if an object matches class name.
---@param obj any
---@param name string
---@return boolean
IsClass = function(obj, name)
    if not obj or not obj.class or not obj.class.name then return false end
    return obj.class.name == name
end

---Check if an object is an instance of a class.
---@param obj any
---@param class middleclass
---@return boolean
IsInstanceOf = function(obj, class)
    return istable(obj) and obj.IsInstanceOf and obj:IsInstanceOf(class)
end

---Check if an object is subclass of a class.
---@param obj any
---@param class middleclass
---@return boolean
IsSubclassOf = function(obj, class)
    return istable(obj) and obj.IsSubclassOf and obj:IsSubclassOf(class)
end

---tonumber, but it throws a halting Error if its not a number.
---@param number any
---@return number
ToNumberThrow = function(number)
    local o = tonumber(number)
    if o == nil then
        error("Invalid number provided!")
    end
    return o
end