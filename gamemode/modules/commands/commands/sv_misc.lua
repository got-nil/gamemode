
GNIL.Commands.AddFromTable({
    ["name"] = "version",
    ["public"] = true,
    ["callback"] = function(ply)
        ply:log("The current gamemode version is: " .. GNIL._VERSION)
    end
})
