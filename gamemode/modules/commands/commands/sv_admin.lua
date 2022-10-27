
GNIL.Commands.AddFromTable({
    ["name"] = "ip",
    ["public"] = true,
    ["access_check"] = GNIL_CMD_ACCESS_SUPERADMIN,
    ["arguments"] = {
        GNIL_CMD_ARGUMENT_PLAYER
    },
    ["callback"] = function(ply, args)
        ply:log(args[1]:Nick() .. "'s IP address is: " .. args[1]:IPAddress())
    end
})
