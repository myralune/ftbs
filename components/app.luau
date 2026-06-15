local vide = require "../vide"

local style = require "./style"
local toolbar = require "./toolbar"
local viewport = require "./viewport"
local tooltip = require "./tooltip"
local modal = require "./modal"

local core = require "../core/core"
local srclist = require "../core/srclist"
local status = require "./status"

local create = vide.create

local function app(plugin: Plugin, widget: PluginGui)
	local tab = vide.source("scripts" :: toolbar.Tab)

	-- initial scan
	task.defer(function()
		local entries = srclist.refresh()
		status.status(`Found {#entries} build script(s)`)
	end)

	return create "Frame" {
		Name = "window",
		BackgroundColor3 = style.color.windowBg,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,

		toolbar {
			tab = tab,
			actions = {
				new = function()
					task.spawn(core.createTemplate)
				end,
				import = function()
					task.spawn(core.importScript)
				end,
				export = function()
					local entries = srclist.source()
					if #entries == 0 then
						task.spawn(core.exportScript) -- falls back to the Explorer selection / warning
						return
					end

					local options = {}
					for _, entry in entries do
						options[#options + 1] = {
							label = `{entry.name} ({entry.objectName})`,
							action = function()
								core.exportScript(entry)
							end,
						}
					end
					options[#options + 1] = { label = "Cancel" }

					modal.show {
						title = "Export",
						message = "Choose the build script to export as a Roblox model file:",
						options = options,
					}
				end,
				generate = function()
					local candidates = core.findTimelinesCandidates()
					if #candidates == 0 then
						status.status("No Timelines folders with timelines found in this place")
						return
					end

					local options = {}
					for _, candidate in candidates do
						options[#options + 1] = {
							label = candidate.label,
							action = function()
								core.generateFromTimelines(candidate)
							end,
						}
					end
					options[#options + 1] = { label = "Cancel" }

					modal.show {
						title = "Generate Build Script",
						message = "Choose the map whose Timelines folder should be turned into a build script:",
						options = options,
					}
				end,
				refresh = function()
					local entries = srclist.refresh()
					status.status(`Found {#entries} build script(s)`)
				end,
			},
		},

		viewport { tab = tab },

		modal.render(),
		tooltip(widget),
	}
end

return app
