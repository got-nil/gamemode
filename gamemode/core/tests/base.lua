
-- I intend to use ClassAccessorFunc quite a bit since its fairly
-- useful for class accessing. Since it supports multiple features
-- its important that they're properly tested for regression testing.

return {
    groupName = "Base",

    beforeEach = function(state)
        state.Class = GNIL.Thirdparty.middleclass("TestClass")
    end,

    cases = {
        {
            name = "ClassAccessorFunc FORCEs value type",
            func = function(state)

                ClassAccessorFunc(state.Class, {
                    A = "a",
                    B = {"b", FORCE_NUMBER},
                    C = {
                        var = "d",
                        force = FORCE_COLOR
                    },
                    _set_return_self = false
                })

                local obj = state.Class:New()

                expect( obj:GetA() ).to.beNil()
                expect( obj:SetA("abc") ).to.beTrue()
                expect( obj:GetA("def") ).to.equal( "abc" )
                expect( obj:SetA(123) ).to.beTrue()
                expect( obj:GetA("123") ).to.beA( TYPE_NUMBER )

                expect( obj:GetB() ).to.beNil()
                expect( obj:GetB("abc") ).to.equal( "abc" )
                expect( obj:SetB("123") ).to.beTrue()
                expect( obj:GetB() ).to.equal( 123 )
                expect( obj:GetB() ).to.beA( TYPE_NUMBER )

                local color_a = Color(123, 123, 123)
                local vector_b, color_b = Vector(321, 321, 321), Color(321, 321, 321)

                expect( obj:GetC() ).to.beNil()
                expect( obj:SetC(color_a) ).to.beTrue()
                expect( obj:GetC(vector_b) ).to.equal( color_a )
                expect( obj:SetC(vector_b) ).to.beTrue()
                expect( obj:GetC(color_a) ).to.equal( color_b )
            end
        },
        {
            name = "ClassAccessorFunc Getter/Setter can be disabled",
            func = function(state)

                ClassAccessorFunc(state.Class, {
                    A = {
                        var = "a",
                        set = true,
                        get = false
                    },
                    B = {
                        var = "b",
                        set = false,
                        get = true
                    }
                })
                
                local obj = state.Class:New()

                expect( obj.SetA ).to.exist()
                expect( obj.GetA ).to.beNil()
                
                expect( obj.SetB ).to.beNil()
                expect( obj.GetB ).to.exist()
            end
        },
        {
            name = "ClassAccessorFunc Getter/Setter is called",
            func = function(state)

                local A_SET, A_GET = false, false
                local B_GET = false

                ClassAccessorFunc(state.Class, {
                    A = {
                        var = "a",
                        set = function() A_SET = true end,
                        get = function() A_GET = true return "abc" end
                    },
                    B = {
                        var = "b",
                        get = function(self, __, out) B_GET = true return self[out.var] end
                    },
                    _set_return_self = false
                })

                local obj = state.Class:New()

                expect( obj:SetA("abc") ).to.beTrue()
                expect( obj:GetA("def") ).to.equal( "abc" )
                expect( A_SET and A_GET ).to.beTrue()

                expect( obj:SetB("abc") ).to.beTrue()
                expect( obj:GetB("def") ).to.equal( "abc" )
                expect( B_GET ).to.beTrue()
            end
        },
        {
            name = "ClassAccessorFunc additional options",
            func = function(state)

                ClassAccessorFunc(state.Class, {
                    A = {
                        var = "a",
                        force = FORCE_BOOL,
                        nillable = true
                    },
                    B = {
                        var = "b",
                        force = FORCE_STRING,
                        validate = function(_, v)
                            return v == "abc"
                        end
                    },
                    _set_return_self = false
                })

                local obj = state.Class:New()

                expect( obj:SetA(true) ).to.beTrue()
                expect( obj:GetA(false) ).to.beTrue()
                expect( obj:SetA(nil) ).to.beTrue()
                expect( obj:GetA("abc") ).to.beFalse()

                expect( obj:SetB("abc") ).to.beTrue()
                expect( obj:GetB("def") ).to.equal( "abc" )
                expect( obj:SetB("def") ).to.beFalse()
                expect( obj:GetB("ghi") ).to.equal( "abc" )
            end
        },
        {
            name = "ClassAccessorFunc FuncAccessors",
            func = function(state)

                ClassAccessorFunc(state.Class, {
                    A = FuncAccessors.ReadOnly("a"),
                    B = FuncAccessors.NumberMinMax("b", 3, 5),
                    C = FuncAccessors.Boolean("c"),
                    _set_return_self = false
                })

                local obj = state.Class:New()

                expect( obj.SetA ).to.beNil() expect( obj.GetA ).to.exist() expect( obj.IsA ).to.beNil()
                expect( obj.SetB ).to.exist() expect( obj.GetB ).to.exist() expect( obj.IsB ).to.beNil()
                expect( obj.GetC ).to.beNil() expect( obj.SetC ).to.exist() expect( obj.IsC ).to.exist()

                for _, v in ipairs({1, 2, 6, 7}) do
                    expect( obj:SetB(v) ).to.beFalse()
                    expect( obj:GetB() ).to.beNil()
                end

                expect( obj:SetB(4) ).to.beTrue()
                expect( obj:GetB() ).to.equal( 4 )

                expect( obj:SetC(true) ).to.beTrue()
                expect( obj:IsC() ).to.beTrue()
                expect( obj:SetC(false) ).to.beTrue()
                expect( obj:IsC() ).to.beFalse()
            end
        },
        {
            name = "ClassAccessorFunc InstanceOf FuncAccessor",
            func = function(state)

                local targetClassA = GNIL.Thirdparty.middleclass("TargetA")
                local targetClassB = GNIL.Thirdparty.middleclass("TargetB")

                ClassAccessorFunc(state.Class, {
                    A = FuncAccessors.InstanceOf("a", targetClassA),
                    B = FuncAccessors.InstanceOf("b", function()
                        return targetClassB
                    end),
                    _set_return_self = false
                })

                local obj = state.Class:New()
                local a, b = targetClassA:New(), targetClassB:New()
            
                expect( obj.SetA ).to.exist() expect( obj.GetA ).to.exist() expect( obj.IsA ).to.beNil()
                expect( obj.SetB ).to.exist() expect( obj.GetB ).to.exist() expect( obj.IsB ).to.beNil()

                expect( obj:SetA(b) ).to.beFalse() expect( obj:GetA() ).to.beNil()
                expect( obj:SetA(a) ).to.beTrue() expect( obj:GetA() ).to.equal( a )
                expect( obj:SetB(a) ).to.beFalse() expect( obj:GetB() ).to.beNil()
                expect( obj:SetB(b) ).to.beTrue() expect( obj:GetB() ).to.equal( b )
            end
        },
        {
            name = "ClassAccessorFunc global defaults apply",
            func = function(state)

                ClassAccessorFunc(state.Class, {

                    A = {
                        var = "a",
                        get = function(self, _, args)
                            return args.force == FORCE_STRING and args.nillable == true
                        end
                    },
                    B = {
                        var = "b",
                        force = FORCE_NUMBER,
                        validate = function(self, _, args)
                            return args.force == FORCE_NUMBER and args.nillable == true
                        end,
                        get = true,
                        set_return_self = false
                    },
                    C = {
                        var = "c",
                        nillable = false,
                        set = function(self, _, args)
                            return args.force == FORCE_STRING and args.nillable == false
                        end,
                        get = true,
                        set_return_self = false
                    },
                    D = "d",

                    _set_return_self = true,
                    _force = FORCE_STRING,
                    _nillable = true,
                    _get = function()
                        return 456
                    end
                })

                local obj = state.Class:New()

                expect( obj:SetA("abc") ).to.equal( obj )
                expect( obj:GetA("def") ).to.beTrue()
                expect( obj.a ).to.equal( "abc" )
                
                expect( obj:SetB("123") ).to.beTrue()
                expect( obj:GetB(789) ).to.equal( 123 )
                
                expect( obj:SetC("abc") ).to.beTrue()
                expect( obj:GetC() ).to.beNil()

                expect( obj:SetD("def") ).to.equal( obj )
                expect( obj:GetD() ).to.equal( 456 )
                expect( obj.d ).to.equal( "def" )
            end
        },
        {
            name = "ClassAccessorFunc Set returns self",
            func = function(state)

                ClassAccessorFunc(state.Class, {
                    A = "a"
                })

                local obj = state.Class:New()

                expect( obj:SetA("abc") ).to.equal( obj )
                expect( obj:SetA("abc"):SetA("def") ).to.equal( obj )
                expect( obj:GetA() ).to.equal( "def" )
            end
        },
        {
            name = "SafeTableAccess works properly",
            func = function()

                expect( _G["SafeTableAccess"] ).to.exist()
                
                local tbl = {
                    A = {
                        B = {
                            C = "a",
                        },
                        D = false,
                        E = {
                            [1] = "a",
                            [2] = "b"
                        }
                    },
                    F = nil
                }

                expect( SafeTableAccess(tbl, "A", "B", "C") ).to.equal( tbl.A.B.C )
                expect( SafeTableAccess(tbl, "A", "D") ).to.equal( tbl.A.D )
                expect( SafeTableAccess(tbl, "A", "E", 2) ).to.equal( tbl.A.E[2] )
                expect( SafeTableAccess(tbl, "F") ).to.equal( tbl.F )
            end
        },
        {
            name = "Timeout class resolves correctly",
            async = true,
            func = function()

                -- The timeout should still resolve immidiately 
                -- despite the timeout being longer.

                local timeout = GNIL.Classes.Timeout:New(3)
                expect( timeout ).to.exist()

                local start = math.Round(os.time())
                local done, expect = done, expect
                timeout:OnResolve(function() 
                
                        expect( math.Round(os.time() - start) ).to.equal( 0 )
                        done()

                    end)
                    :OnTimeout(function() error("This should not be called!") end)
                    :Run(function(resolve)
                    
                        expect( resolve ).to.beA( TYPE_FUNCTION )
                        expect( resolve() ).to.succeed() 

                    end)
            end
        },
        {
            name = "Timeout class times out correctly",
            async = true,
            func = function()

                local timeout = GNIL.Classes.Timeout:New(3)
                expect( timeout ).to.exist()

                local start = math.Round(os.time())
                local done, expect = done, expect
                timeout:OnResolve(function() error("This should not be called!") end)
                    :OnTimeout(function()
                    
                        expect( math.Round(os.time() - start) ).to.equal( 3 )
                        done()

                    end)
                    :Run(function() end) -- do nothing
            end
        }
    }
}