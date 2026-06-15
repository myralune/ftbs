local vide = require "./extern/vide"

local theme = require "./theme"
local config = require "../../config"

local base = require "./base"
local createderive = require "./createderive"
local padding = require "./padding"

local function text(
	props: base.props & {
		text: string,
		alignx: Enum.TextXAlignment,
		aligny: Enum.TextYAlignment,
		textSize: number,
		wrap: boolean,
		truncate: Enum.TextTruncate,
	}
)
	local state = vide.source(Enum.StudioStyleGuideModifier.Default)
	local derive: createderive.d<base.props> = createderive(props, {
		text = "",
		color = Enum.StudioStyleGuideColor.MainText,
		modifier = Enum.StudioStyleGuideModifier.Default,
		textSize = config.bodySize,
		alignx = Enum.TextXAlignment.Center,
		aligny = Enum.TextYAlignment.Center,
		wrap = true,
		truncate = Enum.TextTruncate.SplitWord,
		automaticSize = Enum.AutomaticSize.XY,
		padding = {
			all = UDim.new(0, 8),
			bottom = UDim.new(0, 2),
			top = UDim.new(0, 0)
		}
	})
	
	return vide.create "TextLabel" {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = derive "text",
		TextColor3 = theme(
			derive "color",
			derive "modifier"
		),
		TextTruncate = Enum.TextTruncate.SplitWord,
		TextWrapped = derive "wrap",
		TextXAlignment = derive "alignx",
		TextYAlignment = derive "aligny",
		TextSize = derive "textSize",
		
		base(props, {
			name = "qText",
			size = UDim2.fromOffset(0, 22),
		}),
	}
end

return text