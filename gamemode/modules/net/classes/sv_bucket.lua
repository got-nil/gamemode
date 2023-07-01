local MODULE = MODULE

-- An implementation of Token Bucket ratelimiting.
-- https://en.wikipedia.org/wiki/Token_bucket

local Bucket = GNIL.Thirdparty.middleclass("Bucket")

function Bucket:Initialize(capacity, refill_delay, refill_amount)
    self.capacity = capacity
    self.refill_delay = refill_delay
    self.refill_amount = refill_amount

    self._data = {}
    -- ply: {bucket, last_check}
end

AccessorFunc(Bucket, "refill_amount", "RefillAmount", FORCE_NUMBER)
AccessorFunc(Bucket, "refill_delay", "RefillPeriod", FORCE_NUMBER)

-- Used to verify that a bucket matches provided bucket settings.
-- Prevents a bucket from being needlessly reset with the same conf.
function Bucket:IsSame(capacity, refill_delay, refill_amount)
    return self.capacity == capacity and self.refill_delay == refill_delay and self.refill_amount == refill_amount
end

function Bucket:Check(steamid, requested_tokens)
    if IsPlayer(steamid) then
        steamid = tostring(steamid:SteamID64())
    end
    
    -- If the player does not yet have a ratelimit, they're passing.
    local now = RealTime()
    if not self._data[steamid] then
        self._data[steamid] = {self.capacity, now}
        return true
    end
    
    -- Get current bucket state and calculate elapsed time since last refill.
    local tokens, last_refill_time = unpack(self._data[steamid])
    local elapsed = now - last_refill_time

    -- Refill the bucket if needed.
    if elapsed > 0 then
        local refill = math.floor(elapsed / self.refill_delay) * self.refill_amount
        tokens = math.min(self.capacity, tokens + refill)
        self._data[steamid] = {tokens, now}
    end

    -- Check that there are enough tokens in the bucket.
    requested_tokens = requested_tokens or 1
    if tokens >= requested_tokens then
        self._data[steamid][1] = tokens - requested_tokens
        return true
    end
    return false
end

-- Remove given steamid from the bucket cache.
function Bucket:Remove(steamid)
    self._data[steamid] = nil
end

return Bucket

