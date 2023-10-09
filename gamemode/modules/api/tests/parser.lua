
return {
    groupName = "Parser",

    cases = {
        {
            name = "Query arguments should parse",
            func = function()
                local expected = {
                    ["a"] = "a1",
                    ["b"] = "b2",
                    ["c"] = "c3"
                }
                local out = GNIL.API.Parser.Query("a=a1&b=b2&c=c3")
                for k, v in pairs(expected) do
                    expect(v).to.equal(out[k])
                end
            end
        },
        {
            name = "Query arguments sequential table parse",
            func = function()
                local expected = {
                    ["a"] = {"a", "b", "c"},
                    ["b"] = {"e"}
                }
                local out = GNIL.API.Parser.Query("a[]=a&a[]=b&a[]=c&b[]=e")
                for k, v in pairs(expected) do
                    for i, x in ipairs(v) do
                        expect(x).to.equal(out[k][i])
                    end
                end
            end
        },
        {
            name = "Parse route without arguments",
            func = function()
                local out = GNIL.API.Parser.Route("/abc/def/ghi")
                local expected = {
                    {GNIL_API_ARGUMENT_STR, "abc"},
                    {GNIL_API_ARGUMENT_STR, "def"},
                    {GNIL_API_ARGUMENT_STR, "ghi"}
                }
                for k, v in ipairs(expected) do
                    for i, x in ipairs(v) do
                        expect(x).to.equal(out[k][i])
                    end
                end
            end
        },
        {
            name = "Parse route with arguments",
            func = function()
                local out = GNIL.API.Parser.Route("/{abc:str}/{def:int}/ghi")
                local expected = {
                    {GNIL_API_ARGUMENT_ARG, "abc", "str"},
                    {GNIL_API_ARGUMENT_ARG, "def", "int"},
                    {GNIL_API_ARGUMENT_STR, "ghi"}
                }
                for k, v in ipairs(expected) do
                    for i, x in ipairs(v) do
                        expect(x).to.equal(out[k][i])
                    end
                end
            end
        },
        {
            name = "Parse raw path",
            func = function()
                local path, query = GNIL.API.Parser.ParseRawPath("/abc/def?ghi=jkl")
                expect(path).to.equal("/abc/def")
                expect(query["ghi"]).to.equal("jkl")
            end
        }
    }
}