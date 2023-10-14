local MODULE, renderTarget = MODULE, false
local MaskMaterial = CreateMaterial("!mask_material_rounded", "UnlitGeneric", {
	["$translucent"] = 1,
	["$vertexalpha"] = 1,
	["$alpha"] = 1,
})

local function renderTargetGen()
	renderTarget = GetRenderTargetEx("rendertarget_roundedbox_material", ScrW(), ScrH(), RT_SIZE_FULL_FRAME_BUFFER, MATERIAL_RT_DEPTH_NONE, 2, CREATERENDERTARGETFLAGS_UNFILTERABLE_OK, IMAGE_FORMAT_RGBA8888)
end

renderTargetGen()

MODULE:AddHook("OnScreenSizeChanged", "update_mask", function()
	renderTargetGen()
end)

local function drawRoundedMask(radius, x, y, w, h, drawfunc, tl, tr, bl, br)
	if not renderTarget then
		renderTargetGen()
	end

	render.PushRenderTarget(renderTarget)
		render.OverrideAlphaWriteEnable(true, true)
		render.Clear(0, 0, 0, 0)

			drawfunc()

		render.OverrideBlendFunc(true, BLEND_ZERO, BLEND_SRC_ALPHA, BLEND_DST_ALPHA, BLEND_ZERO)
		draw.RoundedBoxEx(radius, x, y, w, h, color_white, tl, tr, bl, br)
		render.OverrideBlendFunc(false)
		render.OverrideAlphaWriteEnable(false)

	render.PopRenderTarget()
		MaskMaterial:SetTexture("$basetexture", renderTarget)
		draw.NoTexture()
		surface.SetDrawColor(color_white)
		surface.SetMaterial(MaskMaterial)
		render.SetMaterial(MaskMaterial)
	render.DrawScreenQuad()
end

function GNIL.UI.DrawRoundedMask(cornerRadius, x, y, w, h, drawFunc)
	drawRoundedMask(cornerRadius, x, y, w, h, drawFunc, true, true, true, true)
end

function GNIL.UI.DrawRoundedExMask(cornerRadius, x, y, w, h, drawFunc, roundTopLeft, roundTopRight, roundBottomLeft, roundBottomRight)
	drawRoundedMask(cornerRadius, x, y, w, h, drawFunc, roundTopLeft, roundTopRight, roundBottomLeft, roundBottomRight)
end