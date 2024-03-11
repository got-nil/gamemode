
GNIL.Commands.AddFromTable({
    ["name"] = "version",
    ["public"] = true,
    ["callback"] = function(ply)
        if ply then
            ply:log("The current gamemode version is: " .. GNIL._VERSION)
        else
            GNIL.log("The current gamemode version is: " .. GNIL._VERSION)
        end
    end
})
