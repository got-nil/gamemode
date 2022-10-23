-- Map the thirdparty and classes directory to
-- their respective global binding.

local function mapDirectoryReturnsToConst(directory, const)
    if not GNIL[const] then GNIL[const] = {} end

    local files, _ = file.Find(GNIL.GamemodeBasePath .. "/core/" .. directory .. "/*.lua", "LUA")
    for _, f in ipairs(files) do
        if not GNIL.Utils.IsFilenameForCurrentRealm(f) then continue end
    
        local name = GNIL.Utils.GetCleanFilename(f, "lua")
        local rtrn = GNIL.Utils.Include(directory .. "/" .. f)
        if rtrn != nil then
            GNIL[const][name] = rtrn
        end
    end
end

-- Load thirdparty 
mapDirectoryReturnsToConst("thirdparty", "Thirdparty")
mapDirectoryReturnsToConst("classes", "Classes")