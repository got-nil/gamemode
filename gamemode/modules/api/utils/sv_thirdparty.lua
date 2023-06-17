local MODULE = MODULE

-- Extend the current thirdparty set with additionals. This means we can
-- continue using GNIL.Thirdparty, so if the tool becomes used in multiple
-- modules it can simply be moved to the global set with unchanged code.
for k, v in pairs(GNIL.Loader.DirectoryMap(MODULE:ResolvePath("thirdparty"))) do
    GNIL.Thirdparty[k] = v
    MODULE:log("Loaded additional thirdparty utility: " .. k, "debug")
end
