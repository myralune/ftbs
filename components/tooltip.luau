--[[
	Floating tooltip that follows the mouse inside the widget.
	Driven by the status.tooltip source (set on hover by styled buttons).
]]

local vide = require "../vide"
local connect = require "../connect"

local style = require "./style"
local status = require "./status"

local create = vide.create

local function tooltip(widget: PluginGui)
	local mousePosition = vide.source(Vector2.zero)
	local frame: Frame? = nil

	connect(game:GetService("RunService").Heartbeat:Connect(function()
		if status.tooltip() ~= "" then
			mousePosition(widget:GetRelativeMousePosition())
		end
	end))

	return create "Frame" {
		Name = "tooltip",
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = style.color.tooltipBg,
		BorderSizePixel = 0,
		ZIndex = 100,
		Visible = function()
			return status.tooltip() ~= ""
		end,
		Position = function()
			local p = mousePosition()
			local x, y = p.X + 12, p.Y + 18

			-- keep the tooltip inside the widget
			if frame then
				local size = frame.AbsoluteSize
				local bounds = widget.AbsoluteSize
				x = math.clamp(x, 0, math.max(0, bounds.X - size.X - 2))
				if y + size.Y + 2 > bounds.Y then
					y = math.max(0, p.Y - size.Y - 6)
				end
			end

			return UDim2.fromOffset(x, y)
		end,

		vide.action(function(instance)
			frame = instance :: Frame
		end),

		create "UICorner" { CornerRadius = UDim.new(0, 4) },
		create "UIStroke" {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = style.color.pillStroke,
			Thickness = 1,
		},
		create "UIPadding" {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 8),
		},

		create "TextLabel" {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.XY,
			FontFace = style.font.regular,
			Text = status.tooltip,
			TextColor3 = style.color.textBright,
			TextSize = 14,
		},
	}
end

return tooltip
