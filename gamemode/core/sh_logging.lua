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
    if istable(log) and GNIL.Thirdparty and GNIL.Thirdparty.pretty_table then
        GNIL.Thirdparty.pretty_table(log)
        return
    end

    Msg("-> " .. (istable(log) and util.TableToJSON(log) or tostring(log)) .. "\n")
end

-- Send a log directly to a player. When using with the player metatable
-- you can send logs to a player as simply as ply:log(...)
function GNIL.Logging.LogToPlayer(ply, log, logtype)

    -- !!!THIS IS TEMPORARY UNTIL I MAKE MY NET THING!!!!
    net.Start("gnil_log")
        net.WriteString(log)
        net.WriteString(logtype or "")
    net.Send(ply)
end

-- !!!THIS IS TEMPORARY UNTIL I MAKE MY NET THING!!!!
if CLIENT then
    net.Receive("gnil_log", function()
        GNIL.Logging.Log(net.ReadString(), net.ReadString())
    end)
else    
    util.AddNetworkString("gnil_log")    
end

-- This is basically the only exception for the
-- no functions on base const rule. 
GNIL.log = GNIL.Logging.Log
