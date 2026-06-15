--$ftbs01

-- Flood Timelines Build System fork script - version 1
-- https://github.com/myralune/ftbs

-- A fork is just another build script nested under the main one. Every fork runs
-- against the SAME registry, so:
--   * timeline names are shared project-wide (keep them unique), and
--   * a pointer here can reference a timeline defined in another file by name.
-- Forks are placed under Timelines in a folder path mirroring their location
-- beneath the main script (this one bakes into Timelines/Forks/testfork.ftbs).

-- * The script will try to automatically find a map model for path resolution, otherwise
--   Workspace is used. If you do not want this behavior or need better autocomplete,
--   change the map variable.

local map = script:FindFirstAncestorWhichIsA("Model") or workspace

function build(create: create, macro: macro, folder: folder, container: container, config: {[string]: any})
	create ("timeline", "FTLS_Fork_Timeline") {
		attributes = {},

		create ("xframe", "FTLS_Fork_XFConditional") {
			attributes = {
				XFrame_Function = "Conditional",
				Conditional_Operator = "==",
				Property_Name = "NameHere",
			},
			target = map,

			-- You can reference timelines in other build scripts by name using this
			create ("pointer", "ConditionalTimeline") {
				target = "FTLS_Example_RefByConditionFail"
			},
		},
	}
end

-- disregard all lines below, but do not remove.
local create, macro, folder, container do
	local function object(props: {attributes: {[string]: any}, target: Instance?, onconditionfail: any, [number]: any}): any return 0 end
	local function container_impl(props: {attributes: {[string]: any}, props: {[string]: any}, [number]: any}): any return 0 end
	function create(type: "timeline" | "xframe" | "pointer", name: string): typeof(object) return object end
	function macro(f: () -> {any}): any return 0 end
	function folder(name: string): typeof(container) return 0 end
	function container(class: string, name: string): typeof(container) return 0 end
end; type create = typeof(create); type macro = typeof(macro); type folder = typeof(folder); type container = typeof(container)
return {build = build, map = map}
