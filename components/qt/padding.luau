local vide = require "./extern/vide"

local createderive = require "./createderive"

local function padding(
	props: {
		all: UDim,
		left: UDim,
		right: UDim,
		top: UDim,
		bottom: UDim,
	}
)
	--local derive = createderive(props, {
	--	all = UDim.new(),
	--	--left = UDim.new(),
	--	--right = UDim.new(),
	--	--top = UDim.new(),
	--	--bottom = UDim.new(),
	--})
	
	local function explicit_or_all(name)
		return function()
			return vide.read(props[name]) or vide.read(props.all) or UDim.new()
		end
	end
	
	return vide.create "UIPadding" {
		Name = "qPadding",
		PaddingTop = explicit_or_all("top"),
		PaddingLeft = explicit_or_all("left"),
		PaddingRight = explicit_or_all("right"),
		PaddingBottom = explicit_or_all("bottom"),
	}
end

return padding