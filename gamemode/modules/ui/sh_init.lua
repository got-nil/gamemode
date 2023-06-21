local MODULE = MODULE

MODULE.name = "Professors UI"
MODULE.author = "professor"
MODULE.description = "This is the main UI for the server"

GNIL.Ui = GNIL.Ui or {}

MODULE.OnLoad = function()
    
    local professorsWeirdLoadOrder = {
        "libs/cl_gnil_ui.lua",
        "classes/cl_button.lua",
        "classes/cl_cats.lua",
        "classes/cl_shadows.lua",
        "classes/cl_scroll.lua",
        "classes/cl_frame.lua"
    }

    for _, v in ipairs(professorsWeirdLoadOrder) do
        MODULE:Include(v)
    end
end