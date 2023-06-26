
-- Run provided code in a "sandbox" environment. Most of the default
-- global functions are included. Packages may be partially included.
-- Returns the code output and stdout buffer.

local globals = {
    "Angle",
    "AngleRand",
    "assert",
    "collectgarbage",
    "Color",
    "ColorAlpha",
    "ColorRand",
    "ColorToHSL",
    "ColorToHSV",
    "CompileString",
    "CurTime",
    "DebugInfo",
    "Either",
    "Entity",
    "error",
    "ErrorNoHalt",
    "ErrorNoHaltWithStack",
    "FindMetaTable",
    "Format",
    "FrameTime",
    "gcinfo",
    "setfenv",
    "getfenv",
    "getmetatable",
    "HSLToColor",
    "HSVToColor",
    "HTTP",
    "ipairs",
    "isangle",
    "isbool",
    "IsColor",
    "IsConCommandBlocked",
    "IsEntity",
    "IsFirstTimePredicted",
    "isfunction",
    "ismatrix",
    "IsMounted",
    "isnumber",
    "ispanel",
    "isstring",
    "istable",
    "IsValid",
    "isvector",
    "Lerp",
    "LerpAngle",
    "LerpVector",
    "Matrix",
    "next",
    "pairs",
    "pcall",
    "Path",
    "ProtectedCall",
    "RandomPairs",
    "rawequal",
    "rawget",
    "rawset",
    "RealTime",
    "RecipientFilter",
    "RunString",
    "RunStringEx",
    "select",
    "SortedPairs",
    "SortedPairsByMemberValue",
    "SortedPairsByValue",
    "SQLStr",
    "SysTime",
    "tobool",
    "tonumber",
    "tostring",
    "type",
    "TypeID",
    "unpack",
    "UnPredictedCurTime",
    "Vector",
    "VectorRand",
    "xpcall"
}

local libaries = {
    bit = bit,
    coroutine = coroutine,
    debug = debug,
    engine = {
        AbsoluteFrameTime = engine.AbsoluteFrameTime,
        ActiveGamemode = engine.ActiveGamemode,
        GetAddons = engine.GetAddons,
        TickCount = engine.TickCount
    },
    game = {
        GetIPAddress = function() return "127.0.0.1" end,
        IsDedicated = function() return true end,
        SinglePlayer = function() return false end,
        GetMap = game.GetMap,
        GetMapNext = game.GetMapNext,
        GetMapVersion = game.GetMapVersion,
        GetTimeScale = game.GetTimeScale,
        MaxPlayers = game.MaxPlayers,
    },
    http = http,
    jit = jit,
    language = language,
    list = list,
    markup = markup,
    math = math,
    matproxy = matproxy,
    os = os,
    string = string,
    system = system,
    table = table,
    timer = timer,
    utf8 = utf8,
    util = {
        Base64Encode = util.Base64Encode,
        Base64Decode = util.Base64Decode,
        Compress = util.Compress,
        Decompress = util.Decompress,
        CRC = util.CRC,
        DateStamp = util.DateStamp,
        FilterText = util.FilterText,
        IsBinaryModuleInstalled = function(...) return false end,
        JSONToTable = util.JSONToTable,
        KeyValuesToTable = util.KeyValuesToTable,
        KeyValuesToTablePreserveOrder = util.KeyValuesToTablePreserveOrder,
        NiceFloat = util.NiceFloat,
        MD5 = util.MD5,
        SHA1 = util.SHA1,
        SHA256 = util.SHA256,
        SharedRandom = util.SharedRandom,
        Stack = util.Stack,
        SteamIDFrom64 = util.SteamIDFrom64,
        SteamIDTo64 = util.SteamIDTo64,
        StringToType = util.StringToType,
        TableToJSON = util.TableToJSON,
        TableToKeyValues = util.TableToKeyValues,
        TypeToString = util.TypeToString
    }
}

-- Build sandbox environment from globals and limited libaries.
local function createEnvironment(stdout_callback)
    local sandbox_env = {SERVER = true, CLIENT = false}
    for _, v in ipairs(globals) do sandbox_env[v] = _G[v] end
    for k, v in pairs(libaries) do sandbox_env[k] = v end
    
    -- Proxy environment stdout functions to collect
    -- sandbox print outputs etc. Also prevents people
    -- from spamming messages in the server console.
    local stdout_fns = {
        "print",
        "PrintMessage",
        "PrintTable",
        "Msg",
        "MsgAll",
        "MsgC",
        "MsgN"
    }
    for _, v in ipairs(stdout_fns) do
        if stdout_callback then    
            sandbox_env[v] = function(...)
                local out = {}
                for _, v in ipairs({...}) do
                    if not isstring(v) then continue end
                    table.insert(out, tostring(v))
                end
                stdout_callback(
                    table.concat(out, " ")
                )
            end
        else

            -- If there is no stdout_callback provided default
            -- to the normal function (writes to server console).
            sandbox_env[v] = _G[v]
        end
    end

    return sandbox_env
end

-- Parse a raw error string into 
local function parseError(err)

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

function GNIL.Dev.SandboxExecute(code_or_fn, ...)
    local fn = code_or_fn
    if not isfunction(code_or_fn) then
        assert(isstring(code_or_fn), "Provided argument can either be a function or code string.")

        -- Compile the provided code, returning
        -- the error as a string if there is one.
        fn = CompileString(code_or_fn, "SandboxCode", false)
        if not isfunction(fn) then
            return false, parseError(fn)
        end
    end

    -- Create the stdout_callback to handle any print/log
    -- calls from the sandboxed code.
    local stdout = {}
    local env = createEnvironment(function(str)
        table.insert(stdout, str)
    end)

    -- Call the compiled function with sandbox environment.
    setfenv(fn, env)
    local success, out = pcall(fn, ...)
    if success then
        if out == nil then out = false end
        return true, {
            out = out,
            stdout = stdout
        }
    else
        return false, parseError(out)
    end
end