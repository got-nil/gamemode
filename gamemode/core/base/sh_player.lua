
---@class Player
local PlayerMeta = FindMetaTable("Player")

-- Add IsDeveloper check similar to IsAdmin. Uses the
-- steamid64 information from the server credits table.
local DeveloperSteamIDs = {}
for _, v in ipairs(GNIL._CREDITS) do
    DeveloperSteamIDs[v["id64"]] = true
end

---Check if a player is a developer?
---@return boolean
function PlayerMeta:IsDeveloper()
    return DeveloperSteamIDs[self:SteamID64()] == true
end

---Get the player as a string.
---@param quotes? boolean
---@param steamid? boolean
---@return string
function PlayerMeta:ToString(quotes, steamid)
    return (quotes == false && "" || "'") .. self:Nick() .. (quotes == false && "" || "'") ..
           (steamid == false && "" || (" (" .. self:SteamID() .. ")"))
end

if SERVER then

    ---Log a message on a player (send to their console).
    ---@param log string
    ---@param logtype? string
    function PlayerMeta:log(log, logtype) GNIL.Logging.LogToPlayer(self, log, logtype) end
    PlayerMeta.Log = PlayerMeta.log

    ---Check if the account is using family sharing?
    ---@return boolean
    function PlayerMeta:IsFamilyShared()
        if self:IsBot() then return false end
        return self:SteamID64() != self:OwnerSteamID64()
    end
end