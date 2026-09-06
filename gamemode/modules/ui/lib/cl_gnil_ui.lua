--[[
                 EDIT THIS FILE AT ALL WITHOUT ME SAYING SO YOU WILL BE REMOVED FROM DEV
                                     Exept Morg and Raptor
]]
GNIL = GNIL or {}

GNIL.Ui = GNIL.Ui or {
    __call = function(...) return GNIL.Ui.Create(...) end
}

--Spelling is not my key feture
--Caching all the Mats
local blur = Material("pp/blurscreen")
gradLeft = Material("vgui/gradient-l")
gradUp = Material("vgui/gradient-u")
gradRight = Material("vgui/gradient-r")
gradDown = Material("vgui/gradient-d")
GNIL.Ui.Scale = function(value) return value * (ScrH() / 1080) end

GNIL.Ui.FormatText = function(name, len)
    len = len or 19

    if #name > len then
        name = string.sub(name, 1, len) .. "..."
    end

    return name
end

GNIL.Ui.Colors = {
    --this is the nav but like.. I have it in so many files
    ["Background"] = Color(227, 116, 20),
    -- ["Background"] = Color(32, 32, 32), -- normal --this is acually the background
    ["Nav"] = Color(23, 23, 23),
    ["DGrey"] = Color(28, 28, 28),
    ["Light_Grey"] = Color(52, 52, 52),
    ["MainAccent"] = Color(14, 82, 228),
    ["Purple"] = Color(126, 14, 231),
    ["Red"] = Color(176, 29, 29),
    ["Tint"] = Color(200, 200, 200, 200),
    ["Discord"] = Color(114, 137, 218),
    ["Steam"] = Color(27, 40, 56),
    ["Web"] = Color(42, 71, 94),
    ["Trans_Black"] = Color(0, 0, 0, 219),
    ["Light_Black"] = Color(0, 0, 0, 101),
    ["Green"] = Color(37, 205, 112)
}

local cachedFonts = {}

GNIL.Ui.fontAliases = {
    ["GNIL_MontserratM"] = "Montserrat Medium",
    ["GNIL_MontserratB"] = "Montserrat Bold",
    ["GNIL_ElephantmenGreat"] = "CCElephantmenGreat-Italic",
    ["GNIL_RobotoMedium"] = "Roboto Medium",
    ["GNIL_RobotoBold"] = "Roboto Bold",
    ["GNIL_Roboto"] = "Roboto",
    ["GNIL_RobotoThin"] = "Roboto Thin",
    ["GNIL_Segment"] = "Gaz El",
    ["GNIL_Segment-b"] = "Gaz Rg",
    ["GNIL_Digital"] = "Digital-7",
}

--  ["GNIL_MontserratB"] = "Montserrat Bold",
GNIL.Ui.ensureFontExists = function(alias, size, scale, weight)
    local tsize = tostring(size)
    scale = scale or true

    if not GNIL.Ui.fontAliases[alias] then
        print("This should never happen, but it did. GNIL.Ui.ensureFontExists(" .. alias .. ")")
    end

    if cachedFonts[alias .. tsize] then return alias .. "." .. size end
    local scale_or_not

    if scale then
        scale_or_not = GNIL.Ui.Scale(size) + GNIL.Ui.Scale(9)
    else
        scale_or_not = size + 9
    end

    surface.CreateFont(alias .. "." .. size, {
        font = GNIL.Ui.fontAliases[alias],
        size = scale_or_not,
        weight = weight or 500,
        antialias = true
    })

    cachedFonts[alias .. tsize] = true

    return alias .. "." .. size
end

--Beast's circle drawing function v2
--Updated
local cachedCircleBase = {}

for i = 1, 360 do
    local v = math.rad(i * 360) / 360

    cachedCircleBase[i] = {math.cos(v), math.sin(v)}
end

GNIL.Ui.DrawCircle = function(x, y, r, col)
    local circle = {}

    for i = 1, 360 do
        local v = cachedCircleBase[i]

        circle[i] = {
            x = x + v[1] * r,
            y = y + v[2] * r
        }
    end

    if col then
        surface.SetDrawColor(col)
        draw.NoTexture()
    end

    surface.DrawPoly(circle)
end

--Arc are like a percent of a circle for example a player counter
GNIL.Ui.DrawArc = function(x, y, ang, p, rad, color, seg)
    seg = seg or 80
    ang = (-ang) + 180
    local circle = {}

    table.insert(circle, {
        x = x,
        y = y
    })

    for i = 0, seg do
        local a = math.rad((i / seg) * -p + ang)

        table.insert(circle, {
            x = x + math.sin(a) * rad,
            y = y + math.cos(a) * rad
        })
    end

    surface.SetDrawColor(color)
    draw.NoTexture()
    surface.DrawPoly(circle)
end

GNIL.Ui.InnerShadow = function(x, y, w, h, size, clr)
    surface.SetDrawColor(clr)
    surface.SetMaterial(gradUp)
    surface.DrawTexturedRect(x, y, w, h - size)
    surface.SetMaterial(gradRight)
    surface.DrawTexturedRect(x + w - (w - (size * .9)), y, w - (size * .9), h)
    surface.SetMaterial(gradLeft)
    surface.DrawTexturedRect(x, y, w - (size * .9), h)
    surface.SetMaterial(gradDown)
    surface.DrawTexturedRect(x, y + h - (h - size), w, h - size)
end

-- Beast func
GNIL.Ui.Smooth = function(points, steps)
    if #points < 3 then return points end
    steps = steps or 5
    local spline = {}
    local count = #points - 1
    local p0, p1, p2, p3, x, y

    for i = 1, count do
        if i == 1 then
            p0, p1, p2, p3 = points[i], points[i], points[i + 1], points[i + 2]
        elseif i == count then
            p0, p1, p2, p3 = points[#points - 2], points[#points - 1], points[#points], points[#points]
        else
            p0, p1, p2, p3 = points[i - 1], points[i], points[i + 1], points[i + 2]
        end

        for t = 0, 1, 1 / steps do
            x = 0.5 * ((2 * p1.x) + (p2.x - p0.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t * t + (3 * p1.x - p0.x - 3 * p2.x + p3.x) * t * t * t)
            y = 0.5 * ((2 * p1.y) + (p2.y - p0.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t * t + (3 * p1.y - p0.y - 3 * p2.y + p3.y) * t * t * t)

            if not (#spline > 0 and spline[#spline].x == x and spline[#spline].y == y) then
                table.insert(spline, {
                    x = x,
                    y = y
                })
            end
        end
    end

    return spline
end

local materials = {}
file.CreateDir("eternal-mats")

GNIL.Ui.GetImgur = function(id, callback, matSettings)
    id = string.lower(id)
    if materials[id] then return callback(materials[id]) end

    if file.Exists("eternal-mats/" .. id .. ".png", "DATA") then
        materials[id] = Material("../data/eternal-mats/" .. id .. ".png", matSettings or "noclamp smooth mips")

        return callback(materials[id])
    end

    http.Fetch("https://professor.solutions/eternal/imgs/" .. id .. ".png", function(body, len, headers, code)
        if len > 2097152 then
            materials[id] = Material("nil")

            return callback(materials[id])
        end

        file.Write("eternal-mats/" .. id .. ".png", body)
        materials[id] = Material("../data/eternal-mats/" .. id .. ".png", matSettings or "noclamp smooth mips")

        return callback(materials[id])
    end, function(error) return GNIL.Ui.GetImgur(id, callback) end)
end

do
    local min = math.min
    local curTime = CurTime

    GNIL.Ui.DrawProgressWheel = function(x, y, w, h, col)
        local progSize = min(w, h)
        surface.SetMaterial(progressMat)
        surface.SetDrawColor(col.r, col.g, col.b, col.a)
        surface.DrawTexturedRectRotated(x + w * .5, y + h * .5, progSize, progSize, -curTime() * 100)
    end

    drawProgressWheel = GNIL.Ui.DrawProgressWheel
end

local materials_img = {}
local grabbingMaterials = {}
local getImgur = GNIL.Ui.GetImgur

getImgur("635ppvg", function(mat)
    progressMat = mat
end)

GNIL.Ui.DrawImgur = function(x, y, w, h, imgurId, col)
    if not materials_img[imgurId] then
        drawProgressWheel(x, y, w, h, col)
        if grabbingMaterials[imgurId] then return end
        grabbingMaterials[imgurId] = true

        getImgur(imgurId, function(mat)
            materials_img[imgurId] = mat
            grabbingMaterials[imgurId] = nil
        end)

        return
    end

    surface.SetMaterial(materials_img[imgurId])
    surface.SetDrawColor(col.r, col.g, col.b, col.a)
    surface.DrawTexturedRect(x, y, w, h)
end

GNIL.Ui.DrawImgurRotated = function(x, y, w, h, rot, imgurId, col)
    if not materials_img[imgurId] then
        drawProgressWheel(x - w * .5, y - h * .5, w, h, col)
        if grabbingMaterials[imgurId] then return end
        grabbingMaterials[imgurId] = true

        getImgur(imgurId, function(mat)
            materials_img[imgurId] = mat
            grabbingMaterials[imgurId] = nil
        end)

        return
    end

    surface.SetMaterial(materials_img[imgurId])
    surface.SetDrawColor(col.r, col.g, col.b, col.a)
    surface.DrawTexturedRectRotated(x, y, w, h, rot)
end

GNIL.Ui.MaskMaterial = CreateMaterial("gnil_mask", "UnlitGeneric", {
    ["$translucent"] = 1,
    ["$vertexalpha"] = 1,
    ["$alpha"] = 1,
})

local renderTarget

local function drawRoundedMask(cornerRadius, x, y, w, h, drawFunc, roundTopLeft, roundTopRight, roundBottomLeft, roundBottomRight)
    if (not renderTarget) then
        renderTarget = GetRenderTargetEx("gnil_roundedbox", ScrW(), ScrH(), RT_SIZE_FULL_FRAME_BUFFER, MATERIAL_RT_DEPTH_NONE, 2, CREATERENDERTARGETFLAGS_UNFILTERABLE_OK, IMAGE_FORMAT_RGBA8888)
    end

    render.PushRenderTarget(renderTarget)
    render.OverrideAlphaWriteEnable(true, true)
    render.Clear(0, 0, 0, 0)
    drawFunc()
    render.OverrideBlendFunc(true, BLEND_ZERO, BLEND_SRC_ALPHA, BLEND_DST_ALPHA, BLEND_ZERO)
    draw.RoundedBoxEx(cornerRadius, x, y, w, h, color_white, roundTopLeft, roundTopRight, roundBottomLeft, roundBottomRight)
    render.OverrideBlendFunc(false)
    render.OverrideAlphaWriteEnable(false)
    render.PopRenderTarget()
    GNIL.Ui.MaskMaterial:SetTexture("$basetexture", renderTarget)
    draw.NoTexture()
    surface.SetDrawColor(color_white)
    surface.SetMaterial(GNIL.Ui.MaskMaterial)
    render.SetMaterial(GNIL.Ui.MaskMaterial)
    render.DrawScreenQuad()
end

GNIL.Ui.DrawRoundedMask = function(cornerRadius, x, y, w, h, drawFunc) return drawRoundedMask(cornerRadius, x, y, w, h, drawFunc, true, true, true, true) end
GNIL.Ui.DrawRoundedExMask = function(cornerRadius, x, y, w, h, drawFunc, roundTopLeft, roundTopRight, roundBottomLeft, roundBottomRight) return drawRoundedMask(cornerRadius, x, y, w, h, drawFunc, roundTopLeft, roundTopRight, roundBottomLeft, roundBottomRight) end
GNIL.Ui.LerpColor = function(frac, from, to) return Color(Lerp(frac, from.r, to.r), Lerp(frac, from.g, to.g), Lerp(frac, from.b, to.b), Lerp(frac, from.a, to.a)) end
GNIL.Ui.HoverFunc = function(s) return s:IsHovered() end
GNIL.Ui.HoverFuncChild = function(s) return s:IsHovered() or s:IsChildHovered() end
--[[---------------------------------------------------------------------------
	Circle function - credit to Beast
---------------------------------------------------------------------------]]
--[[---------------------------------------------------------------------------
	Basic helper classes
---------------------------------------------------------------------------]]
local classes = {}

classes.On = function(pnl, name, fn)
    name = pnl.AppendOverwrite or name
    local old = pnl[name]

    pnl[name] = function(s, ...)
        if (old) then
            old(s, ...)
        end

        fn(s, ...)
    end
end

classes.SetupTransition = function(pnl, name, speed, fn)
    fn = pnl.TransitionFunc or fn
    pnl[name] = 0

    pnl:On("Think", function(s)
        s[name] = Lerp(FrameTime() * speed, s[name], fn(s) and 1 or 0)
    end)
end

--[[---------------------------------------------------------------------------
	Classes
---------------------------------------------------------------------------]]
classes.FadeHover = function(pnl, col, speed, rad, child)
    col = col or color_white
    speed = speed or 6
    rad = rad or 8
    child = child or GNIL.Ui.HoverFunc
    pnl:SetupTransition("FadeHover", speed, child)

    pnl:On("Paint", function(s, w, h)
        GNIL.Ui.DrawRoundedMask(rad, 0, 0, w, h, function()
            surface.SetAlphaMultiplier(s.FadeHover)
            surface.SetDrawColor(col)
            surface.DrawRect(0, 0, w, h)
            surface.SetAlphaMultiplier(1)
        end)
    end)
end

classes.BarHover = function(pnl, col, height, speed)
    col = col or color_white
    height = height or 2
    speed = speed or 6
    pnl:SetupTransition("BarHover", speed, GNIL.Ui.HoverFunc)

    pnl:On("PaintOver", function(s, w, h)
        local bar = math.Round(w * s.BarHover)
        surface.SetDrawColor(col)
        surface.DrawRect(w / 2 - bar / 2, h - height, bar, height)
    end)
end

classes.FillHover = function(pnl, col, dir, speed, mat)
    col = col or color_white
    dir = dir or LEFT
    speed = speed or 8
    pnl:SetupTransition("FillHover", speed, GNIL.Ui.HoverFunc)

    pnl:On("PaintOver", function(s, w, h)
        surface.SetDrawColor(col)
        local x, y, fw, fh

        if (dir == LEFT) then
            x, y, fw, fh = 0, 0, math.Round(w * s.FillHover), h
        elseif (dir == TOP) then
            x, y, fw, fh = 0, 0, w, math.Round(h * s.FillHover)
        elseif (dir == RIGHT) then
            local prog = math.Round(w * s.FillHover)
            x, y, fw, fh = w - prog, 0, prog, h
        elseif (dir == BOTTOM) then
            local prog = math.Round(h * s.FillHover)
            x, y, fw, fh = 0, h - prog, w, prog
        end

        if (mat) then
            surface.SetMaterial(mat)
            surface.DrawTexturedRect(x, y, fw, fh)
        else
            surface.DrawRect(x, y, fw, fh)
        end
    end)
end

classes.Background = function(pnl, col, rad, rtl, rtr, rbl, rbr)
    pnl:On("Paint", function(s, w, h)
        if (rad and rad > 0) then
            if (rtl != nil) then
                draw.RoundedBoxEx(rad, 0, 0, w, h, col, rtl, rtr, rbl, rbr)
            else
                draw.RoundedBox(rad, 0, 0, w, h, col)
            end
        else
            surface.SetDrawColor(col)
            surface.DrawRect(0, 0, w, h)
        end
    end)
end

classes.Material = function(pnl, mat, col)
    col = col or color_white

    pnl:On("Paint", function(s, w, h)
        surface.SetDrawColor(col)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(0, 0, w, h)
    end)
end

classes.TiledMaterial = function(pnl, mat, tw, th, col)
    col = col or color_white

    pnl:On("Paint", function(s, w, h)
        surface.SetMaterial(mat)
        surface.SetDrawColor(col)
        surface.DrawTexturedRectUV(0, 0, w, h, 0, 0, w / tw, h / th)
    end)
end

classes.Outline = function(pnl, col, width)
    col = col or color_white
    width = width or 1

    pnl:On("Paint", function(s, w, h)
        surface.SetDrawColor(col)

        for i = 0, width - 1 do
            surface.DrawOutlinedRect(0 + i, 0 + i, w - i * 2, h - i * 2)
        end
    end)
end

classes.LinedCorners = function(pnl, col, len)
    col = col or color_white
    len = len or 15

    pnl:On("Paint", function(s, w, h)
        surface.SetDrawColor(col)
        surface.DrawRect(0, 0, len, 1)
        surface.DrawRect(0, 1, 1, len - 1)
        surface.DrawRect(w - len, h - 1, len, 1)
        surface.DrawRect(w - 1, h - len, 1, len - 1)
    end)
end

classes.SideBlock = function(pnl, col, size, side)
    col = col or color_white
    size = size or 3
    side = side or LEFT

    pnl:On("Paint", function(s, w, h)
        surface.SetDrawColor(col)

        if (side == LEFT) then
            surface.DrawRect(0, 0, size, h)
        elseif (side == TOP) then
            surface.DrawRect(0, 0, w, size)
        elseif (side == RIGHT) then
            surface.DrawRect(w - size, 0, size, h)
        elseif (side == BOTTOM) then
            surface.DrawRect(0, h - size, w, size)
        end
    end)
end

classes.Text = function(pnl, text, font, col, alignment, ox, oy, paint)
    font = font or "Trebuchet24"
    col = col or color_white
    alignment = alignment or TEXT_ALIGN_CENTER
    ox = ox or 0
    oy = oy or 0

    if (not paint and pnl.SetText and pnl.SetFont and pnl.SetTextColor) then
        pnl:SetText(text)
        pnl:SetFont(font)
        pnl:SetTextColor(col)
    else
        pnl:On("Paint", function(s, w, h)
            local x = 0

            if (alignment == TEXT_ALIGN_CENTER) then
                x = w / 2
            elseif (alignment == TEXT_ALIGN_RIGHT) then
                x = w
            elseif (alignment == TEXT_ALIGN_LEFT) then
                x = 0
            end

            draw.SimpleText(text, font, x + ox, h / 2 + oy, col, alignment, TEXT_ALIGN_CENTER)
        end)
    end
end

classes.DualText = function(pnl, toptext, topfont, topcol, bottomtext, bottomfont, bottomcol, alignment, centerSpacing, xaliment)
    topfont = topfont or "Trebuchet24"
    topcol = topcol or color_white
    bottomfont = bottomfont or "Trebuchet18"
    bottomcol = bottomcol or color_white
    alignment = alignment or TEXT_ALIGN_CENTER
    centerSpacing = centerSpacing or 0
    xaliment = xaliment or 0

    pnl:On("Paint", function(s, w, h)
        surface.SetFont(topfont)
        local tw, th = surface.GetTextSize(toptext)
        surface.SetFont(bottomfont)
        local bw, bh = surface.GetTextSize(bottomtext)
        local y1, y2 = h / 2 - bh / 2, h / 2 + th / 2
        local x

        if (alignment == TEXT_ALIGN_LEFT) then
            x = 15
        elseif (alignment == TEXT_ALIGN_CENTER) then
            x = w / 2
        elseif (alignment == TEXT_ALIGN_RIGHT) then
            x = w
        end

        draw.SimpleText(toptext, topfont, x + xaliment, y1 + centerSpacing, topcol, alignment, TEXT_ALIGN_CENTER)
        draw.SimpleText(bottomtext, bottomfont, x + xaliment, y2 - centerSpacing, bottomcol, alignment, TEXT_ALIGN_CENTER)
    end)
end

classes.Blur = function(pnl, amount)
    pnl:On("Paint", function(s, w, h)
        local x, y = s:LocalToScreen(0, 0)
        local scrW, scrH = ScrW(), ScrH()
        surface.SetDrawColor(color_white)
        surface.SetMaterial(blur)

        for i = 1, 3 do
            blur:SetFloat("$blur", (i / 3) * (amount or 8))
            blur:Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
        end
    end)
end

classes.CircleClick = function(pnl, col, speed, trad, box_rad)
    col = col or color_white
    speed = speed or 5
    pnl.Rad, pnl.Alpha, pnl.ClickX, pnl.ClickY = 0, 0, 0, 0

    pnl:On("PaintOver", function(s, w, h)
        GNIL.Ui.DrawRoundedMask(box_rad or 8, 0, 0, w, h, function()
            if (s.Alpha >= 1) then
                surface.SetAlphaMultiplier(s.Alpha / 400)
                surface.SetDrawColor(col)
                draw.NoTexture()
                GNIL.Ui.DrawCircle(s.ClickX, s.ClickY, s.Rad)
                surface.SetAlphaMultiplier(1)
                s.Rad = Lerp(FrameTime() * speed, s.Rad, trad or w)
                s.Alpha = Lerp(FrameTime() * speed, s.Alpha, 0)
            end
        end)
    end)

    pnl:On("DoClick", function(s)
        s.ClickX, s.ClickY = s:CursorPos()
        s.Rad = 0
        s.Alpha = col.a
    end)
end

classes.CircleHover = function(pnl, col, speed, rad)
    col = col or color_white
    speed = speed or 6
    pnl.LastX, pnl.LastY = 0, 0
    pnl:SetupTransition("CircleHover", speed, GNIL.Ui.HoverFunc)

    pnl:On("Think", function(s)
        if (s:IsHovered()) then
            s.LastX, s.LastY = s:CursorPos()
        end
    end)

    pnl:On("PaintOver", function(s, w, h)
        GNIL.Ui.DrawRoundedMask(rad or 8, 0, 0, w, h, function()
            draw.NoTexture()
            surface.SetAlphaMultiplier(s.CircleHover)
            surface.SetDrawColor(col)
            GNIL.Ui.DrawCircle(s.LastX, s.LastY, s.CircleHover * w)
            surface.SetAlphaMultiplier(1)
        end)
    end)
end

classes.SquareCheckbox = function(pnl, inner, outer, speed)
    inner = inner or color_white
    outer = outer or color_white
    speed = speed or 14
    pnl:SetupTransition("SquareCheckbox", speed, function(s) return s:GetChecked() end)

    pnl:On("Paint", function(s, w, h)
        surface.SetDrawColor(outer)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(inner)
        surface.DrawOutlinedRect(0, 0, w, h)
        local bw, bh = (w - 4) * s.SquareCheckbox, (h - 4) * s.SquareCheckbox
        bw, bh = math.Round(bw), math.Round(bh)
        surface.DrawRect(w / 2 - bw / 2, h / 2 - bh / 2, bw, bh)
    end)
end

classes.CircleCheckbox = function(pnl, inner, outer, speed)
    inner = inner or color_white
    outer = outer or color_white
    speed = speed or 14
    pnl:SetupTransition("CircleCheckbox", speed, function(s) return s:GetChecked() end)

    pnl:On("Paint", function(s, w, h)
        draw.NoTexture()
        surface.SetDrawColor(outer)
        GNIL.Ui.DrawCircle(w / 2, h / 2, w / 2 - 1)
        surface.SetDrawColor(inner)
        GNIL.Ui.DrawCircle(w / 2, h / 2, w * s.CircleCheckbox / 2)
    end)
end

classes.AvatarMask = function(pnl, mask)
    pnl.Avatar = vgui.Create("AvatarImage", pnl)
    pnl.Avatar:SetPaintedManually(true)

    pnl.Paint = function(s, w, h)
        render.ClearStencil()
        render.SetStencilEnable(true)
        render.SetStencilWriteMask(1)
        render.SetStencilTestMask(1)
        render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
        render.SetStencilPassOperation(STENCILOPERATION_ZERO)
        render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
        render.SetStencilReferenceValue(1)
        draw.NoTexture()
        surface.SetDrawColor(color_white)
        mask(s, w, h)
        render.SetStencilFailOperation(STENCILOPERATION_ZERO)
        render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
        render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
        render.SetStencilReferenceValue(1)
        s.Avatar:SetPaintedManually(false)
        s.Avatar:PaintManual()
        s.Avatar:SetPaintedManually(true)
        render.SetStencilEnable(false)
        render.ClearStencil()
    end

    pnl.PerformLayout = function(s)
        s.Avatar:SetSize(s:GetWide(), s:GetTall())
    end

    pnl.SetPlayer = function(s, ply, size)
        s.Avatar:SetPlayer(ply, size)
    end

    pnl.SetSteamID = function(s, id, size)
        s.Avatar:SetSteamID(id, size)
    end
end

classes.CircleAvatar = function(pnl)
    pnl:Class("AvatarMask", function(s, w, h)
        GNIL.Ui.DrawCircle(w / 2, h / 2, w / 2)
    end)
end

classes.Circle = function(pnl, col)
    col = col or color_white

    pnl:On("Paint", function(s, w, h)
        draw.NoTexture()
        surface.SetDrawColor(col)
        GNIL.Ui.DrawCircle(w / 2, h / 2, math.min(w, h) / 2)
    end)
end

classes.CircleFadeHover = function(pnl, col, speed)
    col = col or color_white
    speed = speed or 6
    pnl:SetupTransition("CircleFadeHover", speed, GNIL.Ui.HoverFunc)

    pnl:On("Paint", function(s, w, h)
        draw.NoTexture()
        surface.SetAlphaMultiplier(s.CircleFadeHover)
        surface.SetDrawColor(col)
        GNIL.Ui.DrawCircle(w / 2, h / 2, math.min(w, h) / 2)
        surface.SetAlphaMultiplier(1)
    end)
end

classes.CircleExpandHover = function(pnl, col, speed)
    col = col or color_white
    speed = speed or 6
    pnl:SetupTransition("CircleExpandHover", speed, GNIL.Ui.HoverFunc)

    pnl:On("Paint", function(s, w, h)
        local rad = math.Round(w / 2 * s.CircleExpandHover)
        draw.NoTexture()
        surface.SetAlphaMultiplier(s.CircleExpandHover)
        surface.SetDrawColor(col)
        GNIL.Ui.DrawCircle(w / 2, h / 2, rad)
        surface.SetAlphaMultiplier(1)
    end)
end

classes.Gradient = function(pnl, col, dir, frac, op)
    dir = dir or BOTTOM
    frac = frac or 1

    pnl:On("Paint", function(s, w, h)
        surface.SetDrawColor(col)
        local x, y, gw, gh

        if (dir == LEFT) then
            local prog = math.Round(w * frac)
            x, y, gw, gh = 0, 0, prog, h
            surface.SetMaterial(op and gradRight or gradLeft)
        elseif (dir == TOP) then
            local prog = math.Round(h * frac)
            x, y, gw, gh = 0, 0, w, prog
            surface.SetMaterial(op and gradDown or gradUp)
        elseif (dir == RIGHT) then
            local prog = math.Round(w * frac)
            x, y, gw, gh = w - prog, 0, prog, h
            surface.SetMaterial(op and gradLeft or gradRight)
        elseif (dir == BOTTOM) then
            local prog = math.Round(h * frac)
            x, y, gw, gh = 0, h - prog, w, prog
            surface.SetMaterial(op and gradUp or gradDown)
        end

        surface.DrawTexturedRect(x, y, gw, gh)
    end)
end

classes.SetOpenURL = function(pnl, url)
    pnl:On("DoClick", function()
        gui.OpenURL(url)
    end)
end

classes.NetMessage = function(pnl, name, data)
    data = data or function() end

    pnl:On("DoClick", function()
        net.Start(name)
        data(pnl)
        net.SendToServer()
    end)
end

classes.Stick = function(pnl, dock, margin)
    dock = dock or FILL
    margin = margin or 0
    pnl:Dock(dock)

    if (margin > 0) then
        pnl:DockMargin(margin, margin, margin, margin)
    end

    pnl:InvalidateParent(true)
end

classes.DivTall = function(pnl, frac, target)
    frac = frac or 2
    target = target or pnl:GetParent()
    pnl:SetTall(target:GetTall() / frac)
end

classes.DivWide = function(pnl, frac, target)
    target = target or pnl:GetParent()
    frac = frac or 2
    pnl:SetWide(target:GetWide() / frac)
end

classes.SquareFromHeight = function(pnl)
    pnl:SetWide(pnl:GetTall())
end

classes.SquareFromWidth = function(pnl)
    pnl:SetTall(pnl:GetWide())
end

classes.SetRemove = function(pnl, target)
    target = target or pnl

    pnl:On("DoClick", function()
        if (IsValid(target)) then
            target:Remove()
        end
    end)
end

classes.FadeIn = function(pnl, time, alpha)
    time = time or 0.2
    alpha = alpha or 255
    pnl:SetAlpha(0)
    pnl:AlphaTo(alpha, time)
end

classes.HideVBar = function(pnl)
    local vbar = pnl:GetVBar()
    vbar:SetWide(0)
    vbar:Hide()
end

classes.SetTransitionFunc = function(pnl, fn)
    pnl.TransitionFunc = fn
end

classes.ClearTransitionFunc = function(pnl)
    pnl.TransitionFunc = nil
end

classes.SetAppendOverwrite = function(pnl, fn)
    pnl.AppendOverwrite = fn
end

classes.ClearAppendOverwrite = function(pnl)
    pnl.AppendOverwrite = nil
end

classes.ClearPaint = function(pnl)
    pnl.Paint = nil
end

classes.ReadyTextbox = function(pnl)
    pnl:SetPaintBackground(false)
    pnl:SetAppendOverwrite("PaintOver"):SetTransitionFunc(function(s) return s:IsEditing() end)
end

--[[---------------------------------------------------------------------------
	GNIL function which adds all the classes to your panel
---------------------------------------------------------------------------]]
local meta = FindMetaTable("Panel")

function meta:GNIL()
    self.Class = function(pnl, name, ...)
        local class = classes[name]
        class(pnl, ...)

        return pnl
    end

    for k, v in pairs(classes) do
        self[k] = function(s, ...) return s:Class(k, ...) end
    end

    return self
end

GNIL.Ui.Create = function(c, p, n)
    local pnl = vgui.Create(c, p, n)

    return pnl:GNIL()
end