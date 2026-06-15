local vide = require "./extern/vide"

local theme = require "./theme"
local config = require "../../config"

local base = require "./base"
local createderive = require "./createderive"
local padding = require "./padding"

local status = require "../status"

local function button(
	props: base.props & {
		text: string,
		textColor: Color3,
		tooltip: string?,
		disabled: boolean
	}
)
	local state = vide.source(Enum.StudioStyleGuideModifier.Default)
	local derive = createderive(props, {
		text = "",
		textColor = theme(Enum.StudioStyleGuideColor.ButtonText, state),
		tooltip = nil,
		disabled = false
	})
	
	return vide.create "TextButton" {
		base(props, {
			name = "qt-button",
			color = Enum.StudioStyleGuideColor.Button,
			modifier = state,
			borderStyle = Enum.BorderMode.Outline,
			borderThickness = 1,
			automaticSize = Enum.AutomaticSize.X,
			size = UDim2.fromOffset(0, 20),
			borderColor = theme(Enum.StudioStyleGuideColor.ButtonBorder, state),
		}),
		
		padding {
			bottom = UDim.new(0, 2),
			left = UDim.new(0, 8),
			right = UDim.new(0, 8),
		},
		
		RichText = true,
		Text = derive "text",
		TextColor3 = derive "textColor",
		TextTruncate = "SplitWord",
		TextSize = config.bodySize,
		
		vide.changed("Selected", function(isSelected)
			if isSelected then
				state(Enum.StudioStyleGuideModifier.Selected)
			end
		end),
		
		MouseEnter = function()
			vide.batch(function()
				state(Enum.StudioStyleGuideModifier.Hover)
				status.tooltip(vide.read(props.tooltip) or "")
			end)
		end,
		
		MouseLeave = function()
			vide.batch(function()
				state(Enum.StudioStyleGuideModifier.Default)
				status.tooltip("")
			end)
		end,
		
		MouseButton1Down = function()
			state(Enum.StudioStyleGuideModifier.Pressed)
		end,
		
		MouseButton1Up = function()
			state(Enum.StudioStyleGuideModifier.Hover)
		end,
	}
end

return button