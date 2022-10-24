-- Map the thirdparty and classes directory to
-- their respective global binding.

-- PHP function, but in LUA. Mad world we live in.
local function ucfirst(str)
    return str:sub(1,1):upper()..str:sub(2)
end

local function mapDirectoryReturnsToConst(directory)
    local const = ucfirst(directory)
    if not GNIL[const] then GNIL[const] = {} end

    local files, _ = file.Find(GNIL.GamemodeBasePath .. "/core/" .. directory .. "/*.lua", "LUA")
    for _, f in ipairs(files) do
        if not GNIL.Utils.IsFilenameForCurrentRealm(f) then continue end
    
        local name = GNIL.Utils.GetCleanFilename(f, "lua")
        local rtrn = GNIL.Utils.Include(GNIL.Utils.ResolveGamemodePath("core/" .. directory .. "/" .. f))
        if rtrn != nil then
            GNIL[const][const == "Classes" and ucfirst(name) or name] = rtrn
        end
    end
end

-- Load thirdparty and classes directories.
mapDirectoryReturnsToConst("thirdparty")
mapDirectoryReturnsToConst("classes")