local setmetatable = setmetatable
local GNIL = GNIL
local Material = Material
local math_Clamp = math.Clamp
local ScrH = ScrH
local string_sub = string.sub
local Color = Color
local print = print
local tostring = tostring
local surface_CreateFont = surface.CreateFont
local math_cos = math.cos
local math_rad = math.rad
local math_sin = math.sin
local surface_SetDrawColor = surface.SetDrawColor
local draw_NoTexture = draw.NoTexture
local surface_DrawPoly = surface.DrawPoly
local table_insert = table.insert
local file_CreateDir = file.CreateDir
local file_Exists = file.Exists
local http_Fetch = http.Fetch
local file_Write = file.Write
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local drawProgressWheel = drawProgressWheel
local surface_DrawTexturedRect = surface.DrawTexturedRect
local Lerp = Lerp
local FrameTime = FrameTime
local ColorAlpha = ColorAlpha
local draw_RoundedBox = draw.RoundedBox
local surface_DrawRect = surface.DrawRect
local math_Round = math.Round
local draw_RoundedBoxEx = draw.RoundedBoxEx
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local draw_SimpleText = draw.SimpleText
local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local ScrW = ScrW
local render_UpdateScreenEffectTexture = render.UpdateScreenEffectTexture
local vgui_Create = vgui.Create
local render_ClearStencil = render.ClearStencil
local render_SetStencilEnable = render.SetStencilEnable
local render_SetStencilWriteMask = render.SetStencilWriteMask
local render_SetStencilTestMask = render.SetStencilTestMask
local render_SetStencilFailOperation = render.SetStencilFailOperation
local render_SetStencilPassOperation = render.SetStencilPassOperation
local render_SetStencilZFailOperation = render.SetStencilZFailOperation
local render_SetStencilCompareFunction = render.SetStencilCompareFunction
local render_SetStencilReferenceValue = render.SetStencilReferenceValue
local math_min = math.min
local gui_OpenURL = gui.OpenURL
local net_Start = net.Start
local net_SendToServer = net.SendToServer
local IsValid = IsValid
local FindMetaTable = FindMetaTable
local pairs = pairs
--[[
                 EDIT THIS FILE AT ALL WITHOUT ME SAYING SO YOU WILL BE REMOVED FROM DEV
                                     Exept Morg and Raptor
]]
GNIL.Ui = GNIL.Ui or {}

setmetatable(GNIL.Ui, {
    ["__call"] = function(...) return GNIL.Ui.Create(...) end
})

-- Spelling is not my key feture
--[[
Gonna make this as easy as I can for all the devs that are using GNIL ui lib
]]
--[[
Examples:
local pnl = GNIL.Ui.Create("DFrame")
pnl:SetSize(500,500)

GNIL will allow you to use all of the ui for example:
local pnl = GNIL.Ui.Create("DFrame")
pnl:SetSize(500,500)
pnl:ClearPaint():Background():CircleClick():ect....

-- Pretty cool way right

FAQ Basically a way for you not to dm me
How do I add functions like DoClick and Think?
    pnl:On("FuncName",function(some,args)
        print("I do something")
    end)

how do I add GNIL on a self panel?
    self:GNIL()  

    That should be it if you actually have problems with this...
    you should prob like.. mmmm like not be a dev..
    Not my idea but it is
    so yeaaaaa
    just don't be dumb
    I will add some dummy examples so if you are stuck with something
    just rip my code

]]
--Caching all the Mats
local blur = Material("pp/blurscreen")
local gradLeft = Material("vgui/gradient-l")
local gradUp = Material("vgui/gradient-u")
local gradRight = Material("vgui/gradient-r")
local gradDown = Material("vgui/gradient-d")
GNIL.Ui.Scale = function(value) return value * math_Clamp(ScrH() / 1080, 0.7, 1) end

GNIL.Ui.FormatText = function(name, len)
    len = len or 19

    if #name > len then
        name = string_sub(name, 1, len) .. "..."
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

GNIL.Ui.cachedFonts = {}

GNIL.Ui.fontAliases = {
    ["GNIL_MontserratM"] = "Montserrat Medium",
    ["GNIL_MontserratB"] = "Montserrat Bold",
}

GNIL.Ui.ensureFontExists = function(alias, size, scale)
    if scale == nil or scale == false then
        scale = false
    elseif scale == true then
        scale = true
    else
        scale = false
    end

    if not GNIL.Ui.fontAliases[alias] then
        print("This should never happen, but it did. GNIL.Ui.ensureFontExists(" .. alias .. ")")
    end

    if GNIL.Ui.cachedFonts[alias .. tostring(size)] then return alias .. "." .. size end
    local scale_or_not

    if scale then
        scale_or_not = GNIL.Ui.Scale(size) + GNIL.Ui.Scale(9)
    else
        scale_or_not = size + 9
    end

    surface_CreateFont(alias .. "." .. size, {
        font = GNIL.Ui.fontAliases[alias],
        size = scale_or_not,
        extended = true,
        antialias = true
    })

    GNIL.Ui.cachedFonts[alias .. tostring(size)] = true

    return alias .. "." .. size
end

--Beast's circle drawing function v2
GNIL.Ui.DrawCircle = function(x, y, r, col)
    local circle = {}

    for i = 1, 360 do
        circle[i] = {}
        circle[i].x = x + math_cos(math_rad(i * 360) / 360) * r
        circle[i].y = y + math_sin(math_rad(i * 360) / 360) * r
    end

    surface_SetDrawColor(col)
    draw_NoTexture()
    surface_DrawPoly(circle)
end

--Arc are like a percent of a circle for example a player counter
GNIL.Ui.DrawArc = function(x, y, ang, p, rad, color, seg)
    seg = seg or 80
    ang = (-ang) + 180
    local circle = {}

    table_insert(circle, {
        x = x,
        y = y
    })

    for i = 0, seg do
        local a = math_rad((i / seg) * -p + ang)

        table_insert(circle, {
            x = x + math_sin(a) * rad,
            y = y + math_cos(a) * rad
        })
    end

    surface_SetDrawColor(color)
    draw_NoTexture()
    surface_DrawPoly(circle)
end

local materials = {}
file_CreateDir("gnil-mats")

GNIL.Ui.GetImgur = function(id, callback, useproxy, matSettings)
    if materials[id] then return callback(materials[id]) end

    if file_Exists("gnil-mats/" .. id .. ".png", "DATA") then
        materials[id] = Material("../data/gnil-mats/" .. id .. ".png", matSettings or "noclamp smooth mips")

        return callback(materials[id])
    end

    http_Fetch(useproxy and "https://proxy.duckduckgo.com/iu/?u=https://i.imgur.com" or "https://i.imgur.com/" .. id .. ".png", function(body, len, headers, code)
        if len > 2097152 then
            materials[id] = Material("nil")

            return callback(materials[id])
        end

        file_Write("gnil-mats/" .. id .. ".png", body)
        materials[id] = Material("../data/gnil-mats/" .. id .. ".png", matSettings or "noclamp smooth mips")

        return callback(materials[id])
    end, function(error)
        if useproxy then
            materials[id] = Material("nil")

            return callback(materials[id])
        end

        return GNIL.Ui.GetImgur(id, callback, true)
    end)
end

do
    local min = math.min
    local curTime = CurTime

    GNIL.Ui.DrawProgressWheel = function(x, y, w, h, col)
        local progSize = min(w, h)
        surface_SetMaterial(progressMat)
        surface_SetDrawColor(col.r, col.g, col.b, col.a)
        surface_DrawTexturedRectRotated(x + w * .5, y + h * .5, progSize, progSize, -curTime() * 100)
    end

    drawProgressWheel = GNIL.Ui.DrawProgressWheel
end

local materials_img = {}
local grabbingMaterials = {}
local getImgur = GNIL.Ui.GetImgur

getImgur("635PPvg", function(mat)
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

    surface_SetMaterial(materials_img[imgurId])
    surface_SetDrawColor(col.r, col.g, col.b, col.a)
    surface_DrawTexturedRect(x, y, w, h)
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

    surface_SetMaterial(materials_img[imgurId])
    surface_SetDrawColor(col.r, col.g, col.b, col.a)
    surface_DrawTexturedRectRotated(x, y, w, h, rot)
end

GNIL.Ui.LerpColor = function(frac, from, to) return Color(Lerp(frac, from.r, to.r), Lerp(frac, from.g, to.g), Lerp(frac, from.b, to.b), Lerp(frac, from.a, to.a)) end
--Various handy premade transition functions
GNIL.Ui.HoverFunc = function(s) return s:IsHovered() end
GNIL.Ui.HoverFuncChild = function(s) return s:IsHovered() or s:IsChildHovered() end

--[[---------------------------------------------------------------------------
	Circle function - credit to Beast
---------------------------------------------------------------------------]]
local function drawCircle(x, y, r)
    local circle = {}

    for i = 1, 360 do
        circle[i] = {}
        circle[i].x = x + math_cos(math_rad(i * 360) / 360) * r
        circle[i].y = y + math_sin(math_rad(i * 360) / 360) * r
    end

    surface_DrawPoly(circle)
end

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
classes.FadeHover = function(pnl, col, speed, rad)
    col = col or color_white
    speed = speed or 6
    pnl:SetupTransition("FadeHover", speed, GNIL.Ui.HoverFunc)

    pnl:On("Paint", function(s, w, h)
        local col = ColorAlpha(col, col.a * s.FadeHover)

        if (rad and rad > 0) then
            draw_RoundedBox(rad, 0, 0, w, h, col)
        else
            surface_SetDrawColor(col)
            surface_DrawRect(0, 0, w, h)
        end
    end)
end

classes.BarHover = function(pnl, col, height, speed)
    col = col or color_white
    height = height or 2
    speed = speed or 6
    pnl:SetupTransition("BarHover", speed, GNIL.Ui.HoverFunc)

    pnl:On("PaintOver", function(s, w, h)
        local bar = math_Round(w * s.BarHover)
        surface_SetDrawColor(col)
        surface_DrawRect(w / 2 - bar / 2, h - height, bar, height)
    end)
end

classes.FillHover = function(pnl, col, dir, speed, mat)
    col = col or color_white
    dir = dir or LEFT
    speed = speed or 8
    pnl:SetupTransition("FillHover", speed, GNIL.Ui.HoverFunc)

    pnl:On("PaintOver", function(s, w, h)
        surface_SetDrawColor(col)
        local x, y, fw, fh

        if (dir == LEFT) then
            x, y, fw, fh = 0, 0, math_Round(w * s.FillHover), h
        elseif (dir == TOP) then
            x, y, fw, fh = 0, 0, w, math_Round(h * s.FillHover)
        elseif (dir == RIGHT) then
            local prog = math_Round(w * s.FillHover)
            x, y, fw, fh = w - prog, 0, prog, h
        elseif (dir == BOTTOM) then
            local prog = math_Round(h * s.FillHover)
            x, y, fw, fh = 0, h - prog, w, prog
        end

        if (mat) then
            surface_SetMaterial(mat)
            surface_DrawTexturedRect(x, y, fw, fh)
        else
            surface_DrawRect(x, y, fw, fh)
        end
    end)
end

classes.Background = function(pnl, col, rad, rtl, rtr, rbl, rbr)
    pnl:On("Paint", function(s, w, h)
        if (rad and rad > 0) then
            if (rtl ~= nil) then
                draw_RoundedBoxEx(rad, 0, 0, w, h, col, rtl, rtr, rbl, rbr)
            else
                draw_RoundedBox(rad, 0, 0, w, h, col)
            end
        else
            surface_SetDrawColor(col)
            surface_DrawRect(0, 0, w, h)
        end
    end)
end

classes.Material = function(pnl, mat, col)
    col = col or color_white

    pnl:On("Paint", function(s, w, h)
        surface_SetDrawColor(col)
        surface_SetMaterial(mat)
        surface_DrawTexturedRect(0, 0, w, h)
    end)
end

classes.Outline = function(pnl, col, width)
    col = col or color_white
    width = width or 1

    pnl:On("Paint", function(s, w, h)
        surface_SetDrawColor(col)

        for i = 0, width - 1 do
            surface_DrawOutlinedRect(0 + i, 0 + i, w - i * 2, h - i * 2)
        end
    end)
end

classes.LinedCorners = function(pnl, col, len)
    col = col or color_white
    len = len or 15

    pnl:On("Paint", function(s, w, h)
        surface_SetDrawColor(col)
        surface_DrawRect(0, 0, len, 1)
        surface_DrawRect(0, 1, 1, len - 1)
        surface_DrawRect(w - len, h - 1, len, 1)
        surface_DrawRect(w - 1, h - len, 1, len - 1)
    end)
end

classes.SideBlock = function(pnl, col, size, side)
    col = col or color_white
    size = size or 3
    side = side or LEFT

    pnl:On("Paint", function(s, w, h)
        surface_SetDrawColor(col)

        if (side == LEFT) then
            surface_DrawRect(0, 0, size, h)
        elseif (side == TOP) then
            surface_DrawRect(0, 0, w, size)
        elseif (side == RIGHT) then
            surface_DrawRect(w - size, 0, size, h)
        elseif (side == BOTTOM) then
            surface_DrawRect(0, h - size, w, size)
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
            end

            draw_SimpleText(text, font, x + ox, h / 2 + oy, col, alignment, TEXT_ALIGN_CENTER)
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
        surface_SetFont(topfont)
        local tw, th = surface_GetTextSize(toptext)
        surface_SetFont(bottomfont)
        local bw, bh = surface_GetTextSize(bottomtext)
        local y1, y2 = h / 2 - bh / 2, h / 2 + th / 2
        local x

        if (alignment == TEXT_ALIGN_LEFT) then
            x = 15
        elseif (alignment == TEXT_ALIGN_CENTER) then
            x = w / 2
        elseif (alignment == TEXT_ALIGN_RIGHT) then
            x = w
        end

        draw_SimpleText(toptext, topfont, x + xaliment, y1 + centerSpacing, topcol, alignment, TEXT_ALIGN_CENTER)
        draw_SimpleText(bottomtext, bottomfont, x + xaliment, y2 - centerSpacing, bottomcol, alignment, TEXT_ALIGN_CENTER)
    end)
end

classes.Blur = function(pnl, amount)
    pnl:On("Paint", function(s, w, h)
        local x, y = s:LocalToScreen(0, 0)
        local scrW, scrH = ScrW(), ScrH()
        surface_SetDrawColor(color_white)
        surface_SetMaterial(blur)

        for i = 1, 3 do
            blur:SetFloat("$blur", (i / 3) * (amount or 8))
            blur:Recompute()
            render_UpdateScreenEffectTexture()
            surface_DrawTexturedRect(x * -1, y * -1, scrW, scrH)
        end
    end)
end

classes.CircleClick = function(pnl, col, speed, trad)
    col = col or color_white
    speed = speed or 5
    pnl.Rad, pnl.Alpha, pnl.ClickX, pnl.ClickY = 0, 0, 0, 0

    pnl:On("Paint", function(s, w, h)
        if (s.Alpha >= 1) then
            surface_SetDrawColor(ColorAlpha(col, s.Alpha))
            draw_NoTexture()
            drawCircle(s.ClickX, s.ClickY, s.Rad)
            s.Rad = Lerp(FrameTime() * speed, s.Rad, trad or w)
            s.Alpha = Lerp(FrameTime() * speed, s.Alpha, 0)
        end
    end)

    pnl:On("DoClick", function(s)
        s.ClickX, s.ClickY = s:CursorPos()
        s.Rad = 0
        s.Alpha = col.a
    end)
end

classes.CircleHover = function(pnl, col, speed, trad)
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
        draw_NoTexture()
        surface_SetDrawColor(ColorAlpha(col, col.a * s.CircleHover))
        drawCircle(s.LastX, s.LastY, s.CircleHover * (trad or w))
    end)
end

classes.SquareCheckbox = function(pnl, inner, outer, speed)
    inner = inner or color_white
    outer = outer or color_white
    speed = speed or 14
    pnl:SetupTransition("SquareCheckbox", speed, function(s) return s:GetChecked() end)

    pnl:On("Paint", function(s, w, h)
        surface_SetDrawColor(outer)
        surface_DrawRect(0, 0, w, h)
        surface_SetDrawColor(inner)
        surface_DrawOutlinedRect(0, 0, w, h)
        local bw, bh = (w - 4) * s.SquareCheckbox, (h - 4) * s.SquareCheckbox
        bw, bh = math_Round(bw), math_Round(bh)
        surface_DrawRect(w / 2 - bw / 2, h / 2 - bh / 2, bw, bh)
    end)
end

classes.CircleCheckbox = function(pnl, inner, outer, speed)
    inner = inner or color_white
    outer = outer or color_white
    speed = speed or 14
    pnl:SetupTransition("CircleCheckbox", speed, function(s) return s:GetChecked() end)

    pnl:On("Paint", function(s, w, h)
        draw_NoTexture()
        surface_SetDrawColor(outer)
        drawCircle(w / 2, h / 2, w / 2 - 1)
        surface_SetDrawColor(inner)
        drawCircle(w / 2, h / 2, w * s.CircleCheckbox / 2)
    end)
end

classes.AvatarMask = function(pnl, mask)
    pnl.Avatar = vgui_Create("AvatarImage", pnl)
    pnl.Avatar:SetPaintedManually(true)

    pnl.Paint = function(s, w, h)
        render_ClearStencil()
        render_SetStencilEnable(true)
        render_SetStencilWriteMask(1)
        render_SetStencilTestMask(1)
        render_SetStencilFailOperation(STENCILOPERATION_REPLACE)
        render_SetStencilPassOperation(STENCILOPERATION_ZERO)
        render_SetStencilZFailOperation(STENCILOPERATION_ZERO)
        render_SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
        render_SetStencilReferenceValue(1)
        draw_NoTexture()
        surface_SetDrawColor(color_white)
        mask(s, w, h)
        render_SetStencilFailOperation(STENCILOPERATION_ZERO)
        render_SetStencilPassOperation(STENCILOPERATION_REPLACE)
        render_SetStencilZFailOperation(STENCILOPERATION_ZERO)
        render_SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
        render_SetStencilReferenceValue(1)
        s.Avatar:SetPaintedManually(false)
        s.Avatar:PaintManual()
        s.Avatar:SetPaintedManually(true)
        render_SetStencilEnable(false)
        render_ClearStencil()
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
        drawCircle(w / 2, h / 2, w / 2)
    end)
end

classes.Circle = function(pnl, col)
    col = col or color_white

    pnl:On("Paint", function(s, w, h)
        draw_NoTexture()
        surface_SetDrawColor(col)
        drawCircle(w / 2, h / 2, math_min(w, h) / 2)
    end)
end

classes.CircleFadeHover = function(pnl, col, speed)
    col = col or color_white
    speed = speed or 6
    pnl:SetupTransition("CircleFadeHover", speed, GNIL.Ui.HoverFunc)

    pnl:On("Paint", function(s, w, h)
        draw_NoTexture()
        surface_SetDrawColor(ColorAlpha(col, col.a * s.CircleFadeHover))
        drawCircle(w / 2, h / 2, math_min(w, h) / 2)
    end)
end

classes.CircleExpandHover = function(pnl, col, speed)
    col = col or color_white
    speed = speed or 6
    pnl:SetupTransition("CircleExpandHover", speed, GNIL.Ui.HoverFunc)

    pnl:On("Paint", function(s, w, h)
        local rad = math_Round(w / 2 * s.CircleExpandHover)
        draw_NoTexture()
        surface_SetDrawColor(ColorAlpha(col, col.a * s.CircleExpandHover))
        drawCircle(w / 2, h / 2, rad)
    end)
end

classes.Gradient = function(pnl, col, dir, frac, op)
    dir = dir or BOTTOM
    frac = frac or 1

    pnl:On("Paint", function(s, w, h)
        surface_SetDrawColor(col)
        local x, y, gw, gh

        if (dir == LEFT) then
            local prog = math_Round(w * frac)
            x, y, gw, gh = 0, 0, prog, h
            surface_SetMaterial(op and gradRight or gradLeft)
        elseif (dir == TOP) then
            local prog = math_Round(h * frac)
            x, y, gw, gh = 0, 0, w, prog
            surface_SetMaterial(op and gradDown or gradUp)
        elseif (dir == RIGHT) then
            local prog = math_Round(w * frac)
            x, y, gw, gh = w - prog, 0, prog, h
            surface_SetMaterial(op and gradLeft or gradRight)
        elseif (dir == BOTTOM) then
            local prog = math_Round(h * frac)
            x, y, gw, gh = 0, h - prog, w, prog
            surface_SetMaterial(op and gradUp or gradDown)
        end

        surface_DrawTexturedRect(x, y, gw, gh)
    end)
end

classes.SetOpenURL = function(pnl, url)
    pnl:On("DoClick", function()
        gui_OpenURL(url)
    end)
end

classes.NetMessage = function(pnl, name, data)
    data = data or function() end

    pnl:On("DoClick", function()
        net_Start(name)
        data(pnl)
        net_SendToServer()
    end)
end

classes.Stick = function(pnl, dock, margin, dontInvalidate)
    dock = dock or FILL
    margin = margin or 0
    pnl:Dock(dock)

    if (margin > 0) then
        pnl:DockMargin(margin, margin, margin, margin)
    end

    if (not dontInvalidate) then
        pnl:InvalidateParent(true)
    end
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

GNIL.Ui.Create = function(...) return vgui_Create(...):GNIL() end