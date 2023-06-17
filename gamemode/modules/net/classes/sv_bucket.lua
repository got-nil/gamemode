local MODULE = MODULE

-- An implementation of Token Bucket ratelimiting.
-- https://en.wikipedia.org/wiki/Token_bucket

local Bucket = GNIL.Thirdparty.middleclass("Bucket")

function Bucket:Initialize(max, delay)
    self.max = max
    self.delay = delay
    self._data = {}

    -- ply: {bucket, last_check}
end

AccessorFunc(Bucket, "max", "Max", FORCE_NUMBER)
AccessorFunc(Bucket, "delay", "Delay", FORCE_NUMBER)

function Bucket:Check(steamid)    
    if IsPlayer(steamid) then
        steamid = tostring(steamid:SteamID64())
    end
    
    -- If the player does not yet have a ratelimit, they're passing.
    local player_data = self._data[steamid]
    if not player_data then
        self._data[steamid] = {self.max, RealTime()}
        return true
    end
    
    -- Get the players new bucket value.
    local time_passed = RealTime() - player_data[2]
    local bucket = player_data[1] + time_passed * (self.max / self.delay)
    
    GNIL.log("bucket: " .. tostring(bucket), "warning")
    if bucket > self.max then
        bucket = self.max
    end
    if bucket < 1 then
        return false
    else
        bucket = bucket - 1
    end

    self._data[steamid] = {bucket, RealTime()}
    return true
end

-- Remove given steamid from the bucket cache.
function Bucket:Remove(steamid)
    self._data[steamid] = nil
end

return Bucket

