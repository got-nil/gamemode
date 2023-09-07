return {
    groupName = "Events Mixin",

    beforeEach = function(state)
        state.Class = GNIL.Thirdparty.middleclass("TestClass"):IncludeMixin(GNIL.ClassMixins.Events)
    end,

    cases = {
        {
            name = "Listeners are called",
            func = function(state)
                local class = state.Class:New()
                local A, B, C = false, false, false
                local D, E, F = false, false, false

                class:AddEventListener("A", function() A = true end)
                class:AddEventListener("B", function() B = true end)
                class:AddEventListener("C", function() C = true end)

                class:AddSignalListener("A", function() D = true end)
                class:AddSignalListener("B", function() E = true end)
                class:AddSignalListener("C", function() F = true end)

                class:EmitEvent("A")
                class:EmitEvent("B")
                class:EmitEvent("C")

                expect( A ).to.beTrue() expect( B ).to.beTrue()
                expect( C ).to.beTrue() expect( D ).to.beTrue()
                expect( E ).to.beTrue() expect( F ).to.beTrue()
            end
        },
        {
            name = "Event listener only calls once",
            func = function(state)
                local class = state.Class:New()
                local A, B, C = 0, 0, 0

                class:AddEventListener("event", function() A = A + 1 end)
                class:AddSignalListener("signal", function() B = B + 1 end)
                
                class:AddEventListener("both", function() C = C + 1 end)
                class:AddSignalListener("both", function() C = C + 1 end)

                class:EmitEvent("event")
                class:EmitEvent("signal")
                class:EmitEvent("both")

                expect( A ).to.equal(1)
                expect( B ).to.equal(1)
                expect( C ).to.equal(2)
            end
        },
        {
            name = "Event listener value is returned in order",
            func = function(state)
                local class, A = state.Class:New(), false

                class:AddEventListener("A", function() A = true end)
                class:AddEventListener("A", function() return "abc" end)
                class:AddEventListener("A", function() return "def" end)

                expect( class:EmitEvent("A") ).to.equal("abc")
                expect( A ).to.beTrue()
            end
        },
        {
            name = "Function events are called first",
            func = function(state)
                local TestClass, A = state.Class, 0
                function TestClass:OnTest() A = 5 end

                -- If OnA() + below is called A = 6
                local class = TestClass:New()
                class:AddEventListener("test", function() A = A + 1 end)
                
                expect( class:EmitEvent("test") ).to.beNil()
                expect( A ).to.equal(6)
            end
        },
        {
            name = "Function events returns priority over listeners",
            func = function(state)
                local TestClass, A, B = state.Class, false, false
                function TestClass:OnStatic() return "abc" end
                
                local class = TestClass:New()
                class:AddEventListener("static", function() A = true return "def" end)
                class:AddSignalListener("static", function() B = true return "ghi" end)

                expect( class:EmitEvent("static") ).to.equal("abc")
                expect( A ).to.beFalse()
                expect( B ).to.beTrue()
            end
        },
        {
            name = "Event arguments passthrough",
            func = function(state)
                local TestClass = state.Class
                local A, B, C, D = false, false, false, false

                function TestClass:OnStatic1(x) return x end
                function TestClass:OnStatic2(x) A = x end

                local class = TestClass:New()
                class:AddEventListener("Event", function(x) return x end)
                class:AddSignalListener("Other", function(x) B = x end)

                class:AddSignalListener("static1", function(x) C = x end)
                class:AddSignalListener("static2", function(x) D = x end)

                expect( class:EmitEvent("static1", "abc") ).to.equal("abc")
                expect( class:EmitSignal("static2", "def") ).to.beNil()
                expect( class:EmitEvent("event", "ghi") ).to.equal("ghi")
                expect( class:EmitSignal("other", "lmn") ).to.beNil()

                expect( A ).to.equal("def") expect( B ).to.equal("lmn")
                expect( C ).to.equal("abc") expect( D ).to.equal("def")                
            end
        },
        {
            name = "Event listener can return if function event doesnt",
            func = function(state)
                local TestClass = state.Class
                local A, B, C = false, false, false
                local D, E, F = false, false, false
                
                function TestClass:OnStatic() A = true end
                
                local class = TestClass:New()
                class:AddEventListener("static", function() B = true end)
                class:AddEventListener("static", function() C = true return "abc" end)
                class:AddEventListener("static", function() F = true end) -- this shouldn't be called
                
                class:AddSignalListener("static", function() D = true return "def" end)
                class:AddSignalListener("static", function() E = true return "ghi" end)

                expect( class:EmitEvent("static") ).to.equal("abc")
                expect( A ).to.beTrue() expect( B ).to.beTrue()
                expect( C ).to.beTrue() expect( D ).to.beTrue()
                expect( E ).to.beTrue() expect( F ).to.beFalse()
            end
        }
    }
}