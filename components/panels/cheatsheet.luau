local vide = require "../../vide"

local style = require "../style"
local core = require "../../core/core"

local create = vide.create

local function cheatsheetPanel(props: { visible: () -> boolean })
	return create "ScrollingFrame" {
		Name = "cheatsheet",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -8, 1, -8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		Visible = props.visible,

		create "UIListLayout" {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		create "UIPadding" {
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
		},

		style.label {
			text = "Flood Timelines Build Script Cheatsheet",
			bold = true,
			textSize = 20,
			layoutOrder = -1,
		},

		create "TextBox" {
			Name = "text",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromScale(1, 0),
			FontFace = style.font.mono,
			Text = core.cheatsheetText,
			TextColor3 = style.color.text,
			TextSize = 14,
			TextWrapped = false,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextEditable = false,
			ClearTextOnFocus = false,
			MultiLine = true,
			LayoutOrder = 1,
		},

		style.divider(2),
	}
end

return cheatsheetPanel
