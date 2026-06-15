local vide = require "../../vide"

local style = require "../style"

local create = vide.create

local VERSION = "1.0.0"

local function person(name: string, role: string, layoutOrder: number)
	return create "Frame" {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = layoutOrder,

		create "UIPadding" {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 4),
		},

		create "TextLabel" {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.5),
			FontFace = style.font.bold,
			Text = name,
			TextColor3 = style.color.text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
		},
		create "TextLabel" {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromScale(1, 0.5),
			FontFace = style.font.regular,
			Text = role,
			TextColor3 = style.color.text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		},
	}
end

local function selectableText(text: string, layoutOrder: number)
	return create "TextBox" {
		Name = "text",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		FontFace = style.font.regular,
		Text = text,
		RichText = true,
		TextColor3 = style.color.text,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextEditable = false,
		ClearTextOnFocus = false,
		MultiLine = true,
		LayoutOrder = layoutOrder,
	}
end

local function aboutPanel(props: { visible: () -> boolean })
	return create "ScrollingFrame" {
		Name = "about",
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
			text = "About Flood Timelines System Plugin",
			bold = true,
			textSize = 20,
			layoutOrder = -11,
		},
		style.label {
			text = `Version {VERSION}`,
			bold = true,
			textSize = 16,
			layoutOrder = -10,
		},
		style.divider(-9),

		selectableText("Build system for script-oriented Timelines objects for Flood Escape 2", 0),

		style.label {
			text = "Authors",
			bold = true,
			textSize = 20,
			layoutOrder = 4,
		},
		create "Frame" {
			Name = "authors",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			LayoutOrder = 5,

			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			person("Contrastual", "Author, maintainer, build system syntax", 1),
			person("myralune", "Author and maintainer", 2),
		},

		style.label {
			text = "Licenses",
			bold = true,
			textSize = 20,
			layoutOrder = 6,
		},
		selectableText(
			"Flood Timelines Build System Plugin is licensed under the GNU General Public License v3.0. "
				.. "You can find the license on the github page or by searching for it on the web."
				.. "Github: https://github.com/myralune/ftbs/",
			7
		),
	}
end

return aboutPanel
