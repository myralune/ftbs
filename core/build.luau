--!nonstrict
--[[
	Flood Timelines Build System — build runtime
	==========================================================================
	Runs build scripts against a single shared registry and produces a plain, bake-ready data tree.
	It does not touch the DataModel — see core/bake.luau for that
]]

local Build = {}

export type FolderRef = { name: string, className: string }

export type BuiltPointer = {
	name: string, -- becomes an ObjectValue of this name on the xframe
	ref: string?, -- resolved name of the timeline it points at
}

export type BuiltXFrame = {
	name: string,
	target: any, -- ObjectValue.Value (expected to be an Instance)
	attributes: { [string]: any },
	folderPath: { FolderRef }, -- cosmetic nesting under the timeline
	pointers: { BuiltPointer },
}

export type BuiltTimeline = {
	name: string,
	attributes: { [string]: any },
	group: { string }, -- folder path under the Timelines folder ({} = root)
	xframes: { BuiltXFrame },
}

export type BuildResult = {
	ok: boolean, -- false if any error-level issue was reported
	timelines: { BuiltTimeline },
	issues: { string },
}

-- An entry to run
export type Entry = {
	build: (...any) -> (),
	group: { string }?,
}

-- Value types that survive as Roblox attributes (used for friendly warnings).
local ATTRIBUTE_TYPES = {
	string = true, boolean = true, number = true,
	UDim = true, UDim2 = true, BrickColor = true, Color3 = true,
	Vector2 = true, Vector3 = true, CFrame = true,
	NumberSequence = true, ColorSequence = true, NumberRange = true,
	Rect = true, Font = true, EnumItem = true,
}

local function refName(ref: any): string?
	if ref == nil then return nil end
	if type(ref) == "string" then return ref end
	if type(ref) == "table" and ref.__timeline then return ref.__timeline end
	return nil
end

local function childrenOf(props: any): { any }
	local out = {}
	if type(props) ~= "table" then return out end
	for _, value in ipairs(props) do
		if type(value) == "table" and value.kind ~= nil then
			out[#out + 1] = value
		end
	end
	return out
end

-- Runs a list of build entries against one shared registry
function Build.run(entries: { Entry }, config: { [string]: any }?): BuildResult
	local issues = {}
	local function report(message: string)
		issues[#issues + 1] = `[FTBS] {message}`
	end

	local timelineRecords = {} -- { name, node, group }
	local nameCounts = {}
	local currentGroup = {}

	-- create(type, name)(props) -> handle | node
	local function create(kind: string, name: string)
		if kind ~= "timeline" and kind ~= "xframe" and kind ~= "pointer" then
			report(`create() got unknown type "{tostring(kind)}" (expected "timeline", "xframe" or "pointer")`)
		end
		if type(name) ~= "string" then
			report(`create("{tostring(kind)}", …) needs a string name, got {typeof(name)}`)
			name = tostring(name)
		end

		return function(props)
			props = props or {}

			if kind == "timeline" then
				nameCounts[name] = (nameCounts[name] or 0) + 1
				timelineRecords[#timelineRecords + 1] = {
					name = name,
					node = {
						kind = "timeline",
						name = name,
						attributes = props.attributes or {},
						children = childrenOf(props),
					},
					group = currentGroup,
				}
				return { __timeline = name } -- handle, usable as a pointer target

			elseif kind == "xframe" then
				return {
					kind = "xframe",
					name = name,
					attributes = props.attributes or {},
					target = props.target,
					onconditionfail = props.onconditionfail,
					children = childrenOf(props),
				}

			else -- pointer
				return {
					kind = "pointer",
					name = name,
					target = props.target,
				}
			end
		end
	end

	-- macro(fn) runs fn immediately and wraps whatever nodes it returns into a transparent group
	local function macro(fn)
		if type(fn) ~= "function" then
			report(`macro() expects a function, got {typeof(fn)}`)
			return { kind = "group", children = {} }
		end
		local ok, result = pcall(fn)
		if not ok then
			report(`macro errored: {result}`)
			return { kind = "group", children = {} }
		end
		local children = {}
		if type(result) == "table" then
			if result.kind ~= nil then
				children = { result }
			else
				for _, value in ipairs(result) do
					if type(value) == "table" and value.kind ~= nil then
						children[#children + 1] = value
					end
				end
			end
		end
		return { kind = "group", children = children }
	end

	-- container(class, name)(props) -> cosmetic container node holding xframes
	local function container(className: string, name: string)
		if type(className) ~= "string" or type(name) ~= "string" then
			report(`container(class, name) needs two strings`)
		end
		return function(props)
			props = props or {}
			return {
				kind = "container",
				className = className,
				name = name,
				attributes = props.attributes,
				children = childrenOf(props),
			}
		end
	end

	local function folder(name: string)
		return container("Folder", name)
	end

	-- Run every build function against the shared registry
	for index, entry in entries do
		currentGroup = entry.group or {}
		if type(entry.build) ~= "function" then
			report(`entry #{index} has no build function`)
			continue
		end
		local ok, err = pcall(entry.build, create, macro, folder, container, config or {})
		if not ok then
			report(`build #{index} errored while running: {err}`)
		end
	end

	for name, count in nameCounts do
		if count > 1 then
			report(`duplicate timeline name "{name}" ({count} definitions)`)
		end
	end

	-- Validation / flattening
	local function checkRef(ref: any, context: string): string?
		local resolved = refName(ref)
		if resolved == nil or resolved == "" then return nil end
		if nameCounts[resolved] == nil then
			report(`{context} references unknown timeline "{resolved}"`)
		end
		return resolved
	end

	local function warnAttributeTypes(ownerName: string, attrs)
		if type(attrs) ~= "table" then return end
		for key, value in attrs do
			if value ~= nil and not ATTRIBUTE_TYPES[typeof(value)] then
				report(`{ownerName}.{key} has value type "{typeof(value)}", which can't be stored as an attribute`)
			end
		end
	end

	-- Collects pointer children off an xframe
	local function collectPointers(xnode, context): { BuiltPointer }
		local pointers = {}
		local function consider(node)
			if node.kind == "pointer" then
				pointers[#pointers + 1] = {
					name = node.name,
					ref = checkRef(node.target, `pointer "{node.name}" in {context}`),
				}
			elseif node.kind == "group" then
				for _, child in node.children or {} do
					consider(child)
				end
			end
		end
		for _, child in xnode.children or {} do
			consider(child)
		end
		if xnode.onconditionfail ~= nil then
			pointers[#pointers + 1] = {
				name = "Conditional_Timeline",
				ref = checkRef(xnode.onconditionfail, `xframe "{xnode.name}" onconditionfail in {context}`),
			}
		end
		return pointers
	end

	-- Flattens containers/groups into a flat xframe list
	local function flatten(nodes, path, xframesOut, tlName)
		for _, node in nodes do
			if type(node) ~= "table" then continue end
			if node.kind == "xframe" then
				warnAttributeTypes(`xframe "{node.name}"`, node.attributes)
				xframesOut[#xframesOut + 1] = {
					name = node.name,
					target = node.target,
					attributes = node.attributes or {},
					folderPath = path,
					pointers = collectPointers(node, `timeline "{tlName}"`),
				}
			elseif node.kind == "container" then
				local nextPath = table.clone(path)
				nextPath[#nextPath + 1] = { name = node.name, className = node.className or "Folder" }
				flatten(node.children or {}, nextPath, xframesOut, tlName)
			elseif node.kind == "group" then
				flatten(node.children or {}, path, xframesOut, tlName)
			end
		end
	end

	local timelines = {}
	for _, record in timelineRecords do
		local node = record.node
		warnAttributeTypes(`timeline "{node.name}"`, node.attributes)

		local xframes = {}
		flatten(node.children or {}, {}, xframes, node.name)
		if #xframes == 0 then
			report(`timeline "{node.name}" has no xframes`)
		end

		timelines[#timelines + 1] = {
			name = node.name,
			attributes = node.attributes or {},
			group = record.group or {},
			xframes = xframes,
		}
	end

	return {
		ok = #issues == 0,
		timelines = timelines,
		issues = issues,
	}
end

local function groupPathFor(module: Instance, root: Instance): { string }
	if module == root then return {} end
	local segments = {}
	local current: Instance? = module
	while current and current ~= root do
		table.insert(segments, 1, current.Name)
		current = current.Parent
	end
	return segments
end

-- Merges the $default configuration with a selected named configuration
local function resolveConfig(conf: any, selectedName: string?): { [string]: any }
	local active = {}
	if type(conf) ~= "table" then return active end
	local function overlay(source)
		if type(source) ~= "table" then return end
		for key, value in source do
			if type(key) == "string" and string.sub(key, 1, 1) ~= "$" then
				active[key] = value
			end
		end
	end
	overlay(conf["$default"])
	if selectedName ~= nil and selectedName ~= "$default" then
		if conf[selectedName] == nil then
			warn(`[FTBS] configuration "{selectedName}" not found, using $default`)
		else
			overlay(conf[selectedName])
		end
	end
	return active
end

-- Clones the main script and forks into the map
function Build.fromScript(rootScript: ModuleScript, map: Instance, configName: string?): BuildResult
	local loadIssues = {}

	local cloneRoot = rootScript:Clone()
	cloneRoot.Parent = map

	local entries: { Entry } = {}
	local conf

	local function tryAdd(module: ModuleScript)
		local ok, result = pcall(require, module)
		local group = groupPathFor(module, cloneRoot)
		if not ok then
			loadIssues[#loadIssues + 1] = `[FTBS] {module.Name} failed to load: {result}`
		elseif type(result) == "table" and type(result.build) == "function" then
			entries[#entries + 1] = { build = result.build, group = group }
			if module == cloneRoot then conf = result.conf end
		elseif type(result) == "function" then
			entries[#entries + 1] = { build = result, group = group }
		end
	end

	tryAdd(cloneRoot)
	for _, descendant in cloneRoot:GetDescendants() do
		if descendant:IsA("ModuleScript") then
			tryAdd(descendant)
		end
	end

	local config = resolveConfig(conf, configName)
	local result = Build.run(entries, config)

	cloneRoot:Destroy()

	for i = #loadIssues, 1, -1 do
		table.insert(result.issues, 1, loadIssues[i])
	end
	result.ok = #result.issues == 0
	return result
end

return Build
