
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
    "isentity",
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

local sandbox_libaries = {
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

-- Build normal libaries.
local normal_libaries = {}
for k, _ in pairs(sandbox_libaries) do
    normal_libaries[k] = _G[k]
end

-- Build sandbox environment from globals and limited libaries.
function GNIL.Dev.CreateEnvironment(stdout_callback, use_global_env, use_normal_libaries)

    local env = {}
    if not use_global_env then
        env = {SERVER = true, CLIENT = false}
        for _, v in ipairs(globals) do env[v] = _G[v] end
        for k, v in pairs(Either(use_normal_libaries, normal_libaries, sandbox_libaries)) do env[k] = v end
    else
        env = table.Copy(_G)
    end

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
            env[v] = function(...)
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
            env[v] = _G[v]
        end
    end

    return env
end
