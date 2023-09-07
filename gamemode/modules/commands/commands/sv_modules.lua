
GNIL.Commands.AddFromTable({
    ["name"] = "load-module",
    ["public"] = true,
    ["access_check"] = GNIL_CMD_ACCESS_SERVER,
    ["arguments"] = {
        GNIL_CMD_ARGUMENT_STRING
    },
    ["callback"] = function(_, args)
        
        if not GNIL.Modules.Exists(args[1]) then
            return GNIL.log("Unknown module name '" .. args[1] .. "'. The module must filepath actually exist.", "warning")
        end

        local success = GNIL.Modules.Load(args[1], nil, true)
        return GNIL.log("Successfully loaded/reloaded module '" .. args[1] .. "'!", "success")
    end
})
