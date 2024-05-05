GNIL.PopUps = GNIL.PopUps or {}
local scrw, scrh = ScrW(), ScrH()
local h = GNIL.Ui.Scale(28)
local accent = Color(43, 48, 145)

hook.Add("PostRenderVGUI", "GNIL.PopUps:DrawOverLay", function()
    local ply = LocalPlayer()
    local eyetrace = ply:GetEyeTrace()
    local ent = eyetrace.Entity

    if IsValid(ent) and isfunction(ent.DrawOverLay) then
        if not ent.DrawOverLay() then return end
        if isfunction(ent.GetInUse) and ent:GetInUse() then return end
        local dis = ply:GetPos():Distance(ent:GetPos())

        if dis <= 150 then
            local text = ent.text == 0 and "Use" or ent.text
            surface.SetFont(GNIL.Ui.ensureFontExists("GNIL_MontserratM", 16))
            local tw, _ = surface.GetTextSize(text)
            -- if ent.Title then
            --     draw.RoundedBoxEx(6, scrw * .5 - h * .5, scrh * .5 - h, tw + h + 8, h * .5, Color(32, 32, 32, 240), true, true, false, false)
            --     draw.SimpleText(ent.Title, GNIL.Ui.ensureFontExists("GNIL_MontserratB", 7), scrw * .5 - h * .45, scrh * .5 - h * .75 - 1, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            -- end
            draw.RoundedBox(6, scrw * .5 - h * .5, scrh * .5 - h * .5, tw + h + 8, h, Color(23, 23, 23, 240))
            draw.RoundedBox(6, scrw * .5 - h * .5, scrh * .5 - h * .5, h, h, accent)
            draw.SimpleText("E", GNIL.Ui.ensureFontExists("GNIL_MontserratB", 19), scrw * .5, scrh * .5 - 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(text, GNIL.Ui.ensureFontExists("GNIL_MontserratM", 16), scrw * .5 + h * .6, scrh * .5 - 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end)