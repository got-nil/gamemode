local MODULE = MODULE

-- https://en.wikipedia.org/wiki/Token_bucket

---An implementation of Token Bucket ratelimiting.
---@class Net.Bucket: middleclass
---@field capacity number How many tokens to allow max.
---@field refill_delay number The delay between refills.
---@field refill_amount number How much tokens to re-add per refill.
local Bucket = GNIL.Thirdparty.middleclass("Bucket")
ClassAccessorFunc(Bucket, {
    RefillAmount = {"refill_amount", FORCE_NUMBER}, ---@accessor number
    RefillPeriod = {"refill_delay", FORCE_NUMBER} ---@accessor number
})

---@param capacity number
---@param refill_delay number
---@param refill_amount number
function Bucket:Initialize(capacity, refill_delay, refill_amount)
    self.capacity = capacity
    self.refill_delay = refill_delay
    self.refill_amount = refill_amount

    self._data = {}
    -- ply: {bucket, last_check}
end

---Used to verify that a bucket matches provided bucket settings.
---Prevents a bucket from being needlessly reset with the same conf.
---@param capacity number
---@param refill_delay number
---@param refill_amount number
---@return boolean
function Bucket:IsSame(capacity, refill_delay, refill_amount)
    return self.capacity == capacity and self.refill_delay == refill_delay and self.refill_amount == refill_amount
end

---Check if a SteamID64 has been limited by the bucket.
---@param steamid string|Player
---@param requested_tokens? number
---@return boolean
function Bucket:Check(steamid, requested_tokens)
    requested_tokens = requested_tokens or 1
    if IsPlayer(steamid) then --- @cast steamid Player
        steamid = tostring(steamid:SteamID64())
    end


    -- If the player does not yet have a ratelimit, they're passing.
    local now = SysTime()
    if not self._data[steamid] then
        self._data[steamid] = {self.capacity - requested_tokens, now}
        return true
    end

    -- Get current bucket state and calculate elapsed time since last refill.
    local tokens, last_refill_time = unpack(self._data[steamid])
    local elapsed = now - last_refill_time

    -- Refill the bucket if needed.
    if elapsed < 1 and elapsed >= 0.9 then elapsed = 1 end
    if elapsed > 0 then
        local refill = math.floor(elapsed / self.refill_delay) * self.refill_amount
        tokens = math.min(self.capacity, tokens + refill)
        self._data[steamid] = {tokens, now}
    end

    -- Check that there are enough tokens in the bucket.
    if tokens >= requested_tokens then
        self._data[steamid][1] = tokens - requested_tokens
        return true
    end
    return false
end

function Bucket:Empty(steamid) self._data[steamid] = {0, SysTime()} end
function Bucket:Remove(steamid) self._data[steamid] = nil end

return Bucket

