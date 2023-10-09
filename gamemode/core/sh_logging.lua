GNIL.Logging = {}

-- Cache colours used for logging.
local logcolours = {
    ["default"] = Color(255, 255, 255),
    ["error"] = Color(255, 0, 0),
    ["success"] = Color(0, 255, 0),
    ["warning"] = Color(255, 183, 0),
    ["debug"] = Color(0, 255, 247)
}

function GNIL.Logging.Log(log, logtype, prefix)
    MsgC(
        (logcolours[logtype == nil and "default" or logtype] != nil and logcolours[logtype] or logcolours["default"]),
        "[GNIL][" .. (SERVER and "SV" or "CL") ..  "]" .. (prefix == nil and "" or ("[" .. prefix .. "]")) .."[" .. (logtype == nil and "INFO" or string.upper(logtype)) .. "] "
    )

    -- If the provided input is a table, and the pretty_table thirdparty
    -- utility is loaded then we should use that to print it. (Also ensure
    -- that the thirdparty utility actually exists).
    if istable(log) and SafeTableAccess(GNIL, "Thirdparty", "pretty_table") != nil then
        GNIL.Thirdparty.pretty_table(log)
        return
    end

    Msg("-> " .. (istable(log) and util.TableToJSON(log) or tostring(log)) .. "\n")
end

-- Send a log directly to a player. When using with the player metatable
-- you can send logs to a player as simply as ply:log(...)
function GNIL.Logging.LogToPlayer(ply, log, logtype)
    if not GNIL.Net then return end

    assert(isstring(log), "Provided log message must be a string")
    assert(logtype == nil or isstring(logtype), "Provided logtype must be nil or a string")

    -- Send the log net message to player.
    GNIL.Net.Create("log")
        :WriteString(log)
        :WriteString(logtype or "default")
    :Send(ply)
end

-- Since this utility loads before the net module
-- we must add a hook to do the net stuff once its
-- been loaded (later down the init order).
hook.Add("GNIL.Modules.Loaded", "GNIL.Logging.Net", function(name)
    if name != "net" then return end
    hook.Remove("GNIL.Modules.Loaded", "GNIL.Logging.Net")

    if SERVER then
        GNIL.Net.AddNetworkString("log")
    else
        GNIL.Net.Receive("log", function()
            GNIL.Logging.Log(net.ReadString(), net.ReadString())
        end)
    end
end)

-- This is basically the only exception for the
-- no functions on base const rule.
GNIL.log = GNIL.Logging.Log
