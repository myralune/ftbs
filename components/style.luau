local vide = require "../vide"

local status = require "./status"

local create = vide.create
local read = vide.read

local style = {}

style.color = table.freeze {
	windowBg     = Color3.new(0.098039, 0.101961, 0.121569),
	panelBg      = Color3.new(0, 0, 0),                      -- transparency 0.9
	text         = Color3.new(0.737255, 0.745098, 0.784314),
	textBright   = Color3.new(0.956863, 0.956863, 0.956863),
	pill         = Color3.new(0.631373, 0.631373, 0.631373), -- transparency 0.75
	pillStroke   = Color3.new(0.247059, 0.247059, 0.247059),
	accent       = Color3.new(0.2, 0.372549, 1),             -- transparency 0.75
	accentStroke = Color3.new(0.12549, 0.235294, 0.631373),
	divider      = Color3.new(0.631373, 0.631373, 0.631373), -- transparency 0.75
	tooltipBg    = Color3.new(0.12549, 0.12549, 0.12549),
	modalStroke  = Color3.new(0.12549, 0.133333, 0.152941),
}

local FONT_ID = "rbxassetid://16658221428"

-- hex of style.color.text darkened, for de-emphasised rich text spans
style.dimHex = "#74767E"

function style.escape(text: string): string
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"))
end

style.font = table.freeze {
	regular = Font.new(FONT_ID, Enum.FontWeight.Regular),
	bold = Font.new(FONT_ID, Enum.FontWeight.Bold),
	mono = Font.new("rbxasset://fonts/families/RobotoMono.json"),
}

local function withTooltip(tooltip)
	if tooltip == nil then
		return nil
	end
	return {
		MouseEnter = function()
			status.tooltip(read(tooltip) or "")
		end,
		MouseLeave = function()
			status.tooltip("")
		end,
	}
end

-- Flat toolbar/tab button: window-coloured, rounded, bold label
function style.toolbarButton(props: {
	text: any,
	tooltip: string?,
	selected: (() -> boolean)?,
	layoutOrder: number?,
	activated: () -> (),
})
	return create "TextButton" {
		Name = read(props.text),
		AutoButtonColor = true,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = function()
			if props.selected and props.selected() then
				return style.color.pill
			end
			return style.color.windowBg
		end,
		BackgroundTransparency = function()
			if props.selected and props.selected() then
				return 0.75
			end
			return 0
		end,
		FontFace = style.font.bold,
		Text = props.text,
		TextColor3 = style.color.text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = props.layoutOrder or 0,

		create "UICorner" { CornerRadius = UDim.new(0, 4) },
		create "UIPadding" {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 2),
		},

		Activated = props.activated,
		withTooltip(props.tooltip),
	}
end

-- Pill button: grey translucent with stroke (list rows, panel footers, modals)
function style.pillButton(props: {
	text: any,
	tooltip: string?,
	accent: boolean?,
	bold: boolean?,
	richText: boolean?,
	alignx: Enum.TextXAlignment?,
	layoutOrder: number?,
	size: UDim2?,
	anchorPoint: Vector2?,
	position: UDim2?,
	automaticSize: Enum.AutomaticSize?,
	activated: (() -> ())?,
	rightClicked: (() -> ())?,
	children: any?,
})
	return create "TextButton" {
		Name = "pill",
		AutoButtonColor = true,
		AutomaticSize = props.automaticSize or Enum.AutomaticSize.X,
		Size = props.size or UDim2.fromScale(0, 1),
		AnchorPoint = props.anchorPoint,
		Position = props.position,
		BackgroundColor3 = if props.accent then style.color.accent else style.color.pill,
		BackgroundTransparency = 0.75,
		FontFace = if props.bold then style.font.bold else style.font.regular,
		Text = props.text,
		RichText = props.richText or false,
		TextColor3 = style.color.text,
		TextSize = 14,
		TextXAlignment = props.alignx or Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = props.layoutOrder or 0,

		create "UICorner" { CornerRadius = UDim.new(0, 4) },
		create "UIStroke" {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = if props.accent then style.color.accentStroke else style.color.pillStroke,
			Thickness = 1,
		},
		create "UIPadding" {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 2),
		},

		Activated = props.activated,
		MouseButton2Click = props.rightClicked,
		withTooltip(props.tooltip),

		props.children,
	}
end

-- Plain body label
function style.label(props: {
	text: any,
	bold: boolean?,
	textSize: number?,
	wrap: boolean?,
	richText: boolean?,
	layoutOrder: number?,
	size: UDim2?,
	automaticSize: Enum.AutomaticSize?,
	alignx: Enum.TextXAlignment?,
	aligny: Enum.TextYAlignment?,
})
	return create "TextLabel" {
		Name = "label",
		BackgroundTransparency = 1,
		AutomaticSize = props.automaticSize or Enum.AutomaticSize.Y,
		Size = props.size or UDim2.fromScale(1, 0),
		FontFace = if props.bold then style.font.bold else style.font.regular,
		Text = props.text,
		RichText = props.richText or false,
		TextColor3 = style.color.text,
		TextSize = props.textSize or 14,
		TextWrapped = if props.wrap == nil then true else props.wrap,
		TextXAlignment = props.alignx or Enum.TextXAlignment.Left,
		TextYAlignment = props.aligny or Enum.TextYAlignment.Center,
		LayoutOrder = props.layoutOrder or 0,
	}
end

-- 1px horizontal rule
function style.divider(layoutOrder: number?)
	return create "Frame" {
		Name = "divider",
		BackgroundColor3 = style.color.divider,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		LayoutOrder = layoutOrder or 0,
	}
end

return style
