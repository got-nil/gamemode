-- https://github.com/zserge/lua-promises
-- A+ promises in Lua.

local M = {}

local deferred = {}
deferred.__index = deferred

local PENDING = 0
local RESOLVING = 1
local REJECTING = 2
local RESOLVED = 3
local REJECTED = 4

local function finish(deferred, state)
	state = state or REJECTED
	for i, f in ipairs(deferred.queue) do
		if state == RESOLVED then
			f:Resolve(deferred.value)
		else
			f:Reject(deferred.value)
		end
	end
	deferred.state = state
end

local function isfunction(f)
	if type(f) == 'table' then
		local mt = getmetatable(f)
		return mt ~= nil and type(mt.__call) == 'function'
	end
	return type(f) == 'function'
end

local function promise(deferred, next, success, failure, nonpromisecb)
	if type(deferred) == 'table' and type(deferred.value) == 'table' and isfunction(next) then
		local called = false
		local ok, err = pcall(next, deferred.value, function(v)
			if called then return end
			called = true
			deferred.value = v
			success()
		end, function(v)
			if called then return end
			called = true
			deferred.value = v
			failure()
		end)
		if not ok and not called then
			deferred.value = err
			failure()
		end
	else
		nonpromisecb()
	end
end

local function fire(deferred)
	local next
	if type(deferred.value) == 'table' then
		next = deferred.value.next
	end
	promise(deferred, next, function()
		deferred.state = RESOLVING
		fire(deferred)
	end, function()
		deferred.state = REJECTING
		fire(deferred)
	end, function()
		local ok
		local v
		if deferred.state == RESOLVING and isfunction(deferred.success) then
			ok, v = pcall(deferred.success, deferred.value)
		elseif deferred.state == REJECTING and isfunction(deferred.failure) then
			ok, v = pcall(deferred.failure, deferred.value)
			if ok then
				deferred.state = RESOLVING
			end
		end

		if ok ~= nil then
			if ok then
				deferred.value = v
			else
				deferred.value = v
				return finish(deferred)
			end
		end

		if deferred.value == deferred then
			deferred.value = pcall(error, 'resolving promise with itself')
			return finish(deferred)
		else
			promise(deferred, next, function()
				finish(deferred, RESOLVED)
			end, function(state)
				finish(deferred, state)
			end, function()
				finish(deferred, deferred.state == RESOLVING and RESOLVED)
			end)
		end
	end)
end

local function resolve(deferred, state, value)
	if deferred.state == 0 then
		deferred.value = value
		deferred.state = state
		fire(deferred)
	end
	return deferred
end

--
-- PUBLIC API
--
function deferred:Resolve(value)
	return resolve(self, RESOLVING, value)
end

function deferred:Reject(value)
	return resolve(self, REJECTING, value)
end

function M.new(options)
	if isfunction(options) then
		local d = M.new()
		local ok, err = pcall(options, d)
		if not ok then
			d:Reject(err)
		end
		return d
	end
	options = options or {}
	local d
	d = {
		Next = function(self, success, failure)
			local next = M.new({success = success, failure = failure, extend = options.extend})
			if d.state == RESOLVED then
				Next:Resolve(d.value)
			elseif d.state == REJECTED then
				Next:Reject(d.value)
			else
				table.insert(d.queue, next)
			end
			return next
		end,
		state = 0,
		queue = {},
		success = options.success,
		failure = options.failure,
	}
	d = setmetatable(d, deferred)
	if isfunction(options.extend) then
		options.extend(d)
	end
	return d
end

function M.all(args)
	local d = M.new()
	if #args == 0 then
		return d:Resolve({})
	end
	local method = "resolve"
	local pending = #args
	local results = {}

	local function synchronizer(i, resolved)
		return function(value)
			results[i] = value
			if not resolved then
				method = "reject"
			end
			pending = pending - 1
			if pending == 0 then
				d[method](d, results)
			end
			return value
		end
	end

	for i = 1, pending do
		args[i]:Next(synchronizer(i, true), synchronizer(i, false))
	end
	return d
end

function M.map(args, fn)
	local d = M.new()
	local results = {}
	local function donext(i)
		if i > #args then
			d:Resolve(results)
		else
			fn(args[i]):Next(function(res)
				table.insert(results, res)
				donext(i+1)
			end, function(err)
				d:Reject(err)
			end)
		end
	end
	donext(1)
	return d
end

function M.first(args)
	local d = M.new()
	for _, v in ipairs(args) do
		v:Next(function(res)
			d:Resolve(res)
		end, function(err)
			d:Reject(err)
		end)
	end
	return d
end


setmetatable(M, {
    __call = function(_, ...)
        return M.new(...)
    end
})

return M