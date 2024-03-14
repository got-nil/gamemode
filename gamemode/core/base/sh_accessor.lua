
-- AccessorFunc, but with more options.
--[[

Supports global settings with _ prefix on root level.

ClassAccessorFunc(MyClass, {
    Name = "name",
    Age = FuncAccessors.ReadOnly("age"),
    Gender = {"gender", FORCE_STRING},
    Country = {
        var = "country",
        force = TYPE_STRING,
        validate = function(v)

            local acceptedCountries = {
                ["GB"] = true,
                ["FR"] = true
            }
            return acceptedCountries[v]
        end
    }
})
class obj = MyClass:New()

 obj:GetName() / obj:SetName()          -> No validation or type force, allows name to be set to value.
 obj:GetAge()                           -> There is no SetAge function since its ReadOnly.
 obj:GetGender() / obj:SetGender()      -> The gender will be a string.
 obj:GetCountry() / obj:SetCountry()    -> The country will be a string, and can only be set to "GB" or "FR".

--]]

---@alias FuncAccessorTable table<string, string|table<number, any>|FuncAccessor>
---@alias FuncAccessor { var: string, force?: number, nillable?: boolean, validate?: (fun(obj: any, value: any, accessor: FuncAccessor): boolean?), get?: boolean|(fun(obj: any, fallback: any, accessor: FuncAccessor): any), set?: boolean|(fun(obj: any, value: any, accessor: FuncAccessor): boolean), is?: boolean|(fun(obj: any, accessor: FuncAccessor): boolean) }

local force_setters = {
    [FORCE_STRING] = tostring,
    [FORCE_NUMBER] = tonumber,
    [FORCE_BOOL] = tobool,
    [FORCE_ANGLE] = Angle,
    [FORCE_COLOR] = function(v)
        local t = TypeID(v)
        if t == TYPE_COLOR then return v end
        if t == TYPE_VECTOR then return v:ToColor() end
        return string.ToColor(tostring(v))
    end,
    [FORCE_VECTOR] = function(v)
        if IsColor(v) then return v:ToVector() end
        return Vector(v)
    end
}

-- Safely get index from table, returning nil
-- if the value doesn't exist.
local function _safe_get_i(tbl, index)
    if index > #tbl then return nil end
    return tbl[index]
end

-- Wrapper that returns validator function.
-- Can accept multiple type enums. Used for validator.
local function _acceptedTypes(...)
    local args = {...}
    return function(value)
        local t = TypeID(value)
        for _, v in ipairs(args) do
            if t == v then return true end
        end
        return false
    end
end

---Add accessor functions to a class.
---@param obj table
---@param tbl FuncAccessorTable
ClassAccessorFunc = function(obj, tbl)

    -- Find global settings within the table. These start with an
    -- underscore and act as the default value for other accessors.
    local global_settings, has_global_settings = {}, false
    local global_setting_strings = {
        "force",
        "nillable",
        "validate",
        "get",
        "set",
        "set_return_self"
    }
    for _, v in ipairs(global_setting_strings) do
        local override = tbl["_" .. v]
        if override != nil then
            global_settings[v] = override
            tbl["_" .. v] = nil
            has_global_settings = true
        end
    end

    for k, v in pairs(tbl) do
        assert(isstring(k), "Provided accessor name must be a string")

        -- Convert provided value to assoc table.
        local value = v
        if isstring(v) then
            value = {
                var = v
            }
        end
        if istable(v) then ---@cast v table
            if table.IsSequential(v) then
                local o = table.Copy(v)
                value = {
                    var = _safe_get_i(o, 1),
                    force = _safe_get_i(o, 2),
                    nillable = _safe_get_i(o, 3)
                }
            end
        end
        assert(istable(value), "Provided accessor value must be a table")

        -- Apply global settings if they don't yet exist.
        if has_global_settings then
            for name, default in pairs(global_settings) do
                if value[name] != nil then continue end
                value[name] = default
            end
        end

        -- Ensure the value is a table (either directly or from conversion).
        -- Then validate the table structure with defaults etc.
        local success, out = GNIL.Validation.Structure(value, {
            var = {nil, TYPE_STRING, true},
            force = {
                nil, {
                    FORCE_STRING,
                    FORCE_NUMBER,
                    FORCE_BOOL,
                    FORCE_ANGLE,
                    FORCE_COLOR,
                    FORCE_VECTOR
                }
            },
            nillable = {false, TYPE_BOOL},
            validate = {nil, TYPE_FUNCTION},
            get = {nil, _acceptedTypes(TYPE_BOOL, TYPE_FUNCTION)},
            set = {nil, _acceptedTypes(TYPE_BOOL, TYPE_FUNCTION)},
            is = {false, _acceptedTypes(TYPE_BOOL, TYPE_FUNCTION)},

            -- Should :Set() return itsself to be chainable?
            set_return_self = {true, TYPE_BOOL}
        })
        if not success then
            error("Failed to add class accessor for '" .. k .. "' with reason: " .. out)
        end

        -- If the get/set is true, set it to nil. This means the value
        -- will only be truthy when there is a callback present instead
        -- of having to call isfunction constantly.
        out.get = Either(out.get == true, nil, out.get)
        out.set = Either(out.set == true, nil, out.set)

        -- Setter that allows default FORCE enum behaviour.
        -- Also provides a validator function before a value is set.
        if out.set != false then
            obj["Set" .. k] = function(self, value)
                if out.force then
                    value = force_setters[out.force](value)
                end
                local should_set = true
                if (not (value == nil and out.nillable)) and out.validate then
                    local fn_validate = out.validate(self, value, out)
                    if isbool(fn_validate) then should_set = fn_validate end
                end
                if should_set then
                    if out.set then
                        local fn_set = out.set(self, value, out)
                        if isbool(fn_set) then should_set = fn_set end
                    else
                        self[out.var] = value
                    end
                end
                if out.set_return_self then
                    return self
                else
                    return should_set
                end
            end
        end

        -- Getter with fallback support.
        if out.get != false then
            obj["Get" .. k] = function(self, fallback)
                if out.get then return out.get(self, fallback, out) end
                local class_value = self[out.var]
                return Either(class_value == nil, fallback, class_value)
            end
        end

        -- Only for boolean types.
        if out.is != false then
            obj["Is" .. k] = function(self)
                if out.is != true then return out.is(self, out) end
                return tobool(self[out.var])
            end
        end
    end
end

FuncAccessors = {

    ---Add only a getter without setter.
    ---@param var string
    ---@param additions? table
    ---@return FuncAccessor
    ReadOnly = function(var, additions)
        return table.Inherit({
            var = var,
            set = false
        }, additions or {})
    end,

    ---Add a getter and setter that only accepts numbers between range.
    ---@param var string
    ---@param min? number
    ---@param max? number
    ---@param additions? table
    ---@return FuncAccessor
    NumberMinMax = function(var, min, max, additions)
        local min, max = min, max
        return table.Inherit({
            var = var,
            validate = function(_, v)

                -- Min, Max is optional.
                if not isnumber(v) then return false end
                if min and min > v then return false end
                if max and v > max then return false end
                return true
            end
        }, additions or {})
    end,

    ---Add a getter and setter that only accepts a class which is the instance of provided class name.
    ---@param var string
    ---@param class string|fun(): string
    ---@param additions? table
    ---@return FuncAccessor
    InstanceOf = function(var, class, additions)
        local class, is_fn = class, isfunction(class)
        return table.Inherit({
            var = var,
            validate = function(_, v)

                -- Allow a function to be provided in-place of the class.
                -- This is useful for classes that do not exist when the
                -- ClassAccessorFunc is being added. (weird load orders).
                local cls = class
                if is_fn then cls = class() end
                return v.IsInstanceOf and v:IsInstanceOf(cls)
            end
        }, additions or {})
    end,

    ---Add a setter that only accepts boolean and IsVar method.
    ---@param var string
    ---@param additions? table
    ---@return FuncAccessor
    Boolean = function(var, additions)
        return table.Inherit({
            var = var,
            validate = function(_, v) return isbool(v) end,
            get = false,
            is = true
        }, additions or {})
    end,

    ---Add a getter and setter that only allows numbers greater or equal to count.
    ---@param var string
    ---@param count number
    ---@param additions? table
    ---@return FuncAccessor
    Enum = function(var, count, additions)
        return FuncAccessors.NumberMinMax(var, 1, count, additions)
    end
}