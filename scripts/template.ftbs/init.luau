--$ftbs01

-- Flood Timelines Build System script - version 1
-- https://github.com/myralune/ftbs

-- Usage:
-- * The script will try to automatically find a map model for path resolution, otherwise
--   Workspace is used. If you do not want this behavior or need better autocomplete,
--   change the map variable.
-- * If another build script is detected under this module, they are generated as folder
--   macros.
-- * For advanced control, the configuration table is located below the build function.

local map = script:FindFirstAncestorWhichIsA("Model") or workspace
local conf

function build(create: create, macro: macro, folder: folder, container: container, config: {[string]: any})
	-- `config` is the active configuration table (the merged $default + selected
	-- configuration from `conf` below). e.g. `if config.booltest1 then ... end`
	local referenced_by_conditional = create ("timeline", "FTLS_Example_RefByConditionFail") {
		attributes = {}
	}
	
	create ("timeline", "FTLS_Example_Timeline") {
		attributes = {},
		
		create ("xframe", "FTLS_Example_XFGeneric") {
			attributes = {},
			target = map.path.to.target,
		},
		
		create ("xframe", "FTLS_Example_XFConditional") {
			attributes = {
				XFrame_Function = "Conditional",
				Conditional_Operator = "==",
				Property_Name = "NameHere",
			},
			target = map.path.to.target,
			
			create ("pointer", "ConditionalTimeline") {
				target = referenced_by_conditional
			}
		},
		
		folder "FTLS_Example_XFFolder" {
			create ("xframe", "FTLS_Example_XFInFolder") {
				attributes = {},
				target = map.path.to.target,
			}
		},
		
		container ("Configuration", "FTLS_Example_XFContainer") {
			create ("xframe", "FTLS_Example_XFInCustomContainer") {
				attributes = {},
				target = map.path.to.target,
			}
		},
	}
	
	create ("timeline", "FTLS_Example_XFrameMacro") {
		attributes = {},
		
		macro(function()
			local xframes = {}
			
			table.insert(xframes,
				create ("xframe", "FTLS_Example_XFrameCreatedByMacro") {
					attributes = {}
				}
			)
			
			return xframes
		end)
	}
	
	macro(function()
		local timelines = {}
		
		table.insert(timelines,
			create ("timeline", "FTLS_Example_TimelineCreatedByMacro") {
				attributes = {}
			}
		)
		
		return timelines
	end)
end

-- Configuration table
conf = {
	-- Default configuration table
	["$default"] = {
		booltest1 = false,
		booltest2 = true,
		booltest3 = false,
	},
	
	-- Advanced: Multiple configurations
	["test1"] = {
		["$dispname"] = "Test Configuration 1",
		["$dispdesc"] = "",
		booltest1 = true,
		booltest2 = false,
		booltest3 = false,
	},
	
	["test2"] = {
		["$dispname"] = "Test Configuration 2",
		["$dispdesc"] = "",
		booltest1 = false,
		booltest2 = false,
		booltest3 = true,
	},
}

-- disregard all lines below, but do not remove.
local create, macro, folder, container do
	-- Add attributes, macros, or containers here.
	-- Timeline objects can contain XFrames.
	-- XFrame objects have additional options for the target and timeline to invoke on Conditional fails.
	local function object(props: {attributes: {[string]: any}, target: Instance?, onconditionfail: any, [number]: any}): any return 0 end
	
	-- Add Timeline or XFrame objects here. Attributes and properties of the container can also be set.
	local function container_impl(props: {attributes: {[string]: any}, props: {[string]: any}, [number]: any}): any return 0 end
	
	-- Create a new Timeline or XFrame object.
	-- If this function is called inside a Timeline table, the XFrame object is a child of the Timeline.
	function create(type: "timeline" | "xframe" | "pointer", name: string): typeof(object) return object end
	
	-- Create a macro that can dynamically create Timeline or XFrame objects. The created objects become children of the parent object.
	-- This function can be called as a child for XFrame objects or in the main function body for Timeline objects.
	function macro(f: () -> {any}): any return 0 end
	
	-- Create a folder for organization.
	-- Shorthand of <code>container("Folder", name)</code>.
	function folder(name: string): typeof(container) return 0 end
	
	-- Create a container instance with a custom class.
	function container(class: string, name: string): typeof(container) return 0 end
end; type create = typeof(create); type macro = typeof(macro); type folder = typeof(folder); type container = typeof(container)
return {build = build, map = map, conf = conf}