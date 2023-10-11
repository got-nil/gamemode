
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
