local PANEL = {}
local Expand_Less = Material("GNIL.Ui/expand_less.png", "noclamp smooth mips")
local Expand_More = Material("GNIL.Ui/expand_more.png", "noclamp smooth mips")

function PANEL:Init()
    self:SetHeaderHeight(50)
    self:SetLabel("")

    self.Header.Paint = function(s, w, h)
        draw.RoundedBox(5, 0, 0, w, h, self.Color)
        local size = h * .95
        local hh = h * .5
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(self:GetExpanded() and Expand_Less or Expand_More)
        surface.DrawTexturedRect(w - size - (h - size) * .5, h * .5 - size * .5, size, size)
        draw.RoundedBox(15, 0, 0, 5, h, self.NavColor or color_white)
        draw.SimpleText(self.CatName or "", GNIL.Ui.ensureFontExists("GNIL_MontserratM", 3), 15, hh, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

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

function PANEL:NavColor(clr)
    self.NavColor = clr
end

function PANEL:Color(clr)
    self.Color = clr
end

vgui.Register("GNIL.Ui.Category", PANEL, "DCollapsibleCategory")