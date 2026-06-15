local vide = require "./extern/vide"

local theme = require "./theme"
local config = require "../../config"

export type d<p> = (keyof<p>) -> any

local function createDerive(props, default)
	return function(name)
		return function()
			local prop = vide.read(props and props[name])
			if prop == nil then
				prop = vide.read(default and default[name])
			end
			return prop
		end
	end
end

return createDerive