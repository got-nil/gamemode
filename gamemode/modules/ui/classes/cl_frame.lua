local PANEL = {}

function PANEL:Init()
    self:GNIL():Blur()
    self.nav = GNIL.Ui.Create("DPanel", self)
    self.nav:Stick(TOP)
    self.nav:ClearPaint()
    self.close = GNIL.Ui.Create("DButton", self.nav)
    self.close:Stick(RIGHT, 5)
    self.close:SetText("")
    self.close:SetWide(self.nav:GetTall() - 10)
    self.close:ClearPaint():CircleHover():Text("✕", GNIL.Ui.ensureFontExists("GNIL_MontserratM", 18))

    self.close:On("DoClick", function()
        self:AlphaTo(0, .4, 0, function()
            self:Remove()
        end)
    end)
end

function PANEL:PerformLayout(w, h)
    self.nav:SetTall(50)
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, GNIL.Ui.Colors["Trans_Black"])
end

function PANEL:SetImg(img)
    self.nav:On("Paint", function(s, w, h)
        GNIL.Ui.DrawImgur(15, h * .5 - h * .4, h * .8, h * .8, img, color_white)
        draw.RoundedBox(16, w * .025, h - 3, w * .95, 3, GNIL.Ui.Colors["Tint"])
    end)
end

function PANEL:SetTitle(str)
    self.nav:Text(str, GNIL.Ui.ensureFontExists("GNIL_MontserratM", 16), color_white, TEXT_ALIGN_LEFT, 60)
end

function PANEL:ShowCloseButton(bool)
    self.close:SetVisible(bool)
end

vgui.Register("GNIL.Ui.Frame", PANEL, "EditablePanel")