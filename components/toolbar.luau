local vide = require "../vide"

local style = require "./style"

local create = vide.create

export type Tab = "scripts" | "queue" | "cheatsheet" | "about"

local function toolbar(props: {
	tab: vide.source<Tab>,
	actions: {
		new: () -> (),
		import: () -> (),
		export: () -> (),
		generate: () -> (),
		refresh: () -> (),
	},
})
	local tab = props.tab

	local function tabButton(id: Tab, label: string, tooltip: string, layoutOrder: number)
		return style.toolbarButton {
			text = label,
			tooltip = tooltip,
			layoutOrder = layoutOrder,
			selected = function()
				return tab() == id
			end,
			activated = function()
				tab(id)
			end,
		}
	end

	return create "Frame" {
		Name = "toolbar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),

		create "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		create "UIPadding" {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		},

		create "Frame" {
			Name = "controls",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			LayoutOrder = 0,

			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			create "UIFlexItem" { FlexMode = Enum.UIFlexMode.Shrink },

			style.toolbarButton {
				text = "New",
				tooltip = "Create a new build script from the template",
				layoutOrder = 1,
				activated = props.actions.new,
			},
			style.toolbarButton {
				text = "Import",
				tooltip = "Import a build script from a local file (.ftbs.luau)",
				layoutOrder = 2,
				activated = props.actions.import,
			},
			style.toolbarButton {
				text = "Export",
				tooltip = "Export a build script to your file system",
				layoutOrder = 3,
				activated = props.actions.export,
			},
			style.toolbarButton {
				text = "Generate",
				tooltip = "Generate a build script from a map's existing Timelines folder",
				layoutOrder = 4,
				activated = props.actions.generate,
			},
			style.toolbarButton {
				text = "Refresh",
				tooltip = "Rescan the place for build scripts",
				layoutOrder = 5,
				activated = props.actions.refresh,
			},
		},

		create "Frame" {
			Name = "flexible",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			LayoutOrder = 2,
		},

		create "Frame" {
			Name = "tabs",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			LayoutOrder = 3,

			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			create "UIFlexItem" { FlexMode = Enum.UIFlexMode.Shrink },

			tabButton("scripts", "Scripts", "Build scripts found in this place", 5),
			tabButton("queue", "Queue", "Scripts queued for a batch build", 6),
			tabButton("cheatsheet", "Cheatsheet", "Cheat sheet of all functions and types supported by the build system", 9),
			tabButton("about", "About", "About the Flood Timelines Build System", 10),
		},
	}
end

return toolbar
