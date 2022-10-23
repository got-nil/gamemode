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
        "[GSI]" .. (prefix == nil and "" or ("[" .. prefix .. "]")) .."[" .. (logtype == nil and "INFO" or string.upper(logtype)) .. "] "
    )
    
    -- If the provided input is a table, and the pretty_table thirdparty
    -- utility is loaded then we should use that to print it. 
    if istable(log) and GNIL.Thirdparty.pretty_table then
        GNIL.Thirdparty.pretty_table(log)
        return
    end

    Msg("-> " .. (istable(log) and util.TableToJSON(log) or tostring(log)) .. "\n")
end

-- This is basically the only exception for the
-- no functions on base const rule. 
GNIL.log = GNIL.Logging.Log