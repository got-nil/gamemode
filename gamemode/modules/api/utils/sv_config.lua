

-- {is_required, type, ?default_value}
local MODULE, config_options = MODULE, {
    ["ws_host"] = {true, TYPE_STRING, false},
    ["ws_token"] = {true, TYPE_STRING, false},
    ["ws_verify_cert"] = {false, TYPE_BOOL, true},

    ["enabled"] = {false, TYPE_BOOL, false},
    ["ip_whitelist"] = {false, TYPE_TABLE, {}},
    ["debug_logs"] = {false, TYPE_BOOL, false},
}

-- Validate / Fill default config values.
local conf = MODULE:Config():ToTable()
for k, v in pairs(config_options) do
    if conf[k] == nil then
        if v[1] then
            MODULE:log("Missing required config argument - " .. k, "error")
        else
            conf[k] = v[3]
        end
    else
        if TypeID(conf[k]) != v[2] then
            MODULE:log("Config invalid value type for argument - " .. k, "error")
        end
    end
end

-- If the ip_whitelist table is sequential, make it associative.
-- This is required by the GSIServer as it makes whitelist checks
-- alot faster (instead of increment checking a list).
if table.IsSequential(conf["ip_whitelist"]) then
    local new_ip_whitelist = {}
    for _, v in ipairs(conf["ip_whitelist"]) do
        new_ip_whitelist[v] = true
    end
    conf["ip_whitelist"] = new_ip_whitelist
end

GNIL.API.Config = conf