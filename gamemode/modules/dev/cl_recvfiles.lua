MODULE, GNIL.Dev = MODULE, GNIL.Dev or {
    ["_files"] = {},
    ["_scripts"] = {
        ["_enabled"] = {},
        ["_out"] = {}
    }
}

-- Toggle developer script states.
function command_callback(_, __, args)
    if #args == 0 then
        MODULE:log("Missing arguments, use: <scriptname> [?state (enable/disable)]", "warning")
        return
    end
    local script = GNIL.Dev["_scripts"]["_out"][args[1]]
    if script == nil then
       MODULE:log("Invalid/Unknown provided developer scriptname.", "warning")
       return
    end

    -- If theres only one argument, return the script status
    -- (is it enabled). If theres multiple then it must 
    -- setting its state (enabled/disabled).
    if #args == 1 then
        MODULE:log("Developer script '" .. script.name .. "' is currently " .. (GNIL.Dev["_scripts"]["_enabled"][script.name] == true && "enabled" || "disabled") .. ".")
    else

        -- The second argument must either be enable or disable.
        if args[2] != "enable" && args[2] != "disable" then
            MODULE:log("Invalid script state argument. Must be either 'enable' or 'disable'.", "warning")
        end

        -- Show a warning if the script state is already as requested.
        local target_state = args[2] == "enable"
        if target_state == (GNIL.Dev["_scripts"]["_enabled"][script.name] == true) then
            MODULE:log("Developer script '" .. script.name .. "' is already " .. (target_state && "enabled" || "disabled") .. "!", "warning")
            return
        end
        
        -- Actually enable/disable the script and store its state.
        GNIL.Dev["_scripts"]["_out"][script.name][target_state && "enable" || "disable"]()
        GNIL.Dev["_scripts"]["_enabled"][script.name] = target_state
        MODULE:log("Successfully " .. (target_state && "enabled" || "disabled") .. " developer script '" .. script.name .. "'!", "success")
    end
    return
end

-- Show script names and possible script states.
function command_autocomplete(cmd, strarg)
    local parts, autocomplete = string.Explode(" ", strarg), {}
    if #parts >= 3 then
        for i, v in ipairs({"enable", "disable"}) do
            autocomplete[i] = cmd .. " " .. parts[2] .. " " .. v
        end
    else
        for i, v in ipairs(table.GetKeys(GNIL.Dev["_scripts"]["_out"])) do
            autocomplete[i] = cmd .. " " .. v
        end
    end
    return autocomplete
end

-- Developer command!
concommand.Add("gnil_dev", command_callback, command_autocomplete)

-- Lowercase any letter, with hyphen and underscore.
local function isSuitableScriptName(name)
    return not string.match(name, "[^a-z_-]") and true or false
end

GNIL.Net.ReceiveChunked("dev_files", function(data)
    if not istable(data) then return end
    if #data % 2 != 0 then return end

    -- First, seperate the filepath that comes before the
    -- filecontent into two seperate tables
    -- (even = filecontent, odd = filepath)
    local out = {{}, {}}
    for i, v in ipairs(data) do
        table.insert(out[i % 2 == 0 && 2 || 1], v)
    end

    -- Execute the dev filecontent and map the return
    -- value to its sent filepath (data prefix).
    local has_errored, files, scripts = false, {}, {}
    for i, v in ipairs(out[1]) do

        -- Execute the filecontent on localplayer and get output (or error).
        local success, out = GNIL.Utils.Execute(out[2][i], "gnil_dev_include")
        MODULE:log((success && "Successfully included" || "Failed to include") .. " developer file '" .. v .. "'" .. (success && "" || (" with error:" .. out)), success && "success" || "error")
        if not success then has_errored = true end

        -- If the return value is a table with a name parameter then its probably
        -- a developer script that should be stored differently.
        local is_script = istable(out)
        if is_script then

            -- Validate and structure the script out table.
            local success, out = GNIL.Validation.Structure(out, {
                ["name"] = {nil, TYPE_STRING, true},
                ["enable"] = {nil, TYPE_FUNCTION, true},
                ["disable"] = {nil, TYPE_FUNCTION, true}
            })

            -- If the script table validation failed, show the error.
            if not success then
                MODULE:log("Failed to validate developer script '" .. v .. "' with error: " .. out, "error")
                continue
            end

            -- The script must have a suitable scriptname. 
            if not isSuitableScriptName(out.name) then
                MODULE:log("Unsuitable scriptname '" .. out.name .. "' for developer file '" .. v .. "', skipping.", "warning")
                continue
            end
            
            -- If the filepath is already stored and its a script
            -- then it should be unloaded as its about to be overwritten.
            -- The script is stored as the file output and can be accessed there.
            if GNIL.Dev["_files"][v] && GNIL.Dev["_files"][v][1] then
                
                -- Check if the module is actually enabled.
                local is_enabled = GNIL.Dev["_scripts"]["_enabled"][GNIL.Dev["_files"][v][2].name] == true
                MODULE:log((is_enabled && "Currently enabled developer script" || "Disabled developer script") .. " '" .. GNIL.Dev["_files"][v][2].name .. "' is being reloaded.", is_loaded && "warning" || "info")

                -- If it actually is currently enabled, then disable it.
                if is_enabled then
                    GNIL.Dev["_files"][v][2].disable()
                end
            end

            -- Store the script data to be called later.
            GNIL.Dev["_scripts"]["_out"][out.name] = out
        end

        -- Store if its a script or not as the first index instead
        -- of contantly having to use istable (ickky ewwwww).
        -- Do not store nil for no response, default to false.
        files[v] = {is_script, out != nil && out || false}
    end

    -- Cache the files output 
    GNIL.Dev["_files"] = files
end)
