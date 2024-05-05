local PANEL = {}

function PANEL:Init()
    self.shouldremove = true
    self:GNIL():Background(Color(23,23,23,150), 8):FadeIn()
    self.nav = GNIL.Ui.Create("DPanel", self)
    self.nav:Stick(TOP)
    self.nav:ClearPaint():Background(Color(28,28,28), 8,true,true,false,false)
    self.nav:On("PaintOver",function(s,w,h)
        draw.RoundedBox(0,0,h-2,w,2,Color(52,52,52))
    end)
    self.close = GNIL.Ui.Create("DButton", self.nav)
    self.close:Stick(RIGHT)
    self.close:SetText("")
    self.close:SetWide(self.nav:GetTall())
    self.close:ClearPaint():ClearPaint():Background(Color(28,28,28), 8):Text("✕", GNIL.Ui.ensureFontExists("GNIL_MontserratM", 15)):FadeHover(GNIL.Ui.Colors["Red"], 8, 8)

    self.close:On("DoClick", function()
        if self.shouldremove then
            self:AlphaTo(0, .4, 0, function()
                self:Remove()
            end)
        else
            self:SetVisible(false)
        end
    end)
end

function PANEL:PerformLayout(w, h)
    self.nav:SetTall(40)
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, GNIL.Ui.Colors["Trans_Black"])
end

function PANEL:SetImg(img)
    self.nav:On("Paint", function(s, w, h)
        GNIL.Ui.DrawImgur(10, h * .5 - h * .4, h * .8, h * .8, img, color_white)
    end)
end

function PANEL:SetTitle(str)
    self.nav:Text(str, GNIL.Ui.ensureFontExists("GNIL_MontserratM", 16), color_white, TEXT_ALIGN_LEFT, 45)
end

function PANEL:ShowCloseButton(bool)
    self.close:SetVisible(bool)
end

function PANEL:ShouldRemove(bool)
    self.shouldremove = bool
end

vgui.Register("GNIL.Ui.Frame", PANEL, "EditablePanel")