
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

return {
    groupName = "Router",
    
    beforeEach = function(state)
        state.router = createRouter()
    end,

    cases = {
        {
            name = "Unknown route returns NotFound response",
            func = function(state)
                expect( state.router:Call(createRequest("GET", "/unknown")).status ).to.equal(404)
            end
        },
        {
            name = "Route with valid method returns success",
            func = function(state)
                expect( state.router:Call(createRequest("GET", "/abc")).status ).to.equal(200)
                expect( state.router:Call(createRequest("POST", "/def")).status ).to.equal(200)
            end
        },
        {
            name = "Route with invalid method returns InvalidMethod",
            func = function(state)
                expect( state.router:Call(createRequest("POST", "/abc")).status ).to.equal(405)
                expect( state.router:Call(createRequest("GET", "/def")).status ).to.equal(405)
            end
        },
        {
            name = "Routes with same structure but different methods returns success",
            func = function(state)
                expect( state.router:Call(createRequest("GET", "/ghi")).status ).to.equal(1)
                expect( state.router:Call(createRequest("POST", "/ghi")).status ).to.equal(2)
            end
        },
        {
            name = "Async response returns success",
            async = true,
            timeout = 5,
            func = function(state)
                state.router:Call(createRequest("GET", "/async"), function(response)
                    expect( response.status ).to.equal(200)
                    done()
                end)
            end
        },
        {
            name = "Route arguments are typecast",
            func = function(state)

                local expect = expect
                state.router:Get("/types/{a}/{b:str}/{c:int}/{d:steamid64}", function(request)
                    expect( request.args["a"] ).to.beA(TYPE_STRING)
                    expect( request.args["b"] ).to.beA(TYPE_STRING)
                    expect( request.args["c"] ).to.beA(TYPE_NUMBER)
                    expect( request.args["d"] ).to.beA(TYPE_STRING)
                    
                    return GNIL.API.Responses.Empty(200)
                end)

                expect( state.router:Call(createRequest("GET", "/types/abc/123/456/76561198301284223")).status ).to.equal(200)
            end
        },
        {
            name = "Route arguments reject invalid types",
            func = function(state)
                
                -- 1 = Valid arguments
                -- 2 = Invalid arguments
                local tests = {
                    int = {
                        {"1", "10", "01"},
                        {"f", "10.50", "@", "-10"}
                    },
                    str = {
                        {"a", "b", "c"}
                    },
                    steamid64 = {
                        {"76561198301284223", "76561198022787311"},
                        {"100", "200", "steamid", "5656119803627873161"}
                    }
                }

                for k, v in pairs(tests) do
                    
                    -- Create test route with typed argument.
                    state.router:Get("/" .. k .. "/{a:" .. k .. "}", function() return GNIL.API.Responses.Empty(200) end)

                    for i, x in ipairs(v) do
                        for _, c in ipairs(x) do
                            expect( state.router:Call(createRequest("GET", k .. "/" .. c)).status ).to.equal(i == 2 && 400 || 200)
                        end
                    end
                end
            end
        }
    }
}