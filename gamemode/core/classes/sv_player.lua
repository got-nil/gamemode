local PlayerMeta = FindMetaTable("Player")

-- Allow for logging directly to a player instance
function PlayerMeta:log(log, logtype) GNIL.Logging.LogToPlayer(self, log, logtype) end
PlayerMeta.Log = PlayerMeta.log

-- Add IsDeveloper check similar to IsAdmin. Uses the
-- steamid64 information from the server credits table.
local DeveloperSteamIDs = {}
for _, v in ipairs(GNIL._CREDITS) do
    DeveloperSteamIDs[v["id64"]] = true
end
function PlayerMeta:IsDeveloper()
    return DeveloperSteamIDs[self:SteamID64()] == true
end

function PlayerMeta:ToString(quotes, steamid)
    return (quotes == false && "" || "'") .. self:Nick() .. (quotes == false && "" || "'") ..
           (steamid == false && "" || (" (" .. self:SteamID() .. ")"))
end