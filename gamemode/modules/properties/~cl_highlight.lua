local red = Color(255, 0, 0)
local blue = Color(0, 0, 255)
local z = -1200

hook.Add("PostDrawTranslucentRenderables", "test", function()
    if not GNIL.Properties["_map"] then return end
    
    for i, x in ipairs(GNIL.Properties["_map"].sets.row) do
        render.DrawLine(
            Vector(x, 0, z),
            Vector(x, GNIL.Properties["_map"].max.x, z),
            red
        )
        
        if i == 1 then
            render.DrawSphere(Vector(x, 0, z), 500, 50, 50, red)
        end
    end
    for i, y in ipairs(GNIL.Properties["_map"].sets.col) do
        render.DrawLine(
            Vector(0, y, z),
            Vector(GNIL.Properties["_map"].max.y, y, z),
            blue
        )

        if i == 1 then
            render.DrawSphere(Vector(0, y, z), 500, 50, 50, blue)
        end
    end
end)

hook.Add("HUDPaint", "test2", function()
    if not GNIL.Properties["_map"] then return end

    local pos = GNIL.Properties.GetMyCoordinates()
    draw.SimpleText("x = " .. pos.x .. "; y = " .. pos.y, "CloseCaption_Bold", 50, 50, color_white)
end)