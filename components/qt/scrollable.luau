local vide = require ("./extern/vide" :: typeof(script.Parent.Parent.Parent.vide))

local theme = require "./theme"
local config = require "../../config"

local base = require "./base"
local createderive = require "./createderive"
local padding = require "./padding"

local scrollbar = require "./scrollbar"

local function scrollable(
	props: {
		direction: "X" | "Y" | "XY",
		canvasSize: Vector2,
		canvasPosition: Vector2,
		container: any
	}
)
	return vide.create "Frame" {
		base(props, {
			name = "qt-scrollbox",
			color = Enum.StudioStyleGuideColor.MainBackground,
			borderThickness = 0,
			size = UDim2.fromScale(1, 1)
		}),
		
		ClipsDescendants = true,
		
		vide.create "Frame" {
			base(props, {
				name = "qt-scrollbox-view",
				color = Enum.StudioStyleGuideColor.MainBackground,
				borderThickness = 0,
				automaticSize = Enum.AutomaticSize.XY
			}),
			
			props.container
		}
	}
end

return scrollable