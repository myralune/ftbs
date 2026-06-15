local vide = require "../vide"

local create = vide.create

local theme = require "./qt/theme"
local config = require "../config"

local base = require "./qt/base"
local padding = require "./qt/padding"
local button = require "./qt/button"

local function header(
	props: {
		leftButtons: {
			{
				name: string,
				tooltip: string,
				onActivated: () -> ()
			}
		},
		rightButtons: {
			{
				name: string,
				tooltip: string,
				onActivated: () -> ()
			}
		},
		buildScripts: {
			{
				name: string,
				script: ModuleScript,
				configurationScripts: ModuleScript
			}
		}
	}
)
	return create "Frame" {
		BackgroundColor3 = theme(Enum.StudioStyleGuideColor.MainBackground),
		
		base(props, {
			name = "ftlsHeader",
			size = function()
				return UDim2.new(1, 0, 0, config.headerSize())
			end,
			padding = {
				all = UDim.new(0, 5)
			}
		}),
		
		create "Frame" {
			Name = "left",
			AutomaticSize = "X",
			Size = UDim2.fromScale(0, 1),
			BackgroundTransparency = 1,
			
			create "UIListLayout" {
				FillDirection = "Horizontal",
				VerticalAlignment = "Center",
				Padding = UDim.new(0, 8)
			},
			
			vide.indexes(props.leftButtons, function(item)
				local item = item()
				return button {
					text = item.name,
					tooltip = item.tooltip,
					events = {
						MouseButton1Click = item.onActivated
					}
				}
			end)
		},
		
		create "Frame" {
			Name = "right",
			AutomaticSize = "X",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromScale(0, 1),
			BackgroundTransparency = 1,
			
			create "UIListLayout" {
				FillDirection = "Horizontal",
				VerticalAlignment = "Center",
				Padding = UDim.new(0, 8)
			},
			
			vide.indexes(props.rightButtons, function(item)
				local item = item()
				return button {
					text = item.name,
					tooltip = item.tooltip,
					events = {
						MouseButton1Click = item.onActivated
					}
				}
			end)
		}
	}
end

return header