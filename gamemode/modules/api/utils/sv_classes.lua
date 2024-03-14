local MODULE = MODULE

-- Classes should be loaded before the rest of the core.
GNIL.API.Classes = GNIL.API.Classes or {}
MODULE:IncludeDirectory("classes")

---Cast value to type, calling the class _From method if it
---exists, or just returning the value if its already the class.
---@param value table
---@param class_name string
---@return middleclass?
function GNIL.API.Classes.To(value, class_name)
    local class = GNIL.API.Classes[class_name]

    if class == nil then return nil end
    if value == nil then return class:New() end
    if value.class and value.class.name == class.name then return value end

    -- Attempt to use the class _From converter to allow the
    -- class to convert the value itself. If that doesn't work,
    -- return empty constructed class instance instead.
    if class._From then
        local rtrn = class._From(value)
        if rtrn then
            return rtrn
        end
    end
    return class:New()
end

---Is a provided value type of class?
---@param value any
---@param class_name string
---@return boolean
function GNIL.API.Classes.Is(value, class_name)
    local class = GNIL.API.Classes[class_name]

    if value == nil or class == nil then return false end
    if value.class and value.class.name == class.name then return true end
    return false
end