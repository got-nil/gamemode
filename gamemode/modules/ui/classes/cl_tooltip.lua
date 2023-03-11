local PANEL = {}
local gradUp = Material("vgui/gradient-d")

function PANEL:SetText(text, rarity, rpm, dmg, mag)
    self.text = text
    self.rarity = rarity
    self.rpm = rpm
    self.dmg = dmg
    self.mag = mag
    self:SetSize(GNIL.Ui.Scale(170), GNIL.Ui.Scale(200))
end

function PANEL:Paint(w, h)
    local x, y = self:LocalToScreen()
    GNIL.Ui.Shadows.BeginShadow(self)
    draw.RoundedBox(5, x, y, w, h, Color(23, 154, 230))
    GNIL.Ui.Shadows.EndShadow(self, 1, 1, 3)
    draw.RoundedBox(8, 0, 0, w, h, Color(23, 23, 23))
    surface.SetDrawColor(Color(23, 154, 230))
    surface.SetMaterial(gradUp)
    surface.DrawTexturedRect(0, 0, w, h * .95)
    draw.RoundedBox(8, 0, h * .3, w, h * .7, Color(32, 32, 32))
    draw.SimpleText(self.text or "", GNIL.Ui.ensureFontExists("GNIL_MontserratB", 16), w * .5, h * .1, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(self.rarity or "", GNIL.Ui.ensureFontExists("GNIL_MontserratB", 14), w * .5, h * .22, Color(23, 154, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("RPM", GNIL.Ui.ensureFontExists("GNIL_MontserratM", 13), w * .05, h * .37, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(self.rpm or "", GNIL.Ui.ensureFontExists("GNIL_MontserratM", 23), w * .05, h * .45, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("DMG", GNIL.Ui.ensureFontExists("GNIL_MontserratM", 13), w * .38, h * .37, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(self.dmg or "", GNIL.Ui.ensureFontExists("GNIL_MontserratM", 23), w * .38, h * .45, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("MAG", GNIL.Ui.ensureFontExists("GNIL_MontserratM", 13), w * .7, h * .37, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(self.mag or "", GNIL.Ui.ensureFontExists("GNIL_MontserratM", 23), w * .7, h * .45, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

function PANEL:Think()
    if self.condition and not self:condition() then
        self:Remove()

        return
    end

    local mx, my = 0, 0

    if (self.sx and self.sy) then
        mx, my = self.sx, self.sy
    else
        mx, my = gui.MousePos()
    end

    local x = mx + 30

    if (x + self:GetWide() > ScrW()) then
        x = mx - self:GetWide() - 5
    end

    self:SetPos(x, my)
end

vgui.Register("Boolean.ToolTip", PANEL, "Panel")