--[[
	Modal dialogs (ported from the mockup's Modal frame).
	`modal.show` puts a dialog up; the rendered layer lives in app.luau.
]]

local vide = require "../vide"

local style = require "./style"

local create = vide.create

local modal = {}

export type Option = { label: string, action: (() -> ())? }

local current = vide.source(nil :: {
	title: string,
	message: string,
	options: { Option },
}?)

function modal.show(props: { title: string, message: string, options: { Option } })
	current(props)
end

-- Yes/No confirmation
function modal.confirm(title: string, message: string, onYes: () -> ())
	modal.show {
		title = title,
		message = message,
		options = {
			{ label = "Yes", action = onYes },
			{ label = "No" },
		},
	}
end

-- One button per choice
function modal.pick(title: string, message: string, choices: { string }, onPick: (string) -> ())
	local options: { Option } = {}
	for _, choice in choices do
		options[#options + 1] = {
			label = choice,
			action = function()
				onPick(choice)
			end,
		}
	end
	options[#options + 1] = { label = "Cancel" }
	modal.show {
		title = title,
		message = message,
		options = options,
	}
end

function modal.dismiss()
	current(nil)
end

function modal.render()
	local options = vide.derive(function()
		local shown = current()
		return shown and shown.options or {}
	end)

	return create "Frame" {
		Name = "modal",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
		Visible = function()
			return current() ~= nil
		end,

		create "Frame" {
			Name = "window",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromOffset(360, 0),
			BackgroundColor3 = style.color.windowBg,
			BorderSizePixel = 0,

			create "UICorner" { CornerRadius = UDim.new(0, 8) },
			create "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = style.color.modalStroke,
				Thickness = 1,
			},

			create "Frame" {
				Name = "titlebar",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30),

				create "Frame" {
					Name = "line",
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.fromScale(0, 1),
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = style.color.modalStroke,
					BorderSizePixel = 0,
				},

				create "TextLabel" {
					Name = "header",
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(0, 0.5),
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromScale(0, 1),
					FontFace = style.font.bold,
					Text = function()
						local shown = current()
						return shown and shown.title or ""
					end,
					TextColor3 = style.color.text,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,

					create "UIPadding" {
						PaddingLeft = UDim.new(0, 12),
						PaddingRight = UDim.new(0, 12),
					},
				},
			},

			create "Frame" {
				Name = "body",
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Position = UDim2.fromOffset(0, 30),
				Size = UDim2.fromScale(1, 0),

				create "UIListLayout" {
					FillDirection = Enum.FillDirection.Vertical,
					Padding = UDim.new(0, 12),
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
				create "UIPadding" {
					PaddingTop = UDim.new(0, 12),
					PaddingBottom = UDim.new(0, 12),
					PaddingLeft = UDim.new(0, 12),
					PaddingRight = UDim.new(0, 12),
				},

				style.label {
					text = function()
						local shown = current()
						return shown and shown.message or ""
					end,
					layoutOrder = 0,
					aligny = Enum.TextYAlignment.Top,
				},

				create "Frame" {
					Name = "buttons",
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.XY,
					LayoutOrder = 1,

					create "UIListLayout" {
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, 8),
						SortOrder = Enum.SortOrder.LayoutOrder,
						Wraps = true,
					},

					vide.indexes(options, function(option, index)
						return style.pillButton {
							text = function()
								return option().label
							end,
							bold = true,
							layoutOrder = index,
							automaticSize = Enum.AutomaticSize.XY,
							size = UDim2.new(),
							activated = function()
								local chosen = option()
								modal.dismiss()
								if chosen.action then
									task.spawn(chosen.action)
								end
							end,
						}
					end),
				},
			},
		},
	}
end

return modal
