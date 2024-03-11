-- https://github.com/kikito/middleclass
-- Used to create object oriented classes.


--[[

    Method changes:
        initialize -> Initialize
        Include -> IncludeMixin

    - morgverd

--]]

local middleclass = {
    _VERSION = 'middleclass v4.1.1',
    _DESCRIPTION = 'Object Orientation for Lua',
    _URL = 'https://github.com/kikito/middleclass',
    _LICENSE = [[
      MIT LICENSE
      Copyright (c) 2011 Enrique García Cota
      Permission is hereby granted, free of charge, to any person obtaining a
      copy of this software and associated documentation files (the
      "Software"), to deal in the Software without restriction, including
      without limitation the rights to use, copy, modify, merge, publish,
      distribute, sublicense, and/or sell copies of the Software, and to
      permit persons to whom the Software is furnished to do so, subject to
      the following conditions:
      The above copyright notice and this permission notice shall be included
      in all copies or substantial portions of the Software.
      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
      OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
      MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
      IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
      CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
      TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
      SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    ]]
}

local function _createIndexWrapper(aClass, f)
    if f == nil then
        return aClass.__instanceDict
    else
        return function(self, name)
            local value = aClass.__instanceDict[name]

            if value != nil then
                return value
            elseif isfunction(f) then
                return (f(self, name))
            else
                return f[name]
            end
        end
    end
end

local function _propagateInstanceMethod(aClass, name, f)
    f = name == "__index" and _createIndexWrapper(aClass, f) or f
    aClass.__instanceDict[name] = f

    for subclass in pairs(aClass.subclasses) do
        if rawget(subclass.__declaredMethods, name) == nil then
            _propagateInstanceMethod(subclass, name, f)
        end
    end
end

local function _declareInstanceMethod(aClass, name, f)
    if not aClass.__declaredMethods then return end
    aClass.__declaredMethods[name] = f

    if f == nil and aClass.super then
        f = aClass.super.__instanceDict[name]
    end

    _propagateInstanceMethod(aClass, name, f)
end

local function _tostring(self)
    return "class " .. self.name
end
local function _call(self, ...)
    return self:New(...)
end

local function _createClass(name, super)
    local dict = {}
    dict.__index = dict

    local aClass = {
        name = name,
        super = super,
        static = {},
        __instanceDict = dict,
        __declaredMethods = {},
        subclasses = setmetatable({}, {
            __mode = 'k'
        })
    }

    if super then
        setmetatable(aClass.static, {
            __index = function(_, k)
                local result = rawget(dict, k)
                if result == nil then
                    return super.static[k]
                end
                return result
            end
        })
    else
        setmetatable(aClass.static, {
            __index = function(_, k)
                return rawget(dict, k)
            end
        })
    end

    setmetatable(aClass, {
        __index = aClass.static,
        __tostring = _tostring,
        __call = _call,
        __newindex = _declareInstanceMethod
    })

    return aClass
end

local function _includeMixin(aClass, mixin)
    assert(istable(mixin), "mixin must be a table")

    for name, method in pairs(mixin) do
        if name != "Included" and name != "static" then
            aClass[name] = method
        end
    end

    for name, method in pairs(mixin.static or {}) do
        aClass.static[name] = method
    end

    if isfunction(mixin.Included) then
        mixin:Included(aClass)
    end
    return aClass
end

local DefaultMixin = {
    __tostring = function(self)
        return "instance of " .. tostring(self.class)
    end,

    Initialize = function(self, ...)
    end,

    IsInstanceOf = function(self, aClass)
        return istable(aClass) and istable(self) and
                   (self.class == aClass or istable(self.class) and isfunction(self.class.IsSubclassOf) and
                       self.class:IsSubclassOf(aClass))
    end,

    static = {
        Allocate = function(self)
            assert(istable(self), "Make sure that you are using 'Class:Allocate' instead of 'Class.Allocate'")
            return setmetatable({
                class = self
            }, self.__instanceDict)
        end,

        New = function(self, ...)
            assert(istable(self), "Make sure that you are using 'Class:New' instead of 'Class.New'")
            local instance = self:Allocate()
            instance:Initialize(...)
            return instance
        end,

        Subclass = function(self, name)
            assert(istable(self), "Make sure that you are using 'Class:Subclass' instead of 'Class.Subclass'")
            assert(isstring(name), "You must provide a name(string) for your class")

            local subclass = _createClass(name, self)

            for methodName, f in pairs(self.__instanceDict) do
                _propagateInstanceMethod(subclass, methodName, f)
            end
            subclass.Initialize = function(instance, ...)
                return self.Initialize(instance, ...)
            end

            self.subclasses[subclass] = true
            self:Subclassed(subclass)

            return subclass
        end,

        Subclassed = function(self, other)
        end,

        IsSubclassOf = function(self, other)
            return istable(other) and istable(self.super) and
                       (self.super == other or self.super:IsSubclassOf(other))
        end,

        IncludeMixin = function(self, ...)
            assert(istable(self), "Make sure you that you are using 'Class:Include' instead of 'Class.Include'")
            for _, mixin in ipairs({...}) do
                _includeMixin(self, mixin)
            end
            return self
        end
    }
}

function middleclass.class(name, super)
    assert(isstring(name), "A name (string) is needed for the new class")
    return super and super:Subclass(name) or _includeMixin(_createClass(name), DefaultMixin)
end

setmetatable(middleclass, {
    __call = function(_, ...)
        return middleclass.class(...)
    end
})

return middleclass