-- Original script by Code Blue, heavily modified by badger
GNIL.Ui = GNIL.Ui or {}
GNIL.Ui.Shadows = {}
local shadows = GNIL.Ui.Shadows
shadows.RenderTargets = {}
shadows.RealRenderTargets = {}
shadows.JunkRT = GetRenderTargetEx("bshadows_junk", 2, 2, RT_SIZE_DEFAULT, MATERIAL_RT_DEPTH_NONE, bit.bor(1, 4096), CREATERENDERTARGETFLAGS_AUTOMIPMAP, IMAGE_FORMAT_RGB888)
local drawShadow = false -- Used for telling if the shadow has aleady been drawn in BeginShadow so it isn't redrawn in EndShadow
local i = 0 -- Used for making new texture names
local shadowMaterial = CreateMaterial("bshadows" .. os.time(), "UnlitGeneric", {
    ["$translucent"] = 1,
    ["$vertexalpha"] = 1,
    ["$alpha"] = 1,
    ["$color"] = "40 0 0",
    ["$color2"] = "0 0 0"
})

shadows.DrawShadow = function(tblRT, intensity, opacity, x, y, x1, y1, x2, y2)
    -- Calculate the distance from origin and the direction of the shadow
    local xDistance = (x - tblRT.Origin.x)
    local yDistance = (y - tblRT.Origin.y)
    -- Draw the shadow
    shadowMaterial:SetFloat("$alpha", opacity / 255)
    shadowMaterial:SetTexture("$basetexture", tblRT.RT)
    render.SetMaterial(shadowMaterial)

    for _ = 1, math.ceil(intensity) do
        -- Only where it needs to be
        if x2 then
            render.SetScissorRect(x1, y1, x2, y2, true)
        end

        render.DrawScreenQuadEx(xDistance, yDistance, ScrW(), ScrH())

        if x2 then
            render.SetScissorRect(0, 0, 0, 0, false)
        end
    end
end

shadows.BeginShadow = function(panel, recreate)
    local w, h = panel:GetSize()
    local tblRT = shadows.RenderTargets[panel]

    if not tblRT or not tblRT.Finished then
        if not tblRT then
            shadows.RenderTargets[panel] = {}
            tblRT = shadows.RenderTargets[panel]
        end

        local x, y = panel:LocalToScreen(0, 0)

        -- Save the original position and size
        tblRT.Origin = {
            x = x,
            y = y
        }

        tblRT.Size = {
            w = w,
            h = h
        }

        -- Check if another panel of the same size exists (very common in ui)
        -- This is much faster than doing blurring and creating the textures and materials.
        for otherPanel in next, shadows.RealRenderTargets do
            local otherTblRT = shadows.RenderTargets[otherPanel]

            if otherTblRT.Size.h == h and otherTblRT.Size.w == w and otherPanel != panel then
                tblRT.RT = otherTblRT.RT
                tblRT.Origin = otherTblRT.Origin
                tblRT.Finished = true
            end
        end
    end

    -- Drawing the cached RT
    -- Only if this RT has already been created
    if tblRT.Finished then
        -- Get info about the panel
        if tblRT.Size.w == w and tblRT.Size.h == h then
            -- Make sure nothing else is drawn
            drawShadow = true
            render.PushRenderTarget(shadows.JunkRT)

            return
        else
            tblRT.Finished = false

            return shadows.BeginShadow(panel, true)
        end
    end

    if not tblRT.RT then
        -- Creating new RT
        tblRT.RT = GetRenderTargetEx("bshadows" .. "_" .. i, ScrW(), ScrH(), RT_SIZE_DEFAULT, MATERIAL_RT_DEPTH_NONE, bit.bor(1, 4096), CREATERENDERTARGETFLAGS_AUTOMIPMAP, IMAGE_FORMAT_DEFAULT)
        i = i + 1
    elseif recreate and not shadows.RealRenderTargets[panel] then
        tblRT.RT = GetRenderTargetEx("bshadows" .. "_" .. i, ScrW(), ScrH(), RT_SIZE_DEFAULT, MATERIAL_RT_DEPTH_NONE, bit.bor(1, 4096), CREATERENDERTARGETFLAGS_AUTOMIPMAP, IMAGE_FORMAT_DEFAULT)
        i = i + 1
    end

    -- Push the RT so everything is drawn onto it
    render.PushRenderTarget(tblRT.RT)
    render.OverrideAlphaWriteEnable(true, true)
    render.Clear(0, 0, 0, 0)
    render.OverrideAlphaWriteEnable(false, false)
    cam.Start2D()
end

shadows.EndShadow = function(panel, spread, blur, intensity, opacity, x1, y1, x2, y2)
    opacity = opacity or 255
    local tblRT = shadows.RenderTargets[panel]

    if drawShadow then
        render.PopRenderTarget()
        drawShadow = false
        local x, y = panel:LocalToScreen(0, 0)
        shadows.DrawShadow(tblRT, intensity, opacity, x, y, x1, y1, x2, y2)

        return
    end

    if not tblRT.Finished then
        -- Blur it
        if blur > 0 then
            render.OverrideAlphaWriteEnable(true, true)
            render.BlurRenderTarget(tblRT.RT, spread, spread, blur)
            render.OverrideAlphaWriteEnable(false, false)
        end

        tblRT.Finished = true
        shadows.RealRenderTargets[panel] = tblRT
    end

    -- Finish up
    render.PopRenderTarget()
    cam.End2D()
    local x, y = panel:LocalToScreen(0, 0)
    shadows.DrawShadow(tblRT, intensity, opacity, x, y, x1, y1, x2, y2)
end