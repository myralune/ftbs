local vide = require "../../vide"

local style = require "../style"
local modal = require "../modal"
local status = require "../status"

local core = require "../../core/core"
local srclist = require "../../core/srclist"
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
			then create "UISizeConstraint" { MinSize = Vector2.new(props.maxWidth or 160, 0) }
			elseif props.maxWidth then create "UISizeConstraint" { MaxSize = Vector2.new(props.maxWidth, math.huge) }
			else nil,
	}
end

-- A cell of the row; fill cells stretch, capped cells stop at maxWidth, fixed cells opt out of flex
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

local function queueEntry(entry: srclist.Entry)
	if #entry.configs > 1 then
		modal.pick(
			"Queue Build",
			`Queue "{entry.name}" with which configuration?`,
			entry.configs,
			function(config)
				queue.add(entry, config)
			end
		)
	else
		queue.add(entry, "$default")
	end
end

local function buildEntryNow(entry: srclist.Entry)
	if #entry.configs > 1 then
		modal.pick(
			"Immediate Build",
			`Build "{entry.name}" immediately with which configuration?`,
			entry.configs,
			function(config)
				core.buildEntry(entry.script, entry.map, config)
			end
		)
	else
		modal.confirm(
			"Immediate Build",
			`Build the Timelines object for "{entry.name}" immediately?`,
			function()
				core.buildEntry(entry.script, entry.map)
			end
		)
	end
end

local function row(entry: () -> srclist.Entry, layoutOrder: number)
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
			children = style.pillButton {
				text = function()
					local e = entry()
					return `{style.escape(e.name)} <font color="{style.dimHex}">({style.escape(e.objectName)})</font>`
				end,
				richText = true,
				tooltip = "Open the build script in the script editor (right-click for more actions)",
				anchorPoint = Vector2.new(0.5, 0.5),
				position = UDim2.fromScale(0.5, 0.5),
				size = UDim2.new(1, 0, 1, -8),
				automaticSize = Enum.AutomaticSize.None,
				activated = function()
					core.openScriptDocument(entry().script)
				end,
				rightClicked = function()
					task.spawn(core.openScriptMenu, entry())
				end,
			},
		},

		cell {
			layoutOrder = 2,
			maxWidth = 160,
			children = style.pillButton {
				text = function()
					return entry().mapName
				end,
				tooltip = "Show the map model in the Explorer",
				anchorPoint = Vector2.new(0.5, 0.5),
				position = UDim2.fromScale(0.5, 0.5),
				size = UDim2.new(1, 0, 1, -8),
				automaticSize = Enum.AutomaticSize.None,
				activated = function()
					core.showInExplorer(entry().map or workspace)
				end,
			},
		},

		cell {
			layoutOrder = 3,
			maxWidth = 160,
			children = create "TextLabel" {
				Name = "configs",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				FontFace = style.font.regular,
				Text = function()
					return table.concat(entry().configs, ", ")
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
			width = 130,
			children = {
				create "UIListLayout" {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
				style.pillButton {
					text = "Queue",
					tooltip = "Add this script to the build queue",
					accent = true,
					alignx = Enum.TextXAlignment.Center,
					size = UDim2.new(0.5, -2, 1, -8),
					automaticSize = Enum.AutomaticSize.None,
					layoutOrder = 1,
					activated = function()
						queueEntry(entry())
					end,
				},
				style.pillButton {
					text = "Build",
					tooltip = "Build this script's Timelines object now",
					accent = true,
					alignx = Enum.TextXAlignment.Center,
					size = UDim2.new(0.5, -2, 1, -8),
					automaticSize = Enum.AutomaticSize.None,
					layoutOrder = 2,
					activated = function()
						buildEntryNow(entry())
					end,
				},
			},
		},
	}
end

local function scriptsPanel(props: { visible: () -> boolean })
	return create "Frame" {
		Name = "scripts",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -16, 1, -8),
		BackgroundTransparency = 1,
		Visible = props.visible,

		-- column headers
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
			columnHeader { text = "Available Configs", layoutOrder = 3, maxWidth = 160 },
			columnHeader { text = "", layoutOrder = 4, width = 130 },
		},

		create "Frame" {
			Name = "headerLine",
			Position = UDim2.fromOffset(0, 19),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = style.color.divider,
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
		},

		-- script list
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

			vide.indexes(srclist.source, function(entry, index)
				return row(entry, index)
			end),
		},

		-- empty state
		create "TextLabel" {
			Name = "empty",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			FontFace = style.font.regular,
			Text = "No build scripts found. Use New to create one, or Refresh to rescan the place.",
			TextColor3 = style.color.text,
			TextSize = 14,
			TextWrapped = true,
			Visible = function()
				return #srclist.source() == 0
			end,
		},

		-- footer actions
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
					text = "Add All to Queue",
					tooltip = "Queue every listed script with its $default configuration",
					bold = true,
					layoutOrder = 1,
					activated = function()
						for _, entry in srclist.source() do
							queue.add(entry, "$default")
						end
					end,
				},
				style.pillButton {
					text = "Build All Immediately",
					tooltip = "Build every listed script now with its $default configuration",
					bold = true,
					layoutOrder = 2,
					activated = function()
						local entries = srclist.source()
						if #entries == 0 then
							return
						end
						modal.confirm(
							"Immediate Build",
							`Build all {#entries} script(s) immediately?`,
							function()
								local items = {}
								for _, entry in entries do
									items[#items + 1] = { entry = entry, config = "$default" }
								end
								core.buildBatch(items)
							end
						)
					end,
				},
			},
		},
	}
end

return scriptsPanel
