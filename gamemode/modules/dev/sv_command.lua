
GNIL.Commands.AddFromTable({
    ["name"] = "reload-module",
    ["public"] = true,
    ["access_check"] = GNIL_CMD_ACCESS_SERVER,
    ["arguments"] = {
        GNIL_CMD_ARGUMENT_STRING
    },
    ["callback"] = function(_, args)

        if not GNIL.Modules.Exists(args[1]) then
            return GNIL.log("Unknown module name '" .. args[1] .. "'. The module must filepath actually exist.", "warning")
        end

        local success = GNIL.Modules.Reload(args[1])
        return GNIL.log((success && "Successfully loaded/reload" || "Failed to load/reload") .. " module '" .. args[1] .. "'!", success && "success" || "warning")
    end
})
