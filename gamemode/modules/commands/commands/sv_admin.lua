
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

GNIL.Commands.AddFromTable({
    ["name"] = "burn",
    ["public"] = true,
    ["access_check"] = GNIL_CMD_ACCESS_SUPERADMIN,
    ["arguments"] = {
        GNIL_CMD_ARGUMENT_ENTITY_MULTI
    },
    ["callback"] = function(ply, args)
        for _, v in ipairs(args[1]) do
            v:Ignite(10, 25)
        end
    end
})
