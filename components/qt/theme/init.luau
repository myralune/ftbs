local vide = require "./extern/vide"
local connect = require "./extern/connect"

local studioSettings = settings().Studio
local currentTheme = vide.source(studioSettings.Theme)

local colors = {}

local function theme(color: Enum.StudioStyleGuideColor, modifier: Enum.StudioStyleGuideModifier)
	--color = vide.read(color)
	--modifier = vide.read(modifier)
	
	--assert(typeof(color) == "EnumItem" and color.EnumType == Enum.StudioStyleGuideColor, "invalid theme color")
	--if typeof(modifier) == "EnumItem" then
	--	assert(typeof(modifier) == "EnumItem" and modifier.EnumType == Enum.StudioStyleGuideModifier, "invalid theme modifier")
	--else
	--	modifier = Enum.StudioStyleGuideModifier.Default
	--end
	
	--local set = colors[color]
	--if not set then
	--	set = {}
	--	colors[color] = set
	--end
	
	--local src = set[modifier]
	--if not src then
	--	src = vide.source(currentTheme:GetColor(color, modifier))
	--	set[modifier] = src
	--end
	--return src
	
	return function()
		return currentTheme():GetColor(vide.read(color), vide.read(modifier))
	end
end

connect(studioSettings.ThemeChanged:Connect(function()
	currentTheme(studioSettings.Theme)
	--local theme = studioSettings.Theme
	--vide.batch(function()
	--	for color, set in colors do
	--		for modifier, src in set do
	--			src(currentTheme():GetColor(color, modifier))
	--		end
	--	end
	--end)
end))

return theme