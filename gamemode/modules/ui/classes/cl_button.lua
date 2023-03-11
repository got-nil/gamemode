local PANEL = {}

function PANEL:Init()
    self:GLib()
    self:SetText("")
    self:SetTextColor(color_white)
    self:SetFont(GNIL.Ui.ensureFontExists("GNIL_MontserratM", 14))
    self:ClearPaint():Background(GNIL.Ui.Colors["MainAccent"], 8)
end

vgui.Register("GNIL.Ui.Button", PANEL, "DButton")