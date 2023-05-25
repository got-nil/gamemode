local MODULE = MODULE

MODULE.name = "Network Layer"
MODULE.author = "morgverd"
MODULE.description = "Just your standard Network Abstraction Layer."

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

-- As the server, we should load the sv_setup file as
-- it defines all the underlying messsage names etc.
if SERVER then
    MODULE:Include("sv_setup.lua")
end

-- Load required classes. Each must be stored globally before the next as
-- the message is used as a baseclass.
if not GNIL.Net.Classes["_loaded"] then
    for k, v in pairs({["Message"] = "sh_message.lua", ["Reply"] = "sh_reply.lua"}) do
        GNIL.Net.Classes[k] = MODULE:Include("classes/" .. v)
    end
    GNIL.Net.Classes["_loaded"] = true
end