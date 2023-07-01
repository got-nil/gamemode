local MODULE = MODULE

MODULE:AddHook("InitPostEntity", "optimise", function()
    for k, v in pairs(GNIL.Fixes["_optimizers"]) do
        MODULE:log("Enabling default optimizer '" .. k .. "'.", "debug")
        v.enable()
    end
    MODULE:log("Finished loading default optimizers.", "debug")
end)