
-- The core directory is loaded in a specific order
-- as some classes inherit from others etc.

local MODULE, core_files = MODULE, {
    "enums",            -- 1. Enums are used anywhere and don't actually add code.
    "validators",       -- 2. Validators can be used anywhere.
    "parser",           -- 3. Used to parse plaintext into HTTP format.
    "message",          -- 4. All HTTP classes subclass Message.
    "request",          
    "response",
    "responses",
    "router",
    "websocket",
    "server"
}
for _, v in ipairs(core_files) do
    MODULE:Include("sv_" .. v .. ".lua")
end