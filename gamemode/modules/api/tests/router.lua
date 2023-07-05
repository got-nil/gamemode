
local function createRouter()
    local router = GNIL.API.Router:New()

    router:Get("/abc", function() return GNIL.API.Responses.Empty(200) end)
    router:Post("/def", function() return GNIL.API.Responses.Empty(200) end)
    
    router:Get("/ghi", function() return GNIL.API.Responses.Empty(1) end)
    router:Post("/ghi", function() return GNIL.API.Responses.Empty(2) end)

    router:Get("/async", function() return function(fn) timer.Simple(1, function() fn(GNIL.API.Responses.Empty(200)) end) end end)

    return router
end

local function createRequest(...) return GNIL.API.Request:New(...) end
local function isStatus(response, status)
    if response == nil then return false end
    return response.status == status
end

return {
    groupName = "Router",
    
    beforeEach = function(state)
        state.router = createRouter()
    end,

    cases = {
        {
            name = "Unknown route returns NotFound response.",
            func = function(state)
                expect(isStatus(state.router:Call(createRequest("GET", "/unknown")), 404)).to.beTrue()
            end
        },
        {
            name = "Route with valid method returns success.",
            func = function(state)
                expect(isStatus(state.router:Call(createRequest("GET", "/abc")), 200)).to.beTrue()
                expect(isStatus(state.router:Call(createRequest("POST", "/def")), 200)).to.beTrue()
            end
        },
        {
            name = "Route with invalid method returns InvalidMethod.",
            func = function(state)
                expect(isStatus(state.router:Call(createRequest("POST", "/abc")), 405)).to.beTrue()
                expect(isStatus(state.router:Call(createRequest("GET", "/def")), 405)).to.beTrue()
            end
        },
        {
            name = "Routes with same structure but different methods returns success.",
            func = function(state)
                expect(isStatus(state.router:Call(createRequest("GET", "/ghi")), 1)).to.beTrue()
                expect(isStatus(state.router:Call(createRequest("POST", "/ghi")), 2)).to.beTrue()
            end
        },
        {
            name = "Async response returns success.",
            async = true,
            timeout = 5,
            func = function(state)
                state.router:Call(createRequest("GET", "/async"), function(response)
                    expect(isStatus(response, 200)).to.beTrue()
                    done()
                end)
            end
        }
    }
}