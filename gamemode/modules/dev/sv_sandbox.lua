
-- Run provided code in a "sandbox" environment. Most of the default
-- global functions are included. Packages may be partially included.
-- Returns the code output and stdout buffer.


---Parse a raw error string into
function GNIL.Dev.ParseError(err)

    -- If the error is not a string, still return a valid structure.
    if not isstring(err) then
        return {
            line = 0,
            err = tostring(err) or ""
        }
    end

    -- Parse the line number from error message.
    local parts, rest = string.Explode(":", err), {}
    for i = 1, #parts - 2 do
        rest[i] = parts[i + 2]
    end
    return {
        line = tonumber(parts[2]),
        err = string.sub(table.concat(rest, ":"), 2)
    }
end

local function toFunction(code_or_fn)
    local fn = code_or_fn
    if not isfunction(code_or_fn) then
        assert(isstring(code_or_fn), "Provided argument can either be a function or code string.")

        -- Compile the provided code, returning
        -- the error as a string if there is one.
        fn = CompileString(code_or_fn, "SandboxCode", false)
        if not isfunction(fn) then
            return false, GNIL.Dev.ParseError(fn)
        end
    end
    return fn, nil
end

local function executeFunction(code_or_fn, use_global_env, arguments)
    local fn, err = toFunction(code_or_fn)
    if not fn then return false, err end

    local stdout = {}
    local env = GNIL.Dev.CreateEnvironment(function(str)
        table.insert(stdout, str)
    end, use_global_env)

    setfenv(fn, env)
    local success, out = pcall(fn, unpack(arguments))
    if success then
        if out == nil then out = false end
        return true, {
            out = out,
            stdout = stdout
        }
    else
        return false, GNIL.Dev.ParseError(out)
    end
end

---Run a function and capture any stdout (print calls etc).
---@param code_or_fn string|function
---@param ... any Function arguments.
---@return boolean SuccessState
---@return table? Output
function GNIL.Dev.CaptureStdout(code_or_fn, ...)
    return executeFunction(code_or_fn, true, {...})
end

---Run code in a "sandbox" with detoured global functions.
---**This should __NOT__ be used to run user supplied code.**
---@param code_or_fn any
---@param ... any Function arguments.
---@return boolean SuccessState
---@return table? Output
function GNIL.Dev.SandboxExecute(code_or_fn, ...)
    return executeFunction(code_or_fn, false, {...})
end