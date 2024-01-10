
-- Default entity base.
local defaultEnt = {
    Base = "gmod_base",
    Spawnable = false,
    AdminOnly = true,
    PrintName = "Unnamed GNIL Entity",
    Author = "GNIL Development Team"
}

local function registerEntity(name, class)
    if class == nil or class == false then
        GNIL.log("Failed to load entity '" .. name .. "' " .. (class == nil && "with an error state" || "as it does not have any files for this realm."), class == nil && "error" || "debug")
        return false
    else
        GNIL.log("Successfully registered entity '" .. name .. "'.", "debug")
    end

    scripted_ents.Register(class, name)
    return true
end

-- Only actually try to include the target filepath if it exists.
local function includeIfExists(filepath)
    if not file.Exists(filepath, "LUA") then
        return
    end
    return GNIL.Utils.Include(filepath)
end

return {

    Directory = "entities",

    -- Load a directory of files as one entity.
    -- Must respect default gmod entity file names.
    LoadDirectory = function(classname, directory_path)

        -- Load realm init file and shared if it exists.
        local out = GNIL.Loader.ConstWrap("ENT", defaultEnt, function()
            if SERVER then includeIfExists(directory_path .. "/init.lua") end
            for _, v in ipairs({"cl_init.lua", "shared.lua"}) do
                includeIfExists(directory_path .. "/" .. v)
            end
        end)
        return registerEntity(classname, out)
    end,

    -- Load a single file as an entity.
    LoadFile = function(classname, filepath)

        -- Wrap the file include in ENT const.
        local out = GNIL.Loader.ConstWrap("ENT", defaultEnt, function()
            GNIL.Utils.Include(filepath)
        end)
        return registerEntity(classname, out)
    end
}