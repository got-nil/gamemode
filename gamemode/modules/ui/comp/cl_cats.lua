local PANEL = {}

function PANEL:Init()
    self.Header:GNIL():Background(Eternal.F4.vgui.Colors["Secondary"], 8):FadeHover(Eternal.F4.vgui.Colors["Accent"], 8, 8)
    self:SetHeaderHeight(50)
    self:SetLabel("")

    self.Header:On("PaintOver", function(s, w, h)
        GNIL.Ui.DrawRoundedMask(8, 0, 0, w, h, function()
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, color_transparent)
            surface.SetDrawColor(self.Bg)
            surface.DrawTexturedRectRotated(w * .194, h * .731, w * .3, w * .2, 45)
            draw.SimpleText(self.CatName or "", GNIL.Ui.ensureFontExists("GNIL_MontserratB", 17), 10, h * .5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end)
    end)

    self.Header:On("Paint", function(s, w, h)
        local siner = (math.sin(CurTime() * 4) + 1) * .5 * 140

        GNIL.Ui.DrawRoundedMask(8, 1, 1, w - 2, h - 2, function()
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, self.Color)
            surface.SetDrawColor(ColorAlpha(self.accent,siner))
            surface.SetMaterial(gradRight)
            surface.DrawTexturedRect(w * .07, 0, w * .2, h)
            surface.SetMaterial(gradLeft)
            surface.DrawTexturedRect(w * .23, 0, w * .2, h)
            local size = h * .65
            GNIL.Ui.DrawImgur(w - size - (h - size) * .5, h * .5 - size * .5, size, size, self:GetExpanded() and "kMBw4p5" or "0982mqA", color_white)

        end)
    end)

    local oclick = self.Header.DoClick

    function self.Header.DoClick()
        oclick(self.Header)
    end

    self.Grid = vgui.Create("DIconLayout")
    self:SetContents(self.Grid)
    self.Grid:DockPadding(5, 5, 5, 5)
    self.Grid:Dock(FILL)
    local spacing = 5
    self.Grid:SetBorder(5)
    self.Grid:SetSpaceY(spacing)
    self.Grid:SetSpaceX(spacing)
end

function PANEL:SetName(name)
    self.CatName = name
end

function PANEL:AddItem(pnl)
    self.Grid:Add(pnl)
end

function PANEL:GetCanvas()
    return self.Grid
end

function PANEL:SetClrs(nav, bg, ac)
    self.Color = nav
    self.Bg = bg
    self.accent = ac
end

vgui.Register("GNIL.Ui.Category", PANEL, "DCollapsibleCategory")
