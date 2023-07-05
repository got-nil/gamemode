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

    -- Load required classes. Each must be stored globally before the next as
    -- the message is used as a baseclass.
    if not GNIL.Net.Classes["_loaded"] then
        for _, v in ipairs({{"Message", "sh_message.lua"}, {"Reply", "sh_reply.lua"}, {"Bucket", "sv_bucket.lua"}}) do
            if not GNIL.Utils.IsFilenameForCurrentRealm(v[2]) then continue end
            GNIL.Net.Classes[v[1]] = MODULE:Include("classes/" .. v[2])
        end
        GNIL.Net.Classes["_loaded"] = true
    end
end

MODULE.OnLoadFinished = function()

    -- Cache max net messages for warning.
    GNIL.Net["_max_messages"] = GNIL.Net.Helpers.GetBitcountMaxValue(GNIL.Net["_idsize"], true)
    MODULE:log("Configured idsize supports a maximum of " .. tostring(GNIL.Net["_max_messages"]) .. " individual messages.", "debug")
end 