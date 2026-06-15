local vide = require "../../vide"

local style = require "../style"
local modal = require "../modal"
local status = require "../status"

local core = require "../../core/core"
local queue = require "../../core/queue"

local create = vide.create

local function columnHeader(props: { text: string, layoutOrder: number, fill: boolean?, maxWidth: number?, width: number? })
	return create "TextLabel" {
		Name = "header",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = if props.width then UDim2.new(0, props.width, 1, 2) else UDim2.new(0, 0, 1, 2),
		FontFace = style.font.bold,
		Text = props.text,
		TextColor3 = style.color.text,
		TextSize = 14,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		LayoutOrder = props.layoutOrder,

		create "UIPadding" {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 5),
			PaddingBottom = UDim.new(0, 4),
		},
		if props.width then create "UIFlexItem" { FlexMode = Enum.UIFlexMode.None } else nil,
		if props.fill
			then create "UISizeConstraint" { MinSize = Vector2.new(160, 0) }
			elseif props.maxWidth then create "UISizeConstraint" { MaxSize = Vector2.new(props.maxWidth, math.huge) }
			else nil,
	}
end

local function cell(props: { layoutOrder: number, fill: boolean?, maxWidth: number?, width: number?, children: any })
	return create "Frame" {
		Name = "cell",
		BackgroundTransparency = 1,
		Size = if props.width then UDim2.new(0, props.width, 1, 0) else UDim2.new(0, 0, 1, 0),
		LayoutOrder = props.layoutOrder,

		if props.width then create "UIFlexItem" { FlexMode = Enum.UIFlexMode.None } else nil,
		if props.fill
			then create "UISizeConstraint" { MinSize = Vector2.new(160, 0) }
			elseif props.maxWidth then create "UISizeConstraint" { MaxSize = Vector2.new(props.maxWidth, math.huge) }
			else nil,
		create "UIPadding" {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		},

		props.children,
	}
end

local function row(item: () -> queue.Item, layoutOrder: number)
	return create "Frame" {
		Name = "entry",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = layoutOrder,

		create "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},

		cell {
			layoutOrder = 1,
			fill = true,
			children = create "TextButton" {
				Name = "pill",
				AutoButtonColor = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, 0, 1, -8),
				BackgroundColor3 = function()
					return if item().selected() then style.color.accent else style.color.pill
				end,
				BackgroundTransparency = 0.75,
				FontFace = style.font.regular,
				Text = function()
					local e = item().entry
					return `{style.escape(e.name)} <font color="{style.dimHex}">({style.escape(e.objectName)})</font>`
				end,
				RichText = true,
				TextColor3 = style.color.text,
				TextSize = 14,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,

				create "UICorner" { CornerRadius = UDim.new(0, 4) },
				create "UIStroke" {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = function()
						return if item().selected() then style.color.accentStroke else style.color.pillStroke
					end,
					Thickness = 1,
				},
				create "UIPadding" {
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
					PaddingBottom = UDim.new(0, 2),
				},

				Activated = function()
					local selected = item().selected
					selected(not selected())
				end,

				MouseEnter = function()
					status.tooltip("Click to toggle whether this queue item is part of Build Selected")
				end,
				MouseLeave = function()
					status.tooltip("")
				end,
			},
		},

		cell {
			layoutOrder = 2,
			maxWidth = 160,
			children = style.pillButton {
				text = function()
					return item().entry.mapName
				end,
				tooltip = "Show the map model in the Explorer",
				anchorPoint = Vector2.new(0.5, 0.5),
				position = UDim2.fromScale(0.5, 0.5),
				size = UDim2.new(1, 0, 1, -8),
				automaticSize = Enum.AutomaticSize.None,
				activated = function()
					core.showInExplorer(item().entry.map or workspace)
				end,
			},
		},

		cell {
			layoutOrder = 3,
			maxWidth = 160,
			children = create "TextLabel" {
				Name = "config",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				FontFace = style.font.regular,
				Text = function()
					return item().config
				end,
				TextColor3 = style.color.text,
				TextSize = 14,
				TextWrapped = false,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,

				create "UIPadding" {
					PaddingLeft = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
				},
			},
		},

		cell {
			layoutOrder = 4,
			width = 70,
			children = style.pillButton {
				text = "Remove",
				tooltip = "Remove this item from the queue",
				alignx = Enum.TextXAlignment.Center,
				anchorPoint = Vector2.new(0.5, 0.5),
				position = UDim2.fromScale(0.5, 0.5),
				size = UDim2.new(1, 0, 1, -8),
				automaticSize = Enum.AutomaticSize.None,
				activated = function()
					queue.remove(item())
				end,
			},
		},
	}
end

local function queuePanel(props: { visible: () -> boolean })
	return create "Frame" {
		Name = "buildQueue",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -16, 1, -8),
		BackgroundTransparency = 1,
		Visible = props.visible,

		create "Frame" {
			Name = "columns",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),

			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			columnHeader { text = "Name / Object Name", layoutOrder = 1, fill = true },
			columnHeader { text = "Map Model", layoutOrder = 2, maxWidth = 160 },
			columnHeader { text = "Configuration", layoutOrder = 3, maxWidth = 160 },
			columnHeader { text = "", layoutOrder = 4, width = 70 },
		},

		create "Frame" {
			Name = "headerLine",
			Position = UDim2.fromOffset(0, 19),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = style.color.divider,
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
		},

		create "ScrollingFrame" {
			Name = "list",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 20),
			Size = UDim2.new(1, 0, 1, -50),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 4,

			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			vide.indexes(queue.source, function(item, index)
				return row(item, index)
			end),
		},

		create "TextLabel" {
			Name = "empty",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			FontFace = style.font.regular,
			Text = "The build queue is empty. Queue scripts from the Scripts tab.",
			TextColor3 = style.color.text,
			TextSize = 14,
			TextWrapped = true,
			Visible = function()
				return #queue.source() == 0
			end,
		},

		create "Frame" {
			Name = "footer",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,

			create "Frame" {
				Name = "footerLine",
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = style.color.divider,
				BackgroundTransparency = 0.75,
				BorderSizePixel = 0,
			},

			create "TextLabel" {
				Name = "status",
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 6, 0.5, 0),
				Size = UDim2.new(0.5, 0, 1, 0),
				FontFace = style.font.regular,
				Text = status.status,
				TextColor3 = style.color.text,
				TextSize = 14,
				TextWrapped = false,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
			},

			create "Frame" {
				Name = "buttons",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -4, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 20),
				BackgroundTransparency = 1,

				create "UIListLayout" {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 8),
					SortOrder = Enum.SortOrder.LayoutOrder,
				},

				style.pillButton {
					text = "Select All",
					tooltip = "Select every queue item",
					bold = true,
					layoutOrder = 1,
					activated = function()
						queue.selectAll(true)
					end,
				},
				style.pillButton {
					text = "Build Selected",
					tooltip = "Build every selected queue item, in order",
					bold = true,
					layoutOrder = 2,
					activated = function()
						local items = queue.selectedItems()
						if #items == 0 then
							return
						end
						modal.confirm(
							"Build Queue",
							`Build {#items} selected queue item(s) now?`,
							function()
								core.buildBatch(items)
								for _, item in items do
									queue.remove(item)
								end
							end
						)
					end,
				},
				style.pillButton {
					text = "Clear Queue",
					tooltip = "Remove every item from the queue",
					bold = true,
					layoutOrder = 3,
					activated = queue.clear,
				},
			},
		},
	}
end

return queuePanel
