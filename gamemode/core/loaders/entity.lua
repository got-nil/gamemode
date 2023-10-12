
-- Default entity base.
local defaultEnt = {
    Base = "gmod_base",
    Spawnable = false,
    AdminOnly = true,
    PrintName = "Unnamed GNIL Entity",
    Author = "GNIL Development Team"
}

return {

    Directory = "entities",
    
    -- Load a directory of files as one entity.
    -- Must respect default gmod entity file names.
    LoadDirectory = function(classname, directory_path)

        -- Load realm init file and shared if it exists.
        local out = GNIL.Loader.ConstWrap("ENT", defaultEnt, function()
            if SERVER then GNIL.Utils.Include(directory_path .. "/init.lua") end
            for _, v in ipairs({"cl_init.lua", "shared.lua"}) do
                GNIL.Utils.Include(directory_path .. "/" .. v)
            end
        end)
        if out == nil or out == false then
            GNIL.log("Failed to load entity '" .. classname .. "' " .. (out == nil && "with an error state" || "as it does not have any files for this realm."), out == nil && "error" || "debug")
            return false
        end

        scripted_ents.Register(out, classname)
        return true
    end,

    -- Load a single file as an entity.
    LoadFile = function(classname, filepath)

        -- Wrap the file include in ENT const.
        local out = GNIL.Loader.ConstWrap("ENT", defaultEnt, function()
            GNIL.Utils.Include(filepath)
        end)
        if out == nil or out == false then
            GNIL.log("Failed to load entity '" .. classname .. "' " .. (out == nil && "with an error state" || "as it does not have any files for this realm."), out == nil && "error" || "debug")
        end

        scripted_ents.Register(out, classname)
        return true
    end
}