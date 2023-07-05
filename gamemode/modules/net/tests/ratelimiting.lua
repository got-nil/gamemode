
local dTimer = GNIL.Thirdparty.detachedtimer
local function emptyBucket(bucket)
    for i = 1, bucket.capacity do
        if not bucket:Check("steamid") then
            return false
        end
    end
    return not bucket:Check("steamid")
end

return {
    groupName = "Ratelimiting",

    beforeEach = function(state)
        state.bucket = GNIL.Net.Classes.Bucket:New(3, 1, 1)
    end,

    cases = {
        {
            name = "Should allow non ratelimited access",
            func = function(state)
                expect(state.bucket:Check("steamid")).to.beTrue()
            end
        },
        {
            name = "Should limit bucket overflows",
            func = function(state)

                -- Empty the bucket.
                expect(emptyBucket(state.bucket)).to.beTrue()
                expect(state.bucket:Check("steamid")).to.beFalse()
            end
        },
        {
            name = "Should refill a limited bucket",
            async = true,
            timeout = 5,
            func = function(state)
                
                -- Empty the bucket.
                expect(emptyBucket(state.bucket)).to.beTrue()

                -- After one second, one token should have been refilled.
                dTimer.Simple(1, function()
                    expect(state.bucket:Check("steamid")).to.beTrue()
                    expect(state.bucket:Check("steamid")).to.beFalse()
                    done()
                end)
            end
        },
        {
            name = "Should refill tokens sequentially",
            async = true,
            timeout = 10,
            func = function(state)

                -- Increase bucket capacity and empty it.
                state.bucket.capacity = 10
                expect(emptyBucket(state.bucket)).to.beTrue()

                -- Test refill multiple times.
                for i = 1, 5 do
                    dTimer.Simple(i, function()

                        -- There should be one token refilled.
                        expect(state.bucket:Check("steamid")).to.beTrue()
                        expect(state.bucket:Check("steamid")).to.beFalse()

                        if i == 5 then done() end
                    end)
                end
            end
        },
        {
            name = "Should refill tokens bulk",
            async = true,
            timeout = 10,
            func = function(state)

                -- Increase bucket capacity and decrease refill_delay,
                -- this should cause the bucket to refill fully in 5 seconds. 
                state.bucket.capacity = 10
                state.bucket.refill_delay = 0.5
                expect(emptyBucket(state.bucket)).to.beTrue()

                -- After 5 seconds, the bucket should be full.
                dTimer.Simple(5, function()
                    expect(emptyBucket(state.bucket)).to.beTrue()
                    done()
                end)
            end
        }
    }
}