
---@class drawlib
local draw = draw

---Draw an outlined textured rectangle with rotation.
---@param x number
---@param y number
---@param width number
---@param height number
---@param color table
---@param rotation number
---@param outlinewidth number
---@param outlinecolour table
draw.DrawTexturedRectRotatedOutlined = function(x, y, width, height, color, rotation, outlinewidth, outlinecolour)
    local steps = ( outlinewidth * 2 ) / 3
    if steps < 1 then steps = 1 end

    surface.SetDrawColor(outlinecolour)
    for _x = -outlinewidth, outlinewidth, steps do
        for _y = -outlinewidth, outlinewidth, steps do
            surface.DrawTexturedRectRotated( x + _x, y + _y, width, height, rotation )
        end
    end

    surface.SetDrawColor(color)
    surface.DrawTexturedRectRotated(x,y, width,height,rotation)
end
