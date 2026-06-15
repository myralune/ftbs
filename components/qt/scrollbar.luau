local vide = require "./extern/vide"

local theme = require "./theme"
local config = require "../../config"

local function scrollbar(
	props: {
		direction: "X" | "Y",
		max: number,
		position: number,
		width: number,
		visible: boolean
	}
)
	
end

return scrollbar