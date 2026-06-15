local vide = require "../vide"

local style = require "./style"
local toolbar = require "./toolbar"

local scriptsPanel = require "./panels/scripts"
local queuePanel = require "./panels/queue"
local cheatsheetPanel = require "./panels/cheatsheet"
local aboutPanel = require "./panels/about"

local create = vide.create

local function viewport(props: { tab: vide.source<toolbar.Tab> })
	local tab = props.tab

	local function visible(id: toolbar.Tab)
		return function()
			return tab() == id
		end
	end

	return create "Frame" {
		Name = "viewport",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 1, -30),
		ZIndex = 0,

		create "UIPadding" {
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		},

		create "Frame" {
			Name = "background",
			BackgroundColor3 = style.color.panelBg,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),

			create "UICorner" { CornerRadius = UDim.new(0, 4) },
			create "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = style.color.pillStroke,
				Thickness = 1,
				Transparency = 0.7,
			},

			scriptsPanel { visible = visible("scripts") },
			queuePanel { visible = visible("queue") },
			cheatsheetPanel { visible = visible("cheatsheet") },
			aboutPanel { visible = visible("about") },
		},
	}
end

return viewport
