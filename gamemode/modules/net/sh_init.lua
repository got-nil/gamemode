local MODULE = MODULE

MODULE.name = "Network Layer"
MODULE.author = "morgverd"
MODULE.description = "Just your standard Network Abstraction Layer."
MODULE.tests = true

GNIL.Net = GNIL.Net or {
    ["_r"] = {}, -- Network ID registry, mirrored between client and server.
    ["_c"] = {}, -- Network ID receiver callbacks.
    ["_i"] = {}, -- Network string to ID cache (_r, but reversed).

    -- This is the size of the network ID that is used for reading/writing the
    -- ID header uint. Default 10 means a max of 1023 individual net messages.
    ["_idsize"] = 10,

    -- Should network messages be recieved? This applies to all messages including
    -- those using the normal net system. *ONLY APPLIES FOR THE SERVER*.
    ["_receive"] = true,

    -- Initialize empty classes set.
    ["Classes"] = {
        ["_loaded"] = false
    }
}

-- Ensure the configured idsize isn't too big.
if SERVER and GNIL.Net["_idsize"] > 32 then
    MODULE:log("The configured idsize is too large! (Current: " .. tostring(GNIL.Net["_idsize"]) .. ", Maximum: 32)", "error")
    MODULE:SetDisabled(true)
    return
end

MODULE.OnLoad = function()
    if SERVER then

        -- Required server base.
        MODULE:Include("sv_network.lua")
        MODULE:Include("sv_antiabuse.lua")
    end

    -- Load required classes. Could use DirectoryMap, but the classes
    -- have different names. Maybe eventually make an interface for this?
    if not GNIL.Net.Classes["_loaded"] then

        -- Looks weird, but this is to ensure the load order is preserved.
        local classes = {
            {"WriteableMixin", "sh_writeable"},
            {"Message", "sh_message"},
            {"Reply", "sh_reply"},
            {"Bucket", "sv_bucket"},
            {"Readable", "sv_readable"}
        }
        for _, v in ipairs(classes) do
            local filename = v[2] .. ".lua"
            GNIL.Net.Classes[v[1]] = MODULE:Include("classes/" .. filename)
        end
        GNIL.Net.Classes["_loaded"] = true
    end
end

MODULE.OnLoadFinished = function()

    -- Cache max net messages for warning.
    GNIL.Net["_max_messages"] = GNIL.Net.Helpers.GetBitcountMaxValue(GNIL.Net["_idsize"], true)
    MODULE:log("Configured idsize supports a maximum of " .. tostring(GNIL.Net["_max_messages"]) .. " individual messages.", "debug")
end