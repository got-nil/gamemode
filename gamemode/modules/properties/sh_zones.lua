GNIL.Properties.Zones = GNIL.Properties.Zones or {}

-- Get the intersection point between two lines.
local function IntersectPoint(line1, line2)

    local x1,y1,x2,y2,x3,y3,x4,y4 = line1.x1,line1.y1,line1.x2,line1.y2,line2.x1,line2.y1,line2.x2,line2.y2

    local m1,m2 = (y1-y2)/((x1-x2)+.001),(y3-y4)/((x3-x4)+.001) --get the slopes
    local yint1,yint2 = (-m1*x1)+y1,(-m2*x3)+y3 --get the y-intercepts
    local x = (yint1-yint2)/(m2-m1) --calculate x pos
    local y = m1*x+yint1 --plug in x pos to get y pos

    return x,y

end

-- Do two lines intersect?
local function Intersect(line1, line2)

    local x,y = IntersectPoint(line1, line2)

    local sx,sy = tostring(x), tostring(y)
    if (sx == "-inf" or sx == "inf" or sx == "nan") then
        return false
    end

    local minx1, maxx1 = math.min(line1.x1,line1.x2)-.1, math.max(line1.x1,line1.x2)+.1
    local minx2, maxx2 = math.min(line2.x1,line2.x2)-.1, math.max(line2.x1,line2.x2)+.1
    local miny1, maxy1 = math.min(line1.y1,line1.y2)-.1, math.max(line1.y1,line1.y2)+.1
    local miny2, maxy2 = math.min(line2.y1,line2.y2)-.1, math.max(line2.y1,line2.y2)+.1

    if (x >= minx1) and (x <= maxx1) and (x >= minx2) and (x <= maxx2) then
        if (y >= miny1) and (y <= maxy1) and (y >= miny2) and (y <= maxy2) then
            return true
        end
    end
    return false
end

-- Is a point (vector, or table with x and z) within a poly set?
function GNIL.Properties.Zones.PointInPoly(point, poly)
    local ray = {
        x1 = point.x,
        y1 = point.y,
        x2 = 100000,
        y2 = 100000
    }

    local inside = false
    local line = {
        x1 = 0,
        y1 = 0,
        x2 = 0,
        y2 = 0
    }

    //Perform ray test
    for k1, v in pairs(poly) do

        local v2 = poly[k1+1]
        if not v2 then
            v2 = poly[1]
        end

        line["x1"] = v.x
        line["y1"] = v.y
        line["x2"] = v2.x
        line["y2"] = v2.y

        if Intersect(ray,line) then
            inside = !inside
        end
    end
    return inside
end