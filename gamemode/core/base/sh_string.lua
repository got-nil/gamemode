---@class stringlib
local string = string

---@param font string
---@param str string
---@param max number
---@return string
---@return number
---@return number
string.TextWrap = function(font, str, max)
	surface.SetFont(font)
	local words = string.Explode(" ", str)
	local result = ""
	local line = ""
	local totalHeight = 0
	local lineHeight = 0

	for i = 1, #words do
		local word = words[i]
		local lineWidth, _ = surface.GetTextSize(line .. (#line > 0 and " " or "") .. word)
		local _, wordTall = surface.GetTextSize(word)
		if lineWidth > max then
			result = result .. line .. "\n"
			totalHeight = totalHeight + lineHeight
			line = word
			lineHeight = wordTall
		else
			line = line .. (#line > 0 and " " or "") .. word
			lineHeight = math.max(lineHeight, wordTall)
		end
	end

	result = result .. line
	totalHeight = totalHeight + lineHeight
	local wide, tall = surface.GetTextSize(result)
	return result, tall, wide
end
