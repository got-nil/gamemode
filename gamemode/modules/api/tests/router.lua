
-- Uses a nonstandard port to prevent the possibility of
-- some bug trying to set failed responses to a 200 status.
local SUCCESS_STATUS = 005

local function createRouter()
    local router = GNIL.API.Router:New()

    router:Get("/static/abc", function() return GNIL.API.Responses.Empty(SUCCESS_STATUS) end)
    router:Post("/static/def", function() return GNIL.API.Responses.Empty(SUCCESS_STATUS) end)

    router:Get("/static/ghi", function() return GNIL.API.Responses.Empty(1) end)
    router:Post("/static/ghi", function() return GNIL.API.Responses.Empty(2) end)

    router:Get("/static/async", function() return function(fn) timer.Simple(1, function() fn(GNIL.API.Responses.Empty(SUCCESS_STATUS)) end) end end)

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
                expect( state.router:Call(createRequest("GET", "/static/abc")).status ).to.equal(SUCCESS_STATUS)
                expect( state.router:Call(createRequest("POST", "/static/def")).status ).to.equal(SUCCESS_STATUS)
            end
        },
        {
            name = "Route with invalid method returns InvalidMethod",
            func = function(state)
                expect( state.router:Call(createRequest("POST", "/static/abc")).status ).to.equal(405)
                expect( state.router:Call(createRequest("GET", "/static/def")).status ).to.equal(405)
            end
        },
        {
            name = "Routes with same structure but different methods returns success",
            func = function(state)
                expect( state.router:Call(createRequest("GET", "/static/ghi")).status ).to.equal(1)
                expect( state.router:Call(createRequest("POST", "/static/ghi")).status ).to.equal(2)
            end
        },
        {
            name = "Async response returns success",
            async = true,
            timeout = 5,
            func = function(state)
                state.router:Call(createRequest("GET", "/static/async"), function(response)
                    expect( response.status ).to.equal(SUCCESS_STATUS)
                    done()
                end)
            end
        },
        {
            name = "Request content is preserved through router",
            func = function(state)

                local expect = expect
                state.router:Get("/test", function()
                    return GNIL.API.Responses.Text("abcdef", SUCCESS_STATUS)
                end)

                local response = state.router:Call(createRequest("GET", "/test"))
                expect( response.status ).to.equal(SUCCESS_STATUS)
                expect( tostring(response.body) ).to.equal("abcdef")
            end
        },
        {
            name = "Route arguments values passthrough",
            func = function(state)

                local expect = expect
                state.router:Get("/test/{a}/{b:str}/{c:int}", function(request)
                    expect( request.args["a"] ).to.equal("abc")
                    expect( request.args["b"] ).to.equal("def")
                    expect( request.args["c"] ).to.equal(123)

                    return GNIL.API.Responses.Empty(SUCCESS_STATUS)
                end)

                expect ( state.router:Call(createRequest("GET", "/test/abc/def/123")).status ).to.equal(SUCCESS_STATUS)
            end
        },
        {
            name = "Route arguments are typecast",
            func = function(state)

                local expect = expect
                state.router:Get("/test/{a}/{b:str}/{c:int}/{d:steamid64}", function(request)
                    expect( request.args["a"] ).to.beA(TYPE_STRING)
                    expect( request.args["b"] ).to.beA(TYPE_STRING)
                    expect( request.args["c"] ).to.beA(TYPE_NUMBER)
                    expect( request.args["d"] ).to.beA(TYPE_STRING)

                    return GNIL.API.Responses.Empty(SUCCESS_STATUS)
                end)

                expect( state.router:Call(createRequest("GET", "/test/abc/123/456/76561198301284223")).status ).to.equal(SUCCESS_STATUS)
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
                    state.router:Get("/test/" .. k .. "/{a:" .. k .. "}", function() return GNIL.API.Responses.Empty(SUCCESS_STATUS) end)

                    for i, x in ipairs(v) do
                        for _, c in ipairs(x) do
                            expect( state.router:Call(createRequest("GET", "/test/" .. k .. "/" .. c)).status ).to.equal(i == 2 && 400 || SUCCESS_STATUS)
                        end
                    end
                end
            end
        },
        {
            name = "Route is called with weird slash formatting",
            func = function(state)

                expect( state.router:Call(createRequest("GET", "//static//abc//")).status ).to.equal( SUCCESS_STATUS )
                expect( state.router:Call(createRequest("GET", "//static//_//abc")).status ).to.equal( 404 )
            end
        },
        {
            name = "Router converts certain non-response types into responses",
            func = function(state)

                -- Test different return types.
                -- {route_return_value, response_validator}
                local types = {
                    bool = {
                        {true, function(v) return v.status == 200 end},
                        {false, function(v) return v.status == 500 end}
                    },
                    num = {
                        {SUCCESS_STATUS, function(v) return v.status == SUCCESS_STATUS end},
                        {400, function(v) return v.status == 400 end},
                        {503, function(v) return v.status == 503 end}
                    },
                    str = {
                        {"Hello! How are you?", function(v) return v.status == 200 and v.body == "Hello! How are you?" end},
                        {"abc\ndef", function(v) return v.status == 200 and v.body == "abc\ndef" end}
                    }
                }
                for type_name, cases in pairs(types) do
                    for i, v in ipairs(cases) do

                        local route_name = "/converter/" .. type_name .. "/" .. tostring(i)
                        state.router:Get(route_name, function() return v[1] end)

                        local response = state.router:Call(createRequest("GET", route_name))
                        expect( v[2](response) ).to.beTrue()
                    end
                end
            end
        }
    }
}