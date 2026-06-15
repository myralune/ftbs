--!nonstrict

local vide = require "./extern/vide"

local theme = require "./theme"
local config = require "../../config"

local createderive = require "./createderive"
local padding = require "./padding"

export type props = {
	children: {}?,
	events: {[string]: (...any) -> ()}?,
	
	name: string,
	visible: boolean,
	color: Enum.StudioStyleGuideColor,
	modifier: Enum.StudioStyleGuideModifier,
	interactable: boolean,
	zindex: number,
	
	automaticSize: Enum.AutomaticSize,
	size: UDim2,
	position: UDim2,
	anchorPoint: Vector2,
	
	borderStyle: Enum.BorderMode,
	borderThickness: number,
	borderColor: Color3,
	
	padding: {
		all: UDim,
		left: UDim,
		right: UDim,
		top: UDim,
		bottom: UDim,
	}
}

local base_default: props = table.freeze {
	__index = table.freeze {
		name = "qUIObject",
		visible = true,
		color = Enum.StudioStyleGuideColor.MainBackground,
		modifier = Enum.StudioStyleGuideModifier.Default,
		interactable = true,
		zindex = 1,
		automaticSize = Enum.AutomaticSize.None,
		size = UDim2.fromOffset(100, 20),
		position = UDim2.new(),
		anchorPoint = Vector2.zero,
		
		borderStyle = Enum.BorderMode.Outline,
		borderThickness = 0,
		borderColor = Color3.new(),
		
		padding = table.freeze {}
	}
}

local function base(props: props, default: props)
	props = props or {}
	default = default or {}
	
	local default = table.clone(default)
	default = setmetatable(default, base_default)
	local derive: createderive.d<props> = createderive(props, default)
	
	return {
		Name = derive "name",
		Visible = derive "visible",
		BackgroundColor3 = theme(derive "color", derive "modifier"),
		Interactable = derive "interactable",
		ZIndex = derive "zindex",
		AutomaticSize = derive "automaticSize",
		Size = derive "size",
		Position = derive "position",
		AnchorPoint = derive "anchorPoint",
		BorderMode = derive "borderStyle",
		BorderSizePixel = derive "borderThickness",
		BorderColor3 = derive "borderColor",
		
		padding(vide.read(derive "padding")),
		props.children,
		props.events
	}
end

return base