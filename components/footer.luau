local vide = require "../vide"

local theme = require "./qt/theme"
local config = require "../config"

local padding = require "./qt/padding"
local text = require "./qt/text"

local status = require "./status"

local function footer()
	return vide.create "Frame" {
		Name = "footer",
		BackgroundColor3 = theme(Enum.StudioStyleGuideColor.MainBackground),
		BorderSizePixel = 0,
		BorderMode = Enum.BorderMode.Outline,
		Size = function()
			return UDim2.new(1, 0, 0, config.footerSize())
		end,
		Position = function()
			return UDim2.new(0, 0, 1, -config.footerSize())
		end,
		
		padding {
			all = UDim.new(0, 8)
		},
		
		text {
			text = function()
				local tooltip, status = status.tooltip(), status.status()
				return (tooltip and tooltip ~= "" and tooltip) or (status and status ~= "" and status) or ""
			end,
			size = UDim2.new(1, 0, 1, 0),
			alignx = "Left"
		}
	}
end	

return footer