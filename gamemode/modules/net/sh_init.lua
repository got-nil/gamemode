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
    ["_idsize"] = 10
}

-- As the server, we should load the sv_setup file as
-- it defines all the underlying messsage names etc.
if SERVER then
    MODULE:Include("sv_setup.lua")
end
