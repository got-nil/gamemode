GNIL.Config = GNIL.Config or {
    ["_r"] = {},
    ["_shared"] = {},
    ["_loaded"] = false
}

-- Allow the table to be called as an alias to Get.
setmetatable(GNIL.Config, {
    __call = function(_, name) return GNIL.Config.Get(name) end,
})

local function validateConfigStructure(structure) -- valid(bool), out(table|string)
    local a, b = GNIL.Validation.Structure(structure, {
        config = {{}, TYPE_TABLE, true},
        realm = {"server", TYPE_STRING, false},
        shared = {{}, TYPE_TABLE, false},
        check = {false, TYPE_FUNCTION, false}
    })
    if not a then return a, b end

    local realms = {
        ["client"] = true,
        ["server"] = true,
        ["shared"] = true,

        -- Replace shorthand aliases
        ["cl"] = "client",
        ["sv"] = "server",
        ["sh"] = "shared" 
    }
    if realms[b.realm] == nil then
        return false, "Invalid provided realm name '" .. b.realm .. "'"
    end
    if realms[b.realm] != true then
        b.realm = realms[b.realm]
    end
    
    return a, b
end

-- Either return the config object or nil.
function GNIL.Config.Get(name)
    return GNIL.Config["_r"][name]
end

-- Load a config file and cache it.
function GNIL.Config.Load(filename)

    -- Ensure the config filepath actually exists.
    local filepath = GNIL.Utils.ResolveGamemodePath("config/" .. filename)
    if not file.Exists(filepath, "LUA") then
        GNIL.log("Config filename being loaded '" .. filename .. "' does not exist.", "warning")
        return false, nil
    end

    -- Actually include the config file to get the out structure.
    local out = include(filepath)
    if out == nil then
        GNIL.log("Config filename '" .. filename .. "' failed to include correctly.", "warning")
        return false, nil
    end

    -- Validate the returned config structure.
    local isvalid, out = validateConfigStructure(out)
    if not isvalid then
        GNIL.log("Config filename '" .. filename .. "' validation error: " .. out .. ".", "warning")
        return false, nil
    end

    -- Cache the collected config as Config object.
    local name = GNIL.Utils.GetCleanFilename(filename, "lua")
    local obj = GNIL.Classes.Config:New(name, out):Setup()
    GNIL.Config["_r"][name] = obj

    return true, obj
end

-- Load any full config files. On the server this is all files,
-- whereas on the client this is shared/client config files.
-- Server config files with shared attributes are sent seperately.
if not GNIL.Config["_loaded"] then
    local files, _ = file.Find(GNIL.Utils.ResolveGamemodePath("config") .. "/*.lua", "LUA")
    for _, v in ipairs(files) do
        local success, conf = GNIL.Config.Load(v)
        if success then
            GNIL.log("Successfully loaded config file '" .. conf.name .. "'!", "debug")
        end
    end

    GNIL.Config["_loaded"] = true
end

-- When a player has finished connecting and is able to recieve
-- network messages we should send the partial config content.
-- This could be the full file if theres a passing check, or
-- certain shared attributes.
if SERVER then
    hook.Add("PlayerNetLoad", "gnil_config_net_send", function(ply)
    
        -- Get all config files that the player should recieve.
        local conf = {}
        for _, v in pairs(GNIL.Config["_r"]) do

            -- If the entire file should be sent, then do so.
            if v:ShouldSend(ply) then
                conf[v.name] = v.struct.config
            end
            
            -- Add specific shared attributes.
            for _, k in ipairs(v.struct.shared) do
                if not conf[v.name] then conf[v.name] = {} end
                conf[v.name][k] = v.struct.config[k]
            end
        end

        -- Actually send the table as JSON string.
        -- I know this doesn't preserve big ints, so just use
        -- strings instead like a normal person.
        GNIL.Net.Chunks.Send(
            ply,
            "config_recieve",
            util.TableToJSON(conf),
            true,
            function(success, output)
                if not success then
                    GNIL.log("Failed to send '" .. ply:ToString() .. "' partial config with error: " .. output, "warning")
                end
            end
        )
    end)
end

hook.Add("GNIL.Modules.Init", "gnil_config_module_validation", function(name, partialModule)
    if not isstring(partialModule.config) then return end
    
    -- Ensure that the config required by the module exists.
    if GNIL.Config.Get(partialModule.config) == nil then
        partialModule:log("Required configuration file '" .. partialModule.config .. "' is missing! Disabling module.", "error")
        return false
    end
end)

hook.Add("GNIL.Modules.FirstLoaded", "gnil_config_net_loaded", function(name, module)
    if name != "net" then return end
    
    if SERVER then
        GNIL.Net.AddNetworkString("config_recieve")
    else
        GNIL.Net.ReceiveChunked("config_recieve", function(data)
            
            -- Parse the recieved config file data, return error
            -- back to server if this fails via chunk recv callback.
            local out = util.JSONToTable(data)
            if out == nil then
                return false
            end

            -- Cache the config data as config objects with partial data.
            for k, v in pairs(out) do
                GNIL.Config["_r"][k] = GNIL.Classes.Config:New(k, {
                    realm = "client",
                    config = v
                })
                GNIL.log("Recieved partial config '" .. k .. "' from the server!", "debug")
            end         
        end)
    end
end)