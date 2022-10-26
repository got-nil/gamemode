
local PlayerMeta = FindMetaTable("Player")

-- Allow for logging directly to a player instance
function PlayerMeta:log(log, logtype)
    GNIL.Logging.LogToPlayer(self, log, logtype)
end